module RsvpApi
  module Cucumber
    module DirectHttp
      class Client
        include ::Rack::Test::Methods

        alias :response :last_response

        def app
          ::Capybara.app
        end
      end

      def http
        @rack_test_http ||= Client.new
      end
    end
  end
end

World(RsvpApi::Cucumber::DirectHttp)
