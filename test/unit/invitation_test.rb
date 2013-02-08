require_relative '../test_helper'

##
# This test case is purely for using the ActiveModel linter. The actual
# tests are in spec/model/invitation_spec.
class InvitationTest < ActiveSupport::TestCase
  include ActiveModel::Lint::Tests

  def setup
    @model = Invitation.new
  end
end
