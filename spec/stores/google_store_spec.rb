require 'spec_helper'
require 'stores/basic_store_behaviors'

describe GoogleStore do
  let(:store) { GoogleStore.new(doc_name) }
  let(:doc_name) { 'GoogleStore test' }

  before(:all) do
    require 'google_device_oauth'
    @drive_session = GoogleDrive.login_with_oauth(
      GoogleDeviceOAuth.new.token.access_token
    )
  end

  let(:spreadsheet) { @drive_session.spreadsheet_by_title(doc_name) }

  after do
    store.clear
  end

  describe '#get_sheet' do
    def write_test_sheet(*rows)
      w = spreadsheet.add_worksheet(sheet_name, rows.size, rows.collect(&:size).max)
      rows.each_with_index do |row, r0|
        row.each_with_index do |v, c0|
          w[r0 + 1, c0 + 1] = v
        end
      end
      w.save
    end

    let(:first_worksheet) { spreadsheet.worksheets.first }

    it 'works when a sheet is empty' do
      first_worksheet.tap do |w|
        w.max_rows = 1
        w.max_cols = 1
        w[1, 1] = nil
        w.save
      end

      store.get_sheet(first_worksheet.title).should == []
    end

    it 'works when a sheet has headers only' do
      first_worksheet.tap do |w|
        w.max_rows = 1
        w.max_cols = 8
        w[1, 1] = 'Foo'
        w[1, 2] = 'Bar'
        w[1, 3] = 'Baz'
        w.save
      end

      store.get_sheet(first_worksheet.title).should == []
    end

    include_context 'a sheet getter'
  end

  describe '#replace_sheet' do
    let(:worksheet) { spreadsheet.worksheets.find { |w| w.title == sheet_name } }

    def row(n)
      worksheet.rows(n).first.collect { |v| v.blank? ? nil : v }
    end

    def test_sheet_row_count
      worksheet.num_cols
    end

    describe 'when the sheet does not exist' do
      it 'creates a new sheet' do
        worksheet.should_not be_nil
      end

      include_context 'a sheet replacer'
    end

    describe 'when the sheet already exists' do
      before do
        new_sheet = spreadsheet.add_worksheet(sheet_name, 2, 3)
        new_sheet.update_cells(1, 1, [
          %w(F B Q),
          %w(1 2 3)
        ])
        new_sheet.save
      end

      it 'completely replaces it' do
        worksheet.rows.flatten.should_not include('F')
      end

      include_context 'a sheet replacer'
    end
  end

  describe '#clear' do
    before do
      spreadsheet.add_worksheet('Baz')
      spreadsheet.add_worksheet('Quux')

      spreadsheet.worksheets.each do |w|
        w[3, 6] = 'Hello'
        w.synchronize
      end

      store.clear
    end

    it 'empties the first sheet' do
      spreadsheet.worksheets.first.tap do |w|
        w.num_rows.should == 0
        w.num_cols.should == 0
      end
    end

    it 'removes all other worksheets' do
      spreadsheet.worksheets.size.should == 1
    end
  end
end
