require 'spec_helper'

describe Guest do
  it 'generates its ID from the name' do
    Guest.new.tap { |g| g.name = 'Betty Rubble' }.id.should == 'bettyrubble'
  end
end
