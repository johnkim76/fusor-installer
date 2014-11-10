if app_value(:provisioning_wizard) != 'none'
  # we register fusor module and its mapping
  add_module('foreman::plugin::fusor',
             {:manifest_name => 'plugin/fusor',  :dir_name => 'foreman'})

  # make sure discovery and foreman-tasks are enabled
  kafo.module('foreman_plugin_discovery').enable
  kafo.module('foreman_plugin_tasks').enable
end
