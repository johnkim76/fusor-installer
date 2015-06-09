class foreman::plugin::fusor_fw_post {
  firewall { '998 reject all':
    proto   => 'all',
    action  => 'reject',
  }->
  firewall { '999 reject all forward':
    chain   => 'FORWARD',
    proto   => 'all',
    action  => 'reject',
    before  => undef,
  }
}
