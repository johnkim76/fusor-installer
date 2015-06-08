require 'facter'

class HostSeeder < BaseSeeder
  attr_accessor :fqdn

  def initialize(kafo)
    super
  end

  def seed
    say HighLine.color("Starting host creation", :good)

    prod_env_attrs = {'name' => "production"}
    prod_env = @foreman.environments.show_or_ensure({'id' => "production"}, prod_env_attrs)

    fusor_server_attrs = {'name'            => @fqdn,
                          'mac'             => Facter.value('macaddress'),
                          'ip'              => Facter.value('ipaddress'),
                          'location_id'     => nil,
                          'organization_id' => nil,
                          'environment_id'  => find_production_environment['id'],
                          'managed'         => "0"}
    fusor_server = @foreman.hosts.show_or_ensure({'id' => @fqdn}, fusor_server_attrs)
  end

  def find_production_environment
    @foreman.environments.show! 'id' => "production",
                                 :error_message => "environment production not found"
  end

end

