require 'facter'

if app_value(:provisioning_wizard) != 'none' && [0,2].include?(kafo.exit_code)
  require File.join(KafoConfigure.root_dir, 'hooks', 'lib', 'foreman.rb')
  require File.join(KafoConfigure.root_dir, 'hooks', 'lib', 'base_seeder.rb')
  require File.join(KafoConfigure.root_dir, 'hooks', 'lib', 'host_seeder.rb')
  require File.join(KafoConfigure.root_dir, 'hooks', 'lib', 'provisioning_seeder.rb')

  puts "Starting configuration..."

  host_seeder = HostSeeder.new(kafo)
  host_seeder.seed

  # we must enforce at least one puppet run
  logger.debug 'Running puppet agent to seed foreman data'
  fqdn =  Facter.value('fqdn')
  `su puppet --shell /bin/bash -c 'mkdir -p /var/lib/puppet/yaml/facts/'`
  `service puppet stop`
  `su puppet --shell /bin/bash -c 'puppet facts find #{fqdn} --render-as yaml > /var/lib/puppet/yaml/facts/#{fqdn}.yaml'`
  `puppet agent -t --no-pluginsync`
  `service puppet start`
  logger.debug 'Puppet agent run finished'

  logger.debug 'Installing puppet modules'
  `/usr/share/katello-installer/hooks/lib/install_modules.sh`
  `foreman-rake puppet:import:puppet_classes[batch]`
  # run import
  logger.debug 'Puppet modules installed'


  # add other provisioning data
  pro_seeder = ProvisioningSeeder.new(kafo)
  pro_seeder.seed
  `foreman-rake db:migrate`
  `foreman-rake db:seed`
else
  say "Not running provisioning configuration since installation encountered errors, exit code was <%= color('#{kafo.exit_code}', :bad) %>"
  false
end
