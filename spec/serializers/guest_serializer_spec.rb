require 'spec_helper'

describe GuestSerializer do
  describe '#from_json' do
    let(:input) {
      {
        'id' => 'emilycarolina',
        'name' => 'Emily Carolina',
        'email_address' => 'ec@example.com',
        'entree_choice' => 'Fish',
        'attending' => true
      }
    }

    let(:result) {
      GuestSerializer.from_json(input)
    }

    it 'produces a Guest instance' do
      result.should be_a Guest
    end

    %w(email_address entree_choice attending name).each do |a|
      it "copies over #{a}" do
        result.send(a).should == input[a]
      end
    end

    it 'ignores undeclared attributes' do
      input['invitation_id'] = 'Foo'
      result.invitation.should be_nil
    end
  end
end
