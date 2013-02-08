module SpreadsheetModel
  ##
  # Provides implementations of ActiveModel methods that are appropriate for the
  # models in this project and which are not particularly complicated.
  module ActiveModelAdapter
    include ActiveModel::Conversion

    # don't use this in this project; included for linter benefit
    def to_partial_path
      self.class.name.downcase
    end

    # According to the ActiveModel documentation, `persisted?` really means
    # "does this instance have an ID?" Model objects in this system always have
    # IDs because they are externally assigned or derived.
    def persisted?
      true
    end

    module ClassMethods
      def model_name
        @model_name ||= ActiveModel::Name.new(self)
      end
    end
  end
end
