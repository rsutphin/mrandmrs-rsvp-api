desc "Assigns new random RSVP IDs to all records"
task :rekey => [:environment] do
  require 'rekeyer'
  store = Rails.application.store_creator.call
  Rekeyer.new(store).rekey!
end
