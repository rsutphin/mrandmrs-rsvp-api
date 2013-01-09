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
end
