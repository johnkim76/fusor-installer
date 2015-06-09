class foreman::plugin::fusor_fw_pre {
  package {'iptables-services':
    ensure => installed,
  }
  service {'firewalld':
    name   => 'firewalld',
    enable => false,
    ensure => false,
    require => Package['iptables-services'],
  }
  Firewall {
    require => Service['firewalld'],
  }
  firewall { '000 accept related established rules':
    proto   => 'all',
    state => ['RELATED', 'ESTABLISHED'],
    action  => 'accept',
  }->
  firewall { '001 accept all icmp':
    proto   => 'icmp',
    action  => 'accept',
  }->
  firewall { '001 accept all to lo interface':
    proto   => 'all',
    iniface => 'lo',
    action  => 'accept',
  }
}
