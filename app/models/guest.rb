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

  validates_inclusion_of :attending, :in => [true, false, nil], :message => "invalid value for attending"
  validates_presence_of :entree_choice, :if => lambda { |rec| rec.attending },
    :message => 'must be selected when attending'
  validates_length_of :name, :email_address, :entree_choice, :maximum => 1024

  validate :no_name_changes

  spreadsheet_mapping 'Invitations' do |m|
    m.value_mapping('RSVP ID', :invitation_id, :identifier => true)
    m.value_mapping('Guest Name', :name)
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
      },
      from_column: lambda { |v|
        case v
        when /y/i
          true
        when /n/i
          false
        else
          nil
        end
      }
    )
  end

  class << self
    def find_for_rsvp(rsvp_id)
      select { |row| row['RSVP ID'].downcase == rsvp_id.downcase }
    end
  end

  ##
  # Provides the generated ID for this record.
  def id
    name && name.gsub(' ', '').downcase
  end

  def invitation_id
    invitation.try(:id)
  end

  def invitation_id=(invitation_id)
    if self.invitation
      return if invitation_id == self.invitation.id
      fail "Cannot change invitation ID for guest #{name.inspect}"
    elsif invitation_id
      self.invitation = Invitation.new.tap { |i| i.id = invitation_id }
    end
  end

  def no_name_changes
    stored_names = self.class.find_for_rsvp(self.invitation_id).collect(&:name)
    unless stored_names.include?(self.name)
      errors.add(:name, "may not be changed")
    end
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
