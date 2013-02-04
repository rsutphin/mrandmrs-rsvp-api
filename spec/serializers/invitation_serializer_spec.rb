require 'spec_helper'

describe InvitationSerializer do
  describe '#from_json' do
    let(:input) {
      {
        'invitation' => {
          'id' => 'ZP070',
          'response_comments' => 'Too many pickles.',
          'hotel' => 'The one from the sky.'
        }
      }
    }

    let(:result) {
      InvitationSerializer.from_json(input)
    }

    it 'produces a single invitation' do
      result.should be_a(Invitation)
    end

    describe 'for simple attributes' do
      %w(id response_comments hotel).each do |a|
        it "copies #{a}" do
          result.send(a).should == input['invitation'][a]
        end
      end

      it 'does not set other attributes' do
        pending 'there are not any undeclared attributes to use for testing'
      end
    end

    describe 'for associated guests' do
      let(:input) {
        {
          'invitation' => {
            'id' => 'BG103',
            'guests' => [
              'elephantsutphin',
              'pandasutphin'
            ]
          },
          'guests' => [
            {
              'id' => 'elephantsutphin',
              'name' => 'Elephant Sutphin',
              'attending' => true
            },
            {
              'id' => 'pandasutphin',
              'name' => 'Panda Sutphin',
              'attending' => nil
            }
          ]
        }
      }

      it 'creates all the guests in order' do
        result.guests.collect(&:name).should == ['Elephant Sutphin', 'Panda Sutphin']
      end

      it 'links the guests back to the result invitation' do
        result.guests.collect(&:invitation).uniq.should == [result]
      end
    end
  end
end
