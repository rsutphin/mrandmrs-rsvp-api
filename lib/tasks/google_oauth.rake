task :initial_device_oauth => [:environment] do
  require 'google_device_oauth'

  GoogleDeviceOAuth.new.initial_setup!
end
