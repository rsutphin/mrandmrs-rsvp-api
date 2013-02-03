##
# Shared logic for spreadsheet-backed models. This is specific to this project
# and should not be reused without some refactoring. (In particular, it is only
# tested through its effects on the behaviors of the models in this system.)
module SpreadsheetModel
  extend ActiveSupport::Concern

  module ClassMethods
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
  end

  def spreadsheet_mapping
    self.class.spreadsheet_mapping
  end

  def sheet_name
    self.class.sheet_name
  end

  class Mapping
    DEFAULT_FROM_COLUMN = lambda { |column_value|
      column_value.blank? ? nil : column_value
    }

    DEFAULT_TO_COLUMN = lambda { |attribute_value| attribute_value }

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
      @value_mappings << {
        :column => column_name, :attribute => attribute_name,
        :from_column => DEFAULT_FROM_COLUMN, :to_column => DEFAULT_TO_COLUMN
      }.merge(options)
    end

    def columns
      @value_mappings.collect { |map| map[:column] }
    end

    def attributes
      @value_mappings.collect { |map| map[:attribute] }
    end

    def update_row_from_instance(row, instance)
      @value_mappings.each do |map|
        row[map[:column]] = map[:to_column].call(instance.send(map[:attribute]))
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
  end
end
