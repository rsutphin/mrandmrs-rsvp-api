require 'spec_helper'
require_relative 'active_model_behaviors'

describe Guest do
  describe '#id' do
    it 'is generated from the name' do
      Guest.new.tap { |g| g.name = 'Betty Rubble' }.id.should == 'bettyrubble'
    end

    it 'is nil when there is no name' do
      Guest.new.id.should be_nil
    end
  end

  describe '#invitation_id' do
    it 'is nil with no invitation' do
      Guest.new.invitation_id.should be_nil
    end

    it 'is the invitation ID when there is an invitation' do
      invitation = Invitation.new.tap { |i| i.id = 'Foo' }
      Guest.new.tap { |g| g.invitation = invitation }.invitation_id.should == 'Foo'
    end
  end

  describe '#invitation_id=' do
    let(:invitation) { Invitation.new.tap { |i| i.id = 'Foo' } }

    describe 'when there is no associated invitation' do
      let(:guest) { Guest.new }

      it 'creates an associated invitation record if set to a concrete value' do
        guest.invitation_id = 'Baz'

        guest.invitation.id.should == 'Baz'
      end

      it 'does nothing if set to nil' do
        guest.invitation_id = nil

        guest.invitation.should be_nil
      end
    end

    describe 'when there is an associated invitation' do
      let(:guest) { Guest.new.tap { |g| g.invitation = invitation } }

      it 'fails if the new ID is different' do
        expect { guest.invitation_id = 'Bar' }.to raise_error(/Cannot change invitation ID for guest nil/)
      end

      it 'fails if the new ID is nil' do
        expect { guest.invitation_id = nil }.to raise_error(/Cannot change invitation ID for guest nil/)
      end

      it 'does nothing if the new ID is the same as the existing' do
        guest.invitation_id = invitation.id

        guest.invitation.should be(invitation)
      end
    end
  end

  describe '#save' do
    let(:invitation_id) { 'GR003' }

    let(:guest) {
      Guest.new.tap do |g|
        g.name = 'Fred Johansson'
        g.invitation = Invitation.new.tap { |i| i.id = 'GR003' }
      end
    }

    describe 'updating an existing record' do
      before do
        store.replace_sheet(Guest.sheet_name, [
          { 'RSVP ID' => invitation_id, 'Guest Name' => 'Fred Johansson', 'E-mail Address' => 'fred@example.net' },
          { 'RSVP ID' => invitation_id, 'Guest Name' => 'Carol Emil', 'E-mail Address' => 'cemil@example.net' }
        ])
      end

      let(:result_row) {
        store.get_sheet(Guest.sheet_name).detect { |row| row['Guest Name'] == guest.name }
      }

      it 'updates the identified record only' do
        guest.save

        store.get_sheet(Guest.sheet_name).collect { |row| row['Guest Name'] }.sort.should == [
          'Carol Emil', 'Fred Johansson'
        ]
      end

      describe '#attending' do
        it 'can be updated to true' do
          guest.attending = true
          guest.save
          result_row['Attending?'].should == 'Yes'
        end

        it 'can be updated to false' do
          guest.attending = false
          guest.save
          result_row['Attending?'].should == 'No'
        end

        it 'can be updated to nil' do
          guest.attending = nil
          guest.save
          result_row['Attending?'].should be_nil
        end
      end

      describe '#email_address' do
        it 'can be updated' do
          guest.email_address = 'fred@j.example.com'
          guest.save
          result_row['E-mail Address'].should == 'fred@j.example.com'
        end
      end

      describe '#entree_choice' do
        it 'can be updated' do
          guest.entree_choice = 'Ice Cream Sandwiches'
          guest.save
          result_row['Entree Choice'].should == 'Ice Cream Sandwiches'
        end
      end
    end

    describe 'adding a new record' do
      it 'is prohibited' do
        guest.name = 'Pony'

        expect { guest.save }.to raise_error(/Invitation "GR003" does not include a guest named "Pony"/)
      end
    end
  end

  context '' do
    let(:record) { Guest.new.tap { |g| g.name = 'Seventeen Elf' } }

    it_behaves_like 'an ActiveModel instance in this project'
  end
end
