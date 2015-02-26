require 'apipie-bindings'
require 'uri'

class BaseSeeder
  def initialize(kafo)
    @foreman_url = kafo.param('foreman_plugin_fusor', 'base_url').value
    param = kafo.param('foreman', 'admin_username')
    @username = param.nil? ? 'admin' : param.value
    param = kafo.param('foreman', 'admin_password')
    @password = param.nil? ? 'changeme' : param.value
    foreman

    @logger = kafo.logger

    @fqdn = URI.parse(@foreman_url).host # TODO rescue error
  end

  def foreman
    @foreman ||= Foreman.new(ApipieBindings::API.new(:uri => @foreman_url, :username => @username, :password => @password, :api_version => 2))
  end

  private

  def find_default_oses(foreman_host)
    os = find_default_os(foreman_host)
    ([os] + additional_oses(os)).compact
  end

  def find_default_os(foreman_host)
    @foreman.operatingsystems.show! 'id' => foreman_host['operatingsystem_id'],
                                    :error_message => "operating system for #{@fqdn} not found, DB inconsitency?"
  end

  def additional_oses(os)
    additional = []
    if os['name'] == 'RedHat' && os['major'] == '6'
      additional << foreman.operatingsystems.show_or_ensure({'id' => 'RedHat 7.0'},
                                                            {'name' => 'RedHat', 'major' => '7', 'minor' => '0',
                                                             'family' => 'Redhat'})
    end
    if os['name'] == 'CentOS' && os['major'] == '6'
      additional << foreman.operatingsystems.show_or_ensure({'id' => 'CentOS 7.0'},
                                                            {'name' => 'CentOS', 'major' => '7', 'minor' => '0',
                                                             'family' => 'Redhat'})
    end

    # TODO: The creation of OS is currently based upon the OS of the server;
    # however for our initial scenario (oVirt), we are going to assume that
    # the hosts that are provisioned are CentOS 6.6.  We'll need to update this
    # once we have support for the Red Hat content in place
    # (subscriptions...etc.)
    additional << foreman.operatingsystems.show_or_ensure({'id' => 'CentOS 6.6'},
                                                          {'name' => 'CentOS', 'major' => '6',
                                                           'minor' => '6', 'family' => 'Redhat'})

    additional
  end

  def find_foreman_host
    @foreman.hosts.show! 'id' => @fqdn,
                         :error_message => "host #{@fqdn} not found in foreman, puppet haven't run yet?"
  end

end
