require 'spreadsheet_model'

class Guest
  include ActiveModel::SerializerSupport
  include SpreadsheetModel

  ##
  # @return [Invitation] the invitation under which this person is invited.
  attr_accessor :invitation

  ##
  # @return [String] the person's invited name.
  attr_accessor :name

  ##
  # @return [String,nil] the person's e-mail address, if known.
  attr_accessor :email_address

  ##
  # @return [Boolean,nil] whether this guest will attend. `nil` means "don't
  #   know" or "not responded yet".
  attr_accessor :attending

  ##
  # @return [String,nil] entree choice.
  attr_accessor :entree_choice

  spreadsheet_mapping 'Invitations' do |m|
    m.value_mapping('E-mail Address', :email_address)
    m.value_mapping('Entree Choice', :entree_choice)
    m.value_mapping('Attending?', :attending,
      to_column: lambda { |v|
        case v
        when nil
          nil
        when true
          'Yes'
        when false
          'No'
        end
      }
    )
  end

  class << self
  end

  ##
  # Provides the generated ID for this record.
  def id
    name && name.gsub(' ', '').downcase
  end

  def invitation_id
    invitation.try(:id)
  end

  def save
    guests_sheet = Rails.application.store.get_sheet(sheet_name) || []
    guest_row = guests_sheet.detect { |row|
      row['RSVP ID'] == self.invitation.try(:id) && row['Guest Name'] == self.name
    }
    unless guest_row
      # TODO: this should be handled as a validation somehow
      fail "Invitation #{self.invitation_id.inspect} does not include a guest named #{self.name.inspect}"
    end

    spreadsheet_mapping.update_row_from_instance(guest_row, self)

    Rails.application.store.replace_sheet(sheet_name, guests_sheet)
  end
end
