class Foreman

  def initialize(api)
    @api = api
  end

  def api_resource(name)
    @api.resource(name)
  end

  def method_missing(name, *args, &block)
    name = name.to_sym
    if @api.resources.any? { |r| r.name == name }
      Resource.new(@api.resource(name))
    else
      super
    end
  end

  def respond_to?(name)
    name = name.to_sym
    if @api.resources.any? { |r| r.name == name }
      true
    else
      super
    end
  end

  def version
    version = @api.resource(:home).action(:status).call
    version['version']
  end

  class Resource
    def initialize(api_resource)
      @api_resource = api_resource
    end

    def method_missing(name, *args, &block)
      if @api_resource.actions.any? { |a| a.name == name }
        @api_resource.call(name, *args, &block)
      else
        super
      end
    end

    def respond_to?(name)
      @api_resource.actions.any? { |a| a.name == name } || super
    end

    def show_or_ensure(identifier, attributes)
      begin
        object = @api_resource.action(:show).call(identifier)
        if should_update?(object, attributes)
          object = @api_resource.action(:update).call(identifier.merge({ @api_resource.singular_name => attributes }))
          object = @api_resource.action(:show).call(identifier)
        end
      rescue RestClient::ResourceNotFound
        object = @api_resource.action(:create).call({ @api_resource.singular_name => attributes }.merge(identifier.tap { |h| h.delete('id') }))
      end
      object
    end

    def search_or_ensure(condition, attributes)
      begin
        object = first!(condition)
        if should_update?(object, attributes)
          identifier = { 'id' => object['id'] }
          object, _ = @api_resource.action(:update).call(identifier.merge({ @api_resource.singular_name => attributes }))
          object, _ = @api_resource.action(:show).call(identifier)
        end
      rescue StandardError
        object, _ = @api_resource.action(:create).call({ @api_resource.singular_name => attributes })
      end
      object
    end

    def katello_search_or_ensure(identifiers, condition, attributes)
      object = @api_resource.action(:index).call(identifiers.merge(condition))['results'].first
      if object
        if should_update?(object, attributes)
          identifiers.merge({ 'id' => object['id'] })
          object = @api_resource.action(:update).call(identifiers.merge(attributes))
          object = @api_resource.action(:show).call(identifiers)
        end
      else
        object = @api_resource.action(:create).call(identifiers.merge(attributes))
      end
      object
    end

    def show!(*args)
      error_message = args.delete(:error_message) || 'unknown error'
      begin
        object = @api_resource.action(:show).call(*args)
      rescue RestClient::ResourceNotFound
        raise StandardError, error_message
      end
      object
    end

    def index(*args)
      object = @api_resource.action(:index).call(*args)
      object['results']
    end

    def search(condition)
      index('search' => condition)
    end

    def first(condition)
      search(condition).first
    end

    def first!(condition)
      first(condition) or raise StandardError, "no #{@name} found by searching '#{condition}'"
    end

    private

    def should_update?(original, desired)
      desired.any? { |attribute, value| original[attribute] != value }
    end
  end
end
