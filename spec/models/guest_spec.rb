require 'spec_helper'

describe Guest do
  describe '#id' do
    it 'is generated from the name' do
      Guest.new.tap { |g| g.name = 'Betty Rubble' }.id.should == 'bettyrubble'
    end

    it 'is nil when there is no name' do
      Guest.new.id.should be_nil
    end
  end
end
