require 'spec_helper'

describe CsvStore do
  describe '#initialize' do
    it 'takes a String for the directory' do
      CsvStore.new('/foo/bar').directory.should == Pathname.new('/foo/bar')
    end

    it 'takes a Pathname for the directory' do
      p = Pathname.new('/bar')
      CsvStore.new(p).directory.should be p
    end
  end
end
