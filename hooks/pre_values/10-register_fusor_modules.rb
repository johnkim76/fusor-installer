if app_value(:provisioning_wizard) != 'none'
  # we register fusor module and its mapping
  add_module('foreman::plugin::fusor',
             {:manifest_name => 'plugin/fusor',  :dir_name => 'foreman'})

  # make sure foreman-tasks is enabled
  unless app_value(:devel_env)
    kafo.module('foreman_plugin_tasks').enable
  end
end
