require 'spec_helper'
require 'stores/basic_store_behaviors'

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

  describe '#get_sheet' do
    let(:expected_filename) { directory + "#{sheet_name}.csv" }

    def write_test_sheet(*rows)
      expected_filename.open('w') do |f|
        rows.each do |row|
          f.puts row.join(',')
        end
      end
    end

    include_context 'a sheet getter'
  end

  describe '#replace_sheet' do
    let(:expected_filename) { (directory + "#{sheet_name}.csv") }

    def row(n)
      CSV.read(expected_filename.to_s)[n]
    end

    def test_sheet_row_count
      expected_filename.readlines.size
    end

    describe 'when the sheet does not exist' do
      it 'creates a new CSV' do
        expected_filename.exist?.should be_true
      end

      include_context 'a sheet replacer'
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

      include_context 'a sheet replacer'
    end
  end

  describe '#clear' do
    it 'removes all sheets from the directory' do
      directory.mkpath
      (directory + 'foo.csv').open('w') { }
      (directory + 'bar.csv').open('w') { }

      store.clear

      directory.children.should == []
    end
  end
end
