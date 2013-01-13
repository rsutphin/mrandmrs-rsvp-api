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

  let(:directory) { Pathname.new(Rails.root + 'tmp' + 'a_store') }
  let(:store) { CsvStore.new(directory) }

  after do
    directory.rmtree if directory.exist?
  end

  describe '#replace_sheet' do
    let(:sheet_name) { 'Invites' }
    let(:expected_filename) { (directory + "#{sheet_name}.csv") }

    shared_context 'sheet replacement' do
      before do
        store.replace_sheet(sheet_name, [{ 'A' => '3', 'C' => '6'}, { 'B' => '1', 'C' => '8' }])
      end

      def row(n)
        CSV.read(expected_filename.to_s)[n]
      end

      it 'creates the header row according to the keys given' do
        row(0).should == %w(A C B)
      end

      it 'creates one row per input hash' do
        expected_filename.readlines.size.should == 3 # incl. header
      end

      it 'puts values with the same key in the same column' do
        [
          row(1)[1],
          row(2)[1]
        ].should == %w(6 8)
      end

      it 'puts values with different keys in different hashes in different columns' do
        [
          row(1)[0], row(1)[2],
          row(2)[0], row(2)[2]
        ].should == [
          '3', nil,
          nil, '1'
        ]
      end
    end

    describe 'when the sheet does not exist' do
      it 'creates a new CSV' do
        expected_filename.exist?.should be_true
      end

      include_context 'sheet replacement'
    end

    describe 'when the sheet already exists' do
      before do
        directory.mkpath
        expected_filename.open('w') do |f|
          f.puts('F,B,Q')
          f.puts('1,2,3')
        end
      end

      it 'completely replaces it' do
        expected_filename.read.should_not =~ /F/
      end

      include_context 'sheet replacement'
    end
  end
end
