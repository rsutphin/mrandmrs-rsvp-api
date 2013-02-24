desc 'Generate a PDF of insert cards'
task :insert_cards => [:environment] do
  RsvpApi::StoreForRequest.apply

  require 'rsvp_api/insert_card_generator'
  RsvpApi::InsertCardGenerator.new.generate
end
