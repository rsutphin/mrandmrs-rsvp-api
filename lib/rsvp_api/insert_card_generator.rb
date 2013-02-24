require 'prawn'
require 'prawn/measurement_extensions'

module RsvpApi
  class InsertCardGenerator
    PAGE_SIZE = [8.5.in, 11.in]
    MARGIN = 0.25.in
    COLS_ROWS = [2, 4]

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

    def generate
      invitations = Invitation.all

      Prawn::Document.generate("insert_cards-#{Rails.env}.pdf", :page_size => PAGE_SIZE, :page_layout => :portrait, :margin => MARGIN) do |pdf|
        pdf.font_families.update("Futura" => {
            :normal => (Rails.root + 'fonts/Futura Medium.ttf').to_s,
            :italic => (Rails.root + 'fonts/Futura Medium Italic.ttf').to_s
          }
        )
        pdf.font_families.update("Futura Condensed" => {
          :normal => (Rails.root + 'fonts/Futura Condensed Medium.ttf').to_s,
          :bold   => (Rails.root + 'fonts/Futura Condensed ExtraBold.ttf').to_s
        })

        pdf.font('Futura')

        rendered_count = 0
        invitations.each_slice(cards_per_page) do |page_of_invitations|
          1.upto(columns) do |col|
            left = (col - 1) * card_width
            1.upto(rows) do |row|
              i = (row - 1) * columns + (col - 1)
              invitation = page_of_invitations[i]
              next unless invitation
              names = invitation.combined_guest_names.upcase.sub(' AND ', ' and ')
              if names.size > 35
                names.sub!(' and ', " and\n")
              else
                names = "\n#{names}"
              end

              is_are = invitation.guests.size == 1 ? 'is' : 'are'

              $stderr.puts "[#{row}, #{col}] #{names}"

              bottom = pdf.bounds.top_left[1] - (row - 1) * card_height

              pdf.bounding_box([left, bottom], :width => card_width - 12, :height => card_height - 20) do
                pdf.formatted_text [
                  { :text => "#{names}\n#{is_are} invited to our wedding\n",
                    :size => 13, :color => '444444' },
                ], :align => :center, :valign => :top

                instruction_format = { :font => 'Futura Condensed', :size => 10, :color => '888888' }

                pdf.formatted_text_box [
                  { :text => "To RSVP, please visit " }.merge(instruction_format),
                  { :text => "http://mrandmrs.sutph.in/rsvp.html", :styles => [:underline] }.merge(instruction_format),
                  { :text => " before April 18 and enter\n" }.merge(instruction_format),
                  { :text => "#{invitation.id}\n", :size => 54, :color => '333333', :styles => [:italic] },
                ], :align => :center, :at => [0, pdf.bounds.height / 2 + (60) / 2], :width => card_width

                pdf.formatted_text [
                  {
                    :text => "If you would prefer to RSVP by phone, please call and leave a message at\n510-MAY-18KR (510-629-1857).",
                  }.merge(instruction_format),
                ], :valign => :bottom, :align => :center

                # pdf.stroke_bounds
              end
              rendered_count += 1
            end
          end

          pdf.start_new_page unless rendered_count == invitations.size
        end
      end
    end
  end
end
