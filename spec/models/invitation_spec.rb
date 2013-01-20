require 'spec_helper'

describe Invitation do
  describe 'as DAO' do
    describe '.find' do
      it 'finds an Invitation instance by ID' do
        store.replace_sheet('Invitations', [
          { 'RSVP ID' => 'KR001', 'Guest Name' => 'F' },
          { 'RSVP ID' => 'KR002', 'Guest Name' => 'G' },
          { 'RSVP ID' => 'KR002', 'Guest Name' => 'H' }
        ])

        Invitation.find('KR002').should be_a(Invitation)
      end

      it 'gives nil for a non-existent instance' do
        store.replace_sheet('Invitations', [
          { 'RSVP ID' => 'KR002', 'Guest Name' => 'B' }
        ])

        Invitation.find('KR001').should be_nil
      end

      it 'finds the invitation if there is only guest info' do
        store.replace_sheet('Invitations', [
          { 'RSVP ID' => 'KR002', 'Guest Name' => 'B' }
        ])

        Invitation.find('KR002').should_not be_nil
      end

      it 'does not find the invitation if there is only notes info' do
        store.replace_sheet('Response Notes', [
          { 'RSVP ID' => 'KR002', 'Hotel' => 'A thing' }
        ])

        Invitation.find('KR002').should be_nil
      end

      describe 'the loaded instance' do
        let(:invitation) { Invitation.find('KR345') }
        let(:blank_invitation) { Invitation.find('KR123') }

        before do
          store.replace_sheet('Invitations', [
            { 'RSVP ID' => 'KR345', 'Guest Name' => 'AP', 'E-mail Address' => 'ap@example.com', 'Attending?' => 'y', 'Entree Choice' => 'Crab' },
            { 'RSVP ID' => 'KR345', 'Guest Name' => 'SP', 'E-mail Address' => 'sp@example.com', 'Attending?' => nil },
            { 'RSVP ID' => 'KR345', 'Guest Name' => 'RP', 'E-mail Address' => '', 'Attending?' => 'n', 'Entree Choice' => '' },
            { 'RSVP ID' => 'KR123', 'Guest Name' => 'ES', 'E-mail Address' => '', 'Attending?' => '', 'Entree Choice' => '' }
          ])

          store.replace_sheet('Response Notes', [
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
    end
  end
end
