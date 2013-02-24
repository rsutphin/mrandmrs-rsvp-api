require 'google_drive'
require 'google_device_oauth'

class GoogleStore
  attr_reader :doc_title

  def initialize(doc_title)
    @doc_title = doc_title
  end

  def get_sheet(sheet_name)
    worksheet = spreadsheet.worksheets.find { |w| w.title == sheet_name }
    return nil unless worksheet

    rows = worksheet.rows
    header = rows[0]
    data   = rows.slice(1, rows.size)
    if data
      data.collect { |row|
        Hash[header.zip(row)]
      }
    else
      []
    end
  end

  def replace_sheet(sheet_name, row_hashes)
    headers = headers_for_hashes(row_hashes)
    cells = [headers] + row_hashes.collect { |row| headers.collect { |header| row[header] } }

    worksheet = spreadsheet.worksheets.find { |w| w.title == sheet_name }
    if worksheet
      worksheet.max_rows = cells.size
      worksheet.max_cols = headers.size
    else
      worksheet = spreadsheet.add_worksheet(sheet_name, cells.size, headers.size)
    end

    worksheet.update_cells(1, 1, cells)
    worksheet.synchronize
  end

  def clear
    spreadsheet.worksheets.first.tap do |first_worksheet|
      f_rows = first_worksheet.num_rows
      f_cols = first_worksheet.num_cols
      first_worksheet.update_cells(1, 1, [([nil] * f_cols)] * f_rows)
      first_worksheet.save
    end

    spreadsheet.worksheets[1, spreadsheet.worksheets.size].each do |later_worksheet|
      later_worksheet.delete
    end
  end

  def spreadsheet
    @spreadsheet ||= drive_session.spreadsheet_by_title(doc_title).tap do |s|
      unless s
        fail "Could not read spreadsheet #{doc_title.inspect}"
      end
    end
  end
  protected :spreadsheet

  def drive_session
    @drive_session = GoogleDrive.login_with_oauth(
      GoogleDeviceOAuth.new.token.access_token
    )
  end
  protected :drive_session

  def headers_for_hashes(hashes)
    hashes.collect { |h| h.keys }.flatten.uniq
  end
  private :headers_for_hashes
end
