module RsvpApi
  module Cucumber
    module Store
      def store
        @store ||= CsvStore.new(Rails.root + 'tmp/features_store')
      end
    end
  end
end

World(RsvpApi::Cucumber::Store)
