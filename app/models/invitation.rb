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

      guests.each { |g| g.invitation = invitation }
      invitation.guests = guests

      invitation
    end

    def exist?(id)
      !Guest.find_for_rsvp(id).empty?
    end

    def convert_attending_from_store(store_value)
      case store_value
      when /y/i
        true
      when /n/i
        false
      else
        nil
      end
    end
    private :convert_attending_from_store

    def nil_for_blank(s)
      s.blank? ? nil : s
    end
    private :nil_for_blank
  end

  def guests
    @guests ||= []
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
