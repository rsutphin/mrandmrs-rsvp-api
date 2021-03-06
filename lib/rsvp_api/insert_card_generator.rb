require 'prawn'
require 'prawn/measurement_extensions'

module RsvpApi
  ##
  # Generates letter-size PDF containing 6 separable insert cards per page.
  # Each card corresponds to one {Invitation}.
  #
  # Expects there to be a directory named `fonts` which includes TTF versions
  # of several variants of Futura.
  class InsertCardGenerator
    PAGE_SIZE = [8.5.in, 11.in]
    MARGIN = 0.25.in
    COLS_ROWS = [2, 3]

    CARD_SIZE = [0, 1].collect { |i|
      (PAGE_SIZE[i] - MARGIN * 2) / COLS_ROWS[i]
    }

    def columns
      COLS_ROWS[0]
    end

    def rows
      COLS_ROWS[1]
    end

    def card_width
      CARD_SIZE[0]
    end

    def card_height
      CARD_SIZE[1]
    end

    def cards_per_page
      columns * rows
    end

    def display_names(invitation)
    end

    def generate
      invitations = Invitation.all

      Prawn::Document.generate(
        "insert_cards-#{Rails.env}.pdf",
        :page_size => PAGE_SIZE,
        :page_layout => :portrait,
        :margin => MARGIN
      ) do |pdf|
        register_futura(pdf)

        pdf.font('Futura')

        rendered_count = 0
        invitations.each_slice(cards_per_page) do |page_of_invitations|
          1.upto(columns) do |col|
            1.upto(rows) do |row|
              i = (row - 1) * columns + (col - 1)
              invitation = page_of_invitations[i]
              next unless invitation

              draw_rsvp_card(pdf, row, col, invitation)

              rendered_count += 1
            end
          end

          pdf.start_new_page unless rendered_count == invitations.size
        end
      end
    end

    def instruction_format
      @instruction_format ||= { :font => 'Futura Condensed', :size => 11, :color => '909090' }
    end

    def draw_rsvp_card(pdf, row, col, invitation)
      $stderr.puts "[#{row}, #{col}] #{invitation.card_names.strip}"

      left = (col - 1) * card_width
      bottom = pdf.bounds.top_left[1] - (row - 1) * card_height

      instruction_emphasized_color = '606060'

      pdf.bounding_box([left, bottom], :width => card_width - 12, :height => card_height - 20) do
        pdf.formatted_text [
          { :text => "#{invitation.card_names}\n#{invitation.guests_is_are} invited to our wedding\n",
            :size => 14, :color => '444444' },
        ], :align => :center, :valign => :top

        pdf.formatted_text_box [
          instruction_block("To RSVP, please visit ", :size => 10),
          instruction_block("http://mrandmrs.sutph.in/rsvp.html", :styles => [:underline], :color => instruction_emphasized_color),
          instruction_block(" before ", :size => 10),
          instruction_block("April 18", :color => instruction_emphasized_color),
          instruction_block(" and enter\n", :size => 10),
          { :text => "#{invitation.id}\n", :size => 60, :color => '333333', :styles => [:italic] },
        ], :align => :center, :at => [0, pdf.bounds.height / 3 * 2 + 10], :width => card_width

        food_highlight = { :color => instruction_emphasized_color }
        pdf.formatted_text_box [
          instruction_block("When you RSVP, we will ask for an entree selection for each guest.\n"),
          instruction_block("The options are "),
          instruction_block("beef brisket", food_highlight),
          instruction_block(", "),
          instruction_block("pork loin", food_highlight),
          instruction_block(", or "),
          instruction_block("black bean and faro cakes", food_highlight),
          instruction_block(".")
        ], :align => :center, :at => [0, pdf.bounds.height / 3 - 15], :width => card_width

        pdf.formatted_text [
          {
            :text => "If you would prefer to RSVP by phone,\nplease call and leave a message at 510-MAY-18KR (510-629-1857).",
          }.merge(instruction_format),
        ], :valign => :bottom, :align => :center

        # pdf.stroke_bounds
      end
    end

    def instruction_block(text, other_options={})
      instruction_format.merge(:text => text).merge(other_options)
    end

    def register_futura(pdf)
      pdf.font_families.update("Futura" => {
          :normal => (Rails.root + 'fonts/Futura Medium.ttf').to_s,
          :italic => (Rails.root + 'fonts/Futura Medium Italic.ttf').to_s
        }
      )
      pdf.font_families.update("Futura Condensed" => {
        :normal => (Rails.root + 'fonts/Futura Condensed Medium.ttf').to_s,
        :bold   => (Rails.root + 'fonts/Futura Condensed ExtraBold.ttf').to_s
      })
    end

    module InvitationExt
      def card_names
        names = combined_guest_names.upcase.sub(' AND ', ' and ')
        if names.size > 33
          names.sub(' and ', " and\n")
        else
          "\n#{names}"
        end
      end

      def guests_is_are
        guests.size == 1 ? 'is' : 'are'
      end
    end

    Invitation.send(:include, InvitationExt)
  end
end
