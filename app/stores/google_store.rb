require 'google_drive'
require 'google_device_oauth'

class GoogleStore
  attr_reader :doc_title

  def initialize(doc_title)
    @doc_title = doc_title
  end

  def get_sheet(sheet_name)
    worksheet = worksheet(sheet_name)
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

    worksheet = worksheet(sheet_name)
    unless worksheet
      worksheet = spreadsheet.add_worksheet(sheet_name, cells.size, headers.size)
      invalidate_worksheets
    end

    0.upto(cells.size - 1) do |r0|
      0.upto(cells.first.size - 1) do |c0|
        new_value = cells[r0][c0]
        r1 = r0 + 1
        c1 = c0 + 1

        if worksheet[r1, c1] != new_value
          worksheet[r1, c1] = new_value
        end
      end
    end
    worksheet.save
  end

  def clear
    # Have to leave one sheet in place at all times.
    worksheets.first.tap do |first_worksheet|
      f_rows = first_worksheet.num_rows
      f_cols = first_worksheet.num_cols
      first_worksheet.update_cells(1, 1, [([nil] * f_cols)] * f_rows)
      first_worksheet.save
    end

    worksheets[1, worksheets.size].each do |later_worksheet|
      later_worksheet.delete
    end
    invalidate_worksheets
  end

  def worksheet(name)
    worksheets.find { |w| w.title == name }
  end
  protected :worksheet

  def worksheets
    @worksheets ||= spreadsheet.worksheets
  end
  protected :worksheets

  def invalidate_worksheets
    @worksheets = nil
  end
  protected :invalidate_worksheets

  def spreadsheet
    @spreadsheet ||= drive_session.spreadsheet_by_title(doc_title).tap do |s|
      unless s
        fail "Could not read spreadsheet #{doc_title.inspect}"
      end
    end
  end
  protected :spreadsheet

  def drive_session
    @drive_session ||= GoogleDrive.login_with_oauth(
      GoogleDeviceOAuth.new.token.access_token
    )
  end
  protected :drive_session

  def headers_for_hashes(hashes)
    hashes.collect { |h| h.keys }.flatten.uniq
  end
  private :headers_for_hashes
end
