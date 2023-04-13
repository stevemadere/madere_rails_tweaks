# Convenience methods to manipulte a CSV-format data
module CSVUtils
  require 'csv'

  # Generate CSV data from an array of hashes (row_data), with column headers
  # specified in field_list.  From each row, the hash elements corrresponding
  # to the fields in field_list are extracted and made into a CSV row.
  def csv_from_rows(row_data,field_list)
    result = CSV.generate do |csv|
      csv << field_list
      row_data.each do |row|
        row_array = field_list.map { |fn| row[fn] }
        csv << row_array
      end
    end
  end
end
