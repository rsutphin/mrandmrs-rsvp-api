# Expects the following methods (with return values):
# - store: the store implementation which responds to replace_sheet
# - test_sheet_row_count: the number of rows in the sheet
# - row(n): an array reflecting the raw contents of row n (zero-based)
shared_context 'a sheet replacer' do
  let(:sheet_name) { 'Invites' }

  before do
    store.replace_sheet(sheet_name, [{ 'A' => '3', 'C' => '6'}, { 'B' => '1', 'C' => '8' }])
  end

  it 'creates the header row according to the keys given' do
    row(0).should == %w(A C B)
  end

  it 'creates one row per input hash' do
    test_sheet_row_count.should == 3 # incl. header
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

# Expects the following methods:
# - store: the store implementation which responds to get_sheet
# - write_test_sheet(*rows): arranges for a spreadsheet to exist where the store
#   is looking containing the raw rows and columns corresponding to the given
#   row arrays
shared_context 'a sheet getter' do
  let(:sheet) { store.get_sheet(sheet_name) }
  let(:sheet_name) { 'Frobs' }

  before do
    write_test_sheet(
      %w(H1 H3 H7 H2),
      %w(A B Q Eleven),
      %w(B 6 H Seven)
    )
  end

  it 'returns an enumerable of indexed rows' do
    sheet.collect { |row| row.respond_to?(:[]) }.uniq.should be_true
  end

  it 'returns all the rows from the sheet' do
    sheet.size.should == 2
  end

  it 'returns all the columns from the sheet' do
    sheet.collect(&:keys).uniq.should == [%w(H1 H3 H7 H2)]
  end

  it 'returns the rows in order' do
    sheet.collect { |row| row['H3'] }.should == %w(B 6)
  end

  it 'returns nil for an unknown sheet' do
    store.get_sheet('Zap').should be_nil
  end
end
