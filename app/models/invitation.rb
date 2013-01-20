class Invitation
  include ActiveModel::SerializerSupport

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

  class << self
    ##
    # @return [Invitation,nil] matching the ID, otherwise `nil`.
    def find(id)
      guest_rows = Rails.application.store.get_sheet('Invitations').try(:select) { |row| row['RSVP ID'] == id }
      notes_row = Rails.application.store.get_sheet('Response Notes').try(:detect) { |row| row['RSVP ID'] == id }

      if guest_rows.blank?
        Rails.logger.debug("No guests for RSVP ID #{id.inspect}")
        return nil
      end

      Invitation.new.tap do |i|
        i.id = id
        if notes_row
          i.hotel = nil_for_blank(notes_row['Hotel'])
          i.response_comments = nil_for_blank(notes_row['Comments'])
        end

        i.guests = guest_rows.collect { |row|
          Guest.new.tap do |g|
            g.invitation = i
            g.name = row['Guest Name']
            g.email_address = nil_for_blank(row['E-mail Address'])
            g.attending = convert_attending_from_store(row['Attending?'])
            g.entree_choice = nil_for_blank(row['Entree Choice'])
          end
        }
      end
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
  end
end
