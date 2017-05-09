require 'pathname'

class EmailHelper
  attr_accessor :raw_email

  def initialize(filename)
    @filename = filename
    @raw_email = ""
    parse_file
  end

  def parse_file
    if Pathname.new(@filename).expand_path.file?
      lines = []
      File.open(@filename, 'r') do |file|
        while line = file.gets
          @raw_email += line
        end
      end
    else
      raise "File not found."
    end
  end
end
