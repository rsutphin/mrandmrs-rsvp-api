require 'spec_helper'
require_relative 'active_model_behaviors'

describe Invitation do
  describe 'as DAO' do
    describe '.find' do
      it 'finds an Invitation instance by ID' do
        app_store.replace_sheet(Guest.sheet_name, [
          { 'RSVP ID' => 'KR001', 'Guest Name' => 'F' },
          { 'RSVP ID' => 'KR002', 'Guest Name' => 'G' },
          { 'RSVP ID' => 'KR002', 'Guest Name' => 'H' }
        ])

        Invitation.find('KR002').should be_a(Invitation)
      end

      it 'gives nil for a non-existent instance' do
        app_store.replace_sheet(Guest.sheet_name, [
          { 'RSVP ID' => 'KR002', 'Guest Name' => 'B' }
        ])

        Invitation.find('KR001').should be_nil
      end

      it 'finds the invitation if there is only guest info' do
        app_store.replace_sheet(Guest.sheet_name, [
          { 'RSVP ID' => 'KR002', 'Guest Name' => 'B' }
        ])

        Invitation.find('KR002').should_not be_nil
      end

      it 'does not find the invitation if there is only notes info' do
        app_store.replace_sheet(Invitation.sheet_name, [
          { 'RSVP ID' => 'KR002', 'Hotel' => 'A thing' }
        ])

        Invitation.find('KR002').should be_nil
      end

      describe 'the loaded instance' do
        let(:invitation) { Invitation.find('KR345') }
        let(:blank_invitation) { Invitation.find('KR123') }

        before do
          app_store.replace_sheet(Guest.sheet_name, [
            {
              'RSVP ID' => 'KR345', 'Guest Name' => 'AP', 'E-mail Address' => 'ap@example.com', 'Attending?' => 'y', 'Entree Choice' => 'Crab',
              'Invited to Rehearsal Dinner?' => '', 'Attending Rehearsal Dinner?' => 'n'
            },
            {
              'RSVP ID' => 'KR345', 'Guest Name' => 'SP', 'E-mail Address' => 'sp@example.com', 'Attending?' => nil,
              'Invited to Rehearsal Dinner?' => 'y', 'Attending Rehearsal Dinner?' => 'Y'
            },
            {
              'RSVP ID' => 'KR345', 'Guest Name' => 'RP', 'E-mail Address' => '', 'Attending?' => 'n', 'Entree Choice' => '',
              'Invited to Rehearsal Dinner?' => 'n', 'Attending Rehearsal Dinner?' => ''
            },
            { 'RSVP ID' => 'KR123', 'Guest Name' => 'ES', 'E-mail Address' => '', 'Attending?' => '', 'Entree Choice' => '' }
          ])

          app_store.replace_sheet(Invitation.sheet_name, [
            { 'RSVP ID' => 'KR345', 'Comments' => "Eat at Joe's", 'Hotel' => 'The fancy one by the river' },
            { 'RSVP ID' => 'KR123', 'Comments' => '', 'Hotel' => '' }
          ])
        end

        it 'includes the ID' do
          invitation.id.should == 'KR345'
        end

        it 'includes the guests' do
          invitation.guests.collect(&:class).should == [Guest] * 3
        end

        describe 'guest details' do
          it 'includes the ID' do
            invitation.guests.collect(&:id).should == %w(ap sp rp)
          end

          it 'includes the name' do
            invitation.guests.collect(&:name).should == %w(AP SP RP)
          end

          it 'includes the e-mail address' do
            invitation.guests.collect(&:email_address).should == ['ap@example.com', 'sp@example.com', nil]
          end

          it 'includes attendance status' do
            invitation.guests.collect(&:attending).should == [true, nil, false]
          end

          it 'includes entree choice' do
            invitation.guests.collect(&:entree_choice).should == ['Crab', nil, nil]
          end

          it 'includes the reverse link to the invitation' do
            invitation.guests.collect(&:invitation).should == [invitation] * 3
          end

          it 'includes the rehearsal dinner invite status' do
            invitation.guests.collect(&:invited_to_rehearsal_dinner).should == [false, true, false]
          end

          it 'includes the rehearsal dinner attendance status' do
            invitation.guests.collect(&:attending_rehearsal_dinner).should == [false, true, nil]
          end
        end

        describe '#hotel' do
          it 'reflects a set value' do
            invitation.hotel.should == 'The fancy one by the river'
          end

          it 'is nil if blank' do
            blank_invitation.hotel.should be_nil
          end
        end

        describe '#response_comments' do
          it 'reflects a set value' do
            invitation.response_comments.should == "Eat at Joe's"
          end

          it 'is nil if blank' do
            blank_invitation.response_comments.should be_nil
          end
        end
      end

      describe 'when found with a different case' do
        before do
          app_store.replace_sheet(Guest.sheet_name, [
            { 'RSVP ID' => 'Kr002', 'Guest Name' => 'B' },
            { 'RSVP ID' => 'Kr001', 'Guest Name' => 'A' }
          ])
        end

        let(:with_different_case) { Invitation.find('kR002') }

        it 'finds the invitation' do
          with_different_case.should_not be_nil
        end

        it 'returns the persisted ID' do
          with_different_case.id.should == 'Kr002'
        end
      end
    end

    describe '.all' do
      before do
        app_store.replace_sheet(Guest.sheet_name, [
          { 'RSVP ID' => 'KR001', 'Guest Name' => 'F' },
          { 'RSVP ID' => 'KR002', 'Guest Name' => 'G' },
          { 'RSVP ID' => 'KR002', 'Guest Name' => 'H' },
          { 'RSVP ID' => 'KR003', 'Guest Name' => 'I' }
        ])

        app_store.replace_sheet(Invitation.sheet_name, [
          { 'RSVP ID' => 'KR002', 'Hotel' => 'Madison Radisson' },
          { 'RSVP ID' => 'KR100', 'Response Notes' => 'Where is everyone?' }
        ])
      end

      let(:all) { Invitation.all }

      it 'finds all the invitations' do
        all.size.should == 3
      end

      it 'does not include ones without guests' do
        all.collect(&:id).should_not include('KR100')
      end

      it 'does include ones without response notes' do
        all.collect(&:id).should include('KR001')
      end

      it 'associates the guests with the correct invitations' do
        all.each_with_object({}) { |i, map| map[i.id] = i.guests.collect(&:name) }.should == {
          'KR001' => %w(F),
          'KR002' => %w(G H),
          'KR003' => %w(I)
        }
      end

      it 'loads invitation attributes' do
        all.find { |i| i.id == 'KR002' }.hotel.should == 'Madison Radisson'
      end
    end

    describe '.exist?' do
      let(:invitation_id) { 'KR900' }

      describe 'when there is a guest with the ID' do
        before do
          app_store.replace_sheet(Guest.sheet_name, [
            { 'RSVP ID' => invitation_id, 'Guest Name' => 'E T C', 'E-mail Address' => 'e@tc' }
          ])
        end

        it 'is true' do
          Invitation.exist?(invitation_id).should be_true
        end
      end

      describe 'when there is no guest with that ID' do
        before do
          app_store.replace_sheet(Guest.sheet_name, [
            { 'RSVP ID' => 'KR009', 'Guest Name' => 'E T C', 'E-mail Address' => 'e@tc' }
          ])
        end

        it 'is false' do
          Invitation.exist?(invitation_id).should be_false
        end

        it 'is false even if there is an invitation row with that ID' do
          app_store.replace_sheet(Invitation.sheet_name, [
            { 'RSVP ID' => invitation_id  }
          ])

          Invitation.exist?(invitation_id).should be_false
        end
      end
    end

    describe '#save' do
      let(:invitation_id) { 'KR900' }
      let(:stored_invitation_id) { invitation_id }

      let(:invitation) {
        Invitation.new.tap do |i|
          i.id = invitation_id
          i.response_comments = 'Foo'
          i.hotel = 'Bar'
        end
      }

      before do
        app_store.replace_sheet(Guest.sheet_name, [
          { 'RSVP ID' => stored_invitation_id, 'Guest Name' => 'E T C', 'E-mail Address' => 'e@tc' }
        ])
      end

      describe 'of invitation attributes' do
        shared_context 'updating invitation attributes' do
          before do
            invitation.save
          end

          it 'stores response_comments' do
            Invitation.find(invitation_id).response_comments.
              should == invitation.response_comments
          end

          it 'stores hotel' do
            Invitation.find(invitation_id).hotel.
              should == invitation.hotel
          end
        end

        describe 'when there is an existing row' do
          before do
            app_store.replace_sheet(Invitation.sheet_name, [
              { 'RSVP ID' => stored_invitation_id, 'Comments' => 'Etc', 'Hotel' => 'Etc' }
            ])
          end

          include_context 'updating invitation attributes'
        end

        describe 'when there is no existing row' do
          before do
            app_store.replace_sheet(Invitation.sheet_name, [
              { 'RSVP ID' => 'KR111' }
            ])
          end

          include_context 'updating invitation attributes'
        end

        describe 'when the sheet does not exist' do
          include_context 'updating invitation attributes'
        end
      end

      describe 'when the invitation being saved has a different case' do
        let(:invitation_id) { 'kr900' }
        let(:stored_invitation_id) { invitation_id.upcase }

        before do
          invitation.save
        end

        it 'preserves the stored ID in the inviration table' do
          app_store.get_sheet(Invitation.sheet_name).first['RSVP ID'].should == stored_invitation_id
        end
      end

      # Further guest saving details are described in guest_spec
      describe 'cascading to guests' do
        let(:existing_guest) {
          Guest.new.tap do |g|
            g.name = 'E T C'
            g.email_address = 'e@tc'
            g.invitation = invitation
          end
        }

        let(:new_guest) {
          Guest.new.tap do |g|
            g.name = 'Newton'
            g.invitation = invitation
          end
        }

        it 'updates an existing guest' do
          invitation.guests << existing_guest
          existing_guest.attending = true
          invitation.save

          Invitation.find(invitation.id).guests.first.attending.should be_true
        end

        it 'fails if given a new guest' do
          invitation.guests << new_guest

          expect { invitation.save }.to raise_error(/Invitation "#{invitation_id}" does not include a guest named "Newton"/)
        end
      end
    end
  end

  context '' do
    let(:record) { Invitation.new.tap { |i| i.id = 'FO000' } }

    it_behaves_like 'an ActiveModel instance in this project'
  end

  describe 'validation' do
    let(:invitation) {
      Invitation.new.tap { |i|
        i.id = 'FO000'
      }
    }

    %w(response_comments hotel).each do |string_attribute|
      describe "of ##{string_attribute}" do
        it 'is valid when a reasonable length' do
          invitation.send("#{string_attribute}=", 'foo' * 50)
          invitation.should be_valid
        end

        it 'is invalid when very long' do
          invitation.send("#{string_attribute}=", 'foo' * 6000)
          invitation.should_not be_valid

          invitation.errors[string_attribute].should == [
            "is too long (maximum is 16384 characters)"
          ]
        end
      end
    end

    describe 'of guests' do
      before do
        app_store.replace_sheet(Guest.sheet_name, [
          { 'RSVP ID' => invitation.id, 'Guest Name' => 'Alpha' },
          { 'RSVP ID' => invitation.id, 'Guest Name' => 'Beta' }
        ])

        app_store.replace_sheet(Invitation.sheet_name, [
          { 'RSVP ID' => invitation.id }
        ])
      end

      def add_guest(name)
        g = Guest.new.tap { |g| g.name = name; g.invitation = invitation }
        invitation.guests << g
      end

      it 'prevents removing a guest' do
        add_guest('Alpha')
        invitation.should_not be_valid

        invitation.errors['guests'].should == [
          "cannot remove a guest"
        ]
      end

      it 'accepts the same guests' do
        add_guest('Beta')
        add_guest('Alpha')
        invitation.should be_valid
      end

      it 'prevents adding another guest' do
        add_guest('Alpha')
        add_guest('Gamma')
        add_guest('Beta')
        invitation.should_not be_valid

        invitation.errors['guests'].should == [
          "cannot add a guest"
        ]
      end

      it 'is invalid when a guest is invalid' do
        pending 'It seems like this should be simple, but it is not.'

        add_guest('Beta')
        add_guest('Alpha')
        invitation.guests.first.attending = 'frob'

        invitation.should_not be_valid
      end
    end
  end

  describe '#combined_guest_names' do
    def invitation_with_guest_names(*names)
      Invitation.new.tap do |i|
        names.each do |name|
          i.guests << Guest.new.tap { |g| g.name = name }
        end
      end
    end

    def combined_for(*names)
      invitation_with_guest_names(*names).combined_guest_names
    end

    it 'combines the first names for a couple with the same last name' do
      combined_for('Alice Bridges', 'Amy Bridges').should == 'Alice and Amy Bridges'
    end

    it 'combines the first names for a couple where one has a multi-part first name' do
      combined_for('Jim Bob Bridges', 'Amy Bridges').should == 'Jim Bob and Amy Bridges'
    end

    it 'does not combine the first names for a couple with different last names' do
      combined_for('Alice Jones', 'Amy Smith').should == 'Alice Jones and Amy Smith'
    end

    it 'does not combine the names for a plus-one' do
      combined_for('Fred Jones', 'Guest').should == 'Fred Jones and Guest'
    end

    it 'combines the first names for a family with the same last name' do
      combined_for('A. Benjamin', 'D. Benjamin', 'F. Benjamin').should ==
        'A., D., and F. Benjamin'
    end

    it 'does not combine the first names for a family with one different last name' do
      combined_for('A. Benjamin', 'D. Benjamin', 'F. Houlihan').should ==
        'A. Benjamin, D. Benjamin, and F. Houlihan'
    end
  end
end
