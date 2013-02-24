require 'spreadsheet_model'

class Invitation
  include ActiveModel::SerializerSupport
  include SpreadsheetModel

  ##
  # @return [String] the assigned ID for this invitation.
  attr_accessor :id

  ##
  # @return [Array<Guest>] the guests associated with this invitation. There
  #   must always be at least one.
  attr_accessor :guests

  ##
  # @return [String,nil] Free-form comments from the invitation's respondent.
  attr_accessor :response_comments

  ##
  # @return [String,nil] Free-text description from the respondent of which hotel they are staying at.
  attr_accessor :hotel

  validates_length_of :response_comments, :hotel, :maximum => 16384

  validate :no_guest_entry_changes

  spreadsheet_mapping 'Response Notes' do |m|
    m.value_mapping('RSVP ID', :id, :identifier => true)
    m.value_mapping('Comments', :response_comments)
    m.value_mapping('Hotel', :hotel)
  end

  class << self
    ##
    # @return [Invitation,nil] matching the ID, otherwise `nil`.
    def find(id)
      guests = Guest.find_for_rsvp(id)

      if guests.empty?
        Rails.logger.debug("No guests for RSVP ID #{id.inspect}")
        return nil
      end

      potential_invitation = select { |row| row['RSVP ID'] == id }.first
      invitation = potential_invitation || Invitation.new.tap { |i| i.id = id }

      associate_invitation_and_guests(invitation, guests)

      invitation
    end

    def associate_invitation_and_guests(invitation, guests)
      guests.each { |g| g.invitation = invitation }
      invitation.guests = guests
    end
    private :associate_invitation_and_guests

    def exist?(id)
      !Guest.find_for_rsvp(id).empty?
    end

    def all
      guests_by_rsvp_id = Guest.all_raw.each_with_object({}) { |g, index| (index[g.invitation_id] ||= []) << g }
      invitations_by_rsvp_id = all_raw.select { |i| guests_by_rsvp_id[i.id] }.each_with_object({}) { |i, index| index[i.id] = i }

      guests_by_rsvp_id.keys.collect do |invitation_id|
        inv = invitations_by_rsvp_id[invitation_id]
        unless inv
          inv = Invitation.new.tap { |i| i.id = invitation_id }
        end
        associate_invitation_and_guests(inv, guests_by_rsvp_id[invitation_id])
        inv
      end
    end
  end

  def guests
    @guests ||= []
  end

  ##
  # @return [String] the names of the guests combined into a single string.
  #   (see specs for examples)
  def combined_guest_names
    split_names = guests.collect do |g|
      parts = g.name.split(/ /)
      [parts[0, parts.size - 1].join(' '), parts[-1]]
    end

    last_names = split_names.collect(&:last).uniq
    if last_names.size == 1
      [join_names(split_names.collect(&:first)), last_names.first].join(' ')
    else
      join_names(guests.collect(&:name))
    end
  end

  def join_names(names)
    names.join(', ').sub(/, ([^,]+)\Z/, "#{',' if names.size != 2} and \\1")
  end
  private :join_names

  def no_guest_entry_changes
    stored_guests = self.class.find(self.id).try(:guests) || []
    no_new_guests = self.guests.all? do |g|
      stored_guests.any? { |sg| sg.id == g.id }
    end
    no_missing_guests = stored_guests.all? do |sg|
      self.guests.any? { |g| sg.id == g.id }
    end

    errors.add('guests', 'cannot add a guest') unless no_new_guests
    errors.add('guests', 'cannot remove a guest') unless no_missing_guests
  end

  def save
    invitation_sheet = Rails.application.store.get_sheet(sheet_name) || []
    invitation_row = invitation_sheet.detect { |row| row['RSVP ID'] == self.id }
    unless invitation_row
      invitation_row = { 'RSVP ID' => self.id }
      invitation_sheet << invitation_row
    end

    spreadsheet_mapping.update_row_from_instance(invitation_row, self)

    Rails.application.store.replace_sheet(sheet_name, invitation_sheet)

    self.guests.each { |g| g.save }
  end
end
