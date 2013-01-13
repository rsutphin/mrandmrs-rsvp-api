require 'csv'

class CsvStore
  attr_reader :directory

  def initialize(directory)
    @directory =
      case directory
      when Pathname
        directory
      else
        Pathname.new(directory.to_s)
      end
  end

  ##
  # Empties all data from the store.
  #
  # @return [void]
  def clear
    directory.rmtree if directory.exist?
    directory.mkpath
  end

  ##
  # @param [String] sheet_name
  # @param [Array<Hash<String,String>>] a set of hashes to comprise the sheet.
  def replace_sheet(sheet_name, hashes)
    headers = headers_for_hashes(hashes)
    directory.mkpath
    CSV.open(sheet_path(sheet_name).to_s, 'w') do |csv|
      csv << headers
      hashes.each do |row|
        csv << headers.collect { |header| row[header] }
      end
    end
  end

  ##
  # @return [Array<Hash<String,String>>] a set of row hashes representing the
  #   named sheet, or nil if there is no such sheet.
  def get_sheet(sheet_name)
    if sheet_path(sheet_name).exist?
      CSV.read(sheet_path(sheet_name).to_s, headers: true).collect(&:to_hash)
    end
  end

  def sheet_path(name)
    directory + "#{name}.csv"
  end
  private :sheet_path

  def headers_for_hashes(hashes)
    hashes.collect { |h| h.keys }.flatten.uniq
  end
  private :headers_for_hashes
end
