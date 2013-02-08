require_relative '../test_helper'

##
# This test case is purely for using the ActiveModel linter. The actual
# tests are in spec/model/guest_spec.
class GuestTest < ActiveSupport::TestCase
  include ActiveModel::Lint::Tests

  def setup
    @model = Guest.new
  end
end
