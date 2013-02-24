module RsvpApi
  ##
  # Uses `Rails.application.store_creator` to create a new store for each request
  # and make it available as a thread local so the models can access it.
  class StoreForRequest
    def initialize(app)
      @app = app
    end

    def call(env)
      begin
        self.class.apply
        @app.call(env)
      ensure
        self.class.remove
      end
    end

    class << self
      def apply
        self.store = Rails.application.store_creator.call
      end

      def remove
        self.store = nil
      end

      def store=(s)
        Thread.current[store_key] = s
      end

      def store
        Thread.current[store_key]
      end

      def store_key
        self.name
      end
    end
  end
end
