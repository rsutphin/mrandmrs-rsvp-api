require 'spreadsheet_model/active_model_adapter'

##
# Shared logic for spreadsheet-backed models. This is specific to this project
# and should not be reused without some refactoring. (In particular, it is only
# tested through its effects on the behaviors of the models in this system.)
module SpreadsheetModel
  extend ActiveSupport::Concern
  include SpreadsheetModel::ActiveModelAdapter
  include ActiveModel::Validations

  module ClassMethods
    include SpreadsheetModel::ActiveModelAdapter::ClassMethods

    def spreadsheet_mapping(sheet_name=nil, &block)
      if sheet_name
        @spreadsheet_mapping = Mapping.new(sheet_name, &block)
      else
        @spreadsheet_mapping
      end
    end

    def sheet_name
      @spreadsheet_mapping.sheet_name
    end

    ##
    # @return [Array<SpreadsheetModel>] an array of instances built by filtering
    #   the rows of this model's sheet according to &criteria
    # @param criteria [Proc] a block that returns true if an instance derived
    #   from the row it receives should be included in the result set.
    def select(&criteria)
      rows = Rails.application.store.get_sheet(sheet_name).try(:select, &criteria) || []
      rows.map { |row| spreadsheet_mapping.update_instance_from_row(self.new, row) }
    end

    ##
    # @return [Array<SpreadsheetModel> all the instances of this type in the
    #   system, without any associations resolved.
    def all_raw
      select { true }
    end
  end

  def spreadsheet_mapping
    self.class.spreadsheet_mapping
  end

  def sheet_name
    self.class.sheet_name
  end

  class Mapping
    NAMED_CONVERSIONS = {
      from_column: {
        nil_for_blank: lambda { |column_value|
          column_value.blank? ? nil : column_value
        },
        boolean_or_nil: lambda { |v|
          case v
          when /y/i
            true
          when /n/i
            false
          else
            nil
          end
        },
        boolean: lambda { |v|
          v =~ /y/i ? true : false
        }
      },
      to_column: {
        identity: lambda { |attribute_value| attribute_value },
        yes_no_nil: lambda { |v|
          case v
          when nil
            nil
          when true
            'Yes'
          when false
            'No'
          end
        },
        yes_nil: lambda { |v|
          v ? 'Yes' : nil
        }
      }
    }

    attr_reader :sheet_name

    def initialize(sheet_name)
      @sheet_name = sheet_name
      @value_mappings = []
      yield self if block_given?
    end

    ##
    # Handled options:
    # * :from_column => a lambda which receives a column value and returns an attribute value
    # * :to_column => a lambda which receives an attribute value and returns a column value
    def value_mapping(column_name, attribute_name, options={})
      @value_mappings << expand_mapping({
        :column => column_name, :attribute => attribute_name,
        :from_column => :nil_for_blank, :to_column => :identity
      }.merge(options))
    end

    def columns
      @value_mappings.collect { |map| map[:column] }
    end

    def attributes
      @value_mappings.collect { |map| map[:attribute] }
    end

    def update_row_from_instance(row, instance)
      @value_mappings.each do |map|
        unless map[:identifier]
          row[map[:column]] = map[:to_column].call(instance.send(map[:attribute]))
        end
      end
      row
    end

    ##
    # @return [instance]
    def update_instance_from_row(instance, row)
      @value_mappings.each do |map|
        instance.send("#{map[:attribute]}=", map[:from_column].call(row[map[:column]]))
      end
      instance
    end

    def expand_mapping(options)
      [:from_column, :to_column].each do |conversion_kind|
        options[conversion_kind] =
          extract_conversion(conversion_kind, options[conversion_kind])
      end
      options
    end
    private :expand_mapping

    def extract_conversion(kind, value)
      case value
      when Symbol
        NAMED_CONVERSIONS[kind][value] or fail "Unknown #{kind.inspect} conversion #{value.inspect}"
      else
        value
      end
    end
    private :extract_conversion
  end
end
