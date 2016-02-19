if app_value(:provisioning_wizard) != 'none'
  require File.join(KafoConfigure.root_dir, 'hooks', 'lib', 'base_wizard.rb')
  require File.join(KafoConfigure.root_dir, 'hooks', 'lib', 'provisioning_wizard.rb')
  provisioning_wizard = ProvisioningWizard.new(kafo)
  provisioning_wizard.start

  if provisioning_wizard.configure_networking || provisioning_wizard.configure_firewall
    command = PuppetCommand.new(%Q(class {"foreman::plugin::fusor_network":
      interface            => "#{provisioning_wizard.interface}",
      ip                   => "#{provisioning_wizard.ip}",
      netmask              => "#{provisioning_wizard.netmask}",
      gateway              => "#{provisioning_wizard.own_gateway}",
      dns                  => "#{provisioning_wizard.dns}",
      configure_networking => #{provisioning_wizard.configure_networking},
      configure_firewall   => #{provisioning_wizard.configure_firewall},
    }))
    command.append '2>&1'
    command = command.command

    say 'Starting networking setup'
    logger.debug "running command to set networking"
    logger.debug `#{command}`

    if $?.success?
      say 'Networking setup has finished'
    else
      say "<%= color('Networking setup failed', :bad) %>"
      kafo.class.exit(101)
    end

    if !system("ntpdate -q #{provisioning_wizard.ntp_host} &> /dev/null")  
      say HighLine.color("WARNING!! - NTP sync host \"#{provisioning_wizard.ntp_host}\" does not appear to be valid!", :bad)
      say HighLine.color('Do you want to continue anyway? [Yes/No]', :run)
      response = STDIN.gets
      if (response.downcase.chomp == "yes") || (response.downcase.chomp == "y") 
        say "  ... continuing installation"
      else
        say "Exiting installation!"
        logger.error "NTP sync host \"#{provisioning_wizard.ntp_host}\" is INVALID! ... Exiting"
        kafo.class.exit(:invalid_values)
      end
    else
      system("/bin/systemctl stop ntpd; /usr/sbin/ntpdate #{provisioning_wizard.ntp_host} >/dev/null")
      say HighLine.color('NTP sync host is ok', :good)
    end
  end

  param('capsule', 'parent_fqdn').value = provisioning_wizard.fqdn
  param('capsule', 'tftp_servername').value = provisioning_wizard.ip
  param('capsule', 'dhcp_interface').value = provisioning_wizard.interface
  param('capsule', 'dhcp_gateway').value = provisioning_wizard.gateway
  param('capsule', 'dhcp_range').value = "#{provisioning_wizard.from} #{provisioning_wizard.to}"
  param('capsule', 'dhcp_nameservers').value = provisioning_wizard.ip
  param('capsule', 'dns_interface').value = provisioning_wizard.interface
  param('capsule', 'dns_zone').value = provisioning_wizard.domain
  param('capsule', 'dns_reverse').value = provisioning_wizard.ip.split('.')[0..2].reverse.join('.') + '.in-addr.arpa'
  param('capsule', 'dns_tsig_principal').value = "foremanproxy/#{provisioning_wizard.fqdn}@#{provisioning_wizard.domain.upcase}"
  param('capsule', 'realm_principal').value = "realm-proxy@#{provisioning_wizard.domain.upcase}"
  param('capsule', 'dns_forwarders').value = provisioning_wizard.dns
  param('capsule', 'qpid_router_broker_addr').value = provisioning_wizard.fqdn
  param('capsule', 'bmc').value = provisioning_wizard.bmc
  param('capsule', 'bmc_default_provider').value = provisioning_wizard.bmc_default_provider
  param('certs', 'node_fqdn').value = provisioning_wizard.fqdn
  param('certs', 'ca_common_name').value = provisioning_wizard.fqdn
  param('foreman_plugin_fusor', 'configure_networking').value = provisioning_wizard.configure_networking
  param('foreman_plugin_fusor', 'configure_firewall').value = provisioning_wizard.configure_firewall
  param('foreman_plugin_fusor', 'interface').value = provisioning_wizard.interface
  param('foreman_plugin_fusor', 'ip').value = provisioning_wizard.ip
  param('foreman_plugin_fusor', 'netmask').value = provisioning_wizard.netmask
  param('foreman_plugin_fusor', 'own_gateway').value = provisioning_wizard.own_gateway
  param('foreman_plugin_fusor', 'gateway').value = provisioning_wizard.gateway
  param('foreman_plugin_fusor', 'dns').value = provisioning_wizard.dns
  param('foreman_plugin_fusor', 'network').value = provisioning_wizard.network
  param('foreman_plugin_fusor', 'from').value = provisioning_wizard.from
  param('foreman_plugin_fusor', 'to').value = provisioning_wizard.to
  param('foreman_plugin_fusor', 'domain').value = provisioning_wizard.domain
  param('foreman_plugin_fusor', 'base_url').value = provisioning_wizard.base_url
  param('foreman_plugin_fusor', 'ntp_host').value = provisioning_wizard.ntp_host
  param('foreman_plugin_fusor', 'timezone').value = provisioning_wizard.timezone

  # some enforced values for foreman-installer
  param('capsule', 'tftp').value = true
  param('capsule', 'dhcp').value = true
  param('capsule', 'dns').value = true
#  param('capsule', 'repo').value = 'nightly'

  unless app_value(:devel_env)
    param('foreman', 'servername').value = provisioning_wizard.fqdn
    param('foreman', 'foreman_url').value = provisioning_wizard.base_url
    param('foreman', 'repo').value = 'nightly'
  end

#  param('puppet', 'server').value = true
end
