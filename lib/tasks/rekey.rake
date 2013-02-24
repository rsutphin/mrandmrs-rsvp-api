desc "Assigns new random RSVP IDs to all records"
task :rekey => [:environment] do
  RsvpApi::StoreForRequest.apply

  require 'rekeyer'
  Rekeyer.new(Rails.application.store).rekey!
end
