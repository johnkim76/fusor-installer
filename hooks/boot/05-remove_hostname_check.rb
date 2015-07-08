# remove hostname check if it exists
check_file = File.join(KafoConfigure.root_dir, 'checks', 'hostname.rb')
begin
  File.delete(check_file)
  logger.info "The check #{check_file} was removed."
rescue Exception
end
