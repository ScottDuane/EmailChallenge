require "minitest/autorun"
require "minitest/reporters"
require "minitest/benchmark" if ENV["BENCH"]
Minitest::Reporters.use!

class Email
  attr_accessor :raw_email

  VALID_HEADERS = ["From", "To", "Subject", "Delivered-To", "Received", "X-Received",
                   "Return-Path", "Received-SPF", "Authentication-Results", "DKIM-Signature",
                   "X-MSFBL", "Message-ID", "Date", "Content-Type", "MIME-Version", "X-Transport",
                   "guid", "X-Trulia-Platform", "X-Sent-Using", "X-Trulia-Campaign", "X-Trulia-PayloadId",
                   "Reply-To", "Feedback-ID", "List-Unsubscribe", "List-Id"] # assume this list will expand to 100+ values
  NEWLINE_PATTERNS = ["\n", "\r\n"]

  def initialize(raw_email: nil)
    @raw_email = raw_email
    @header_hash = {}
    @max_header_length = 0
    create_header_helpers
  end

  def create_header_helpers
    VALID_HEADERS.each do |header|
      @header_hash[header] = true
      @max_header_length = header.length if header.length > @max_header_length
    end
  end

  def remove_double_new_lines_between_headers
    idx = is_legal_header?(0)

    raise "Malformed header" unless !!idx

    full_header = @raw_email[0..idx]
    body_found = false

    until body_found
      newline_bounds = get_newline_bounds(idx)
      full_header += @raw_email[idx+1...newline_bounds[0]]
      colon_idx = is_legal_header?(newline_bounds[1])

      if !!colon_idx
        parsed_newline = parse_into_legal_newline(newline_bounds)
        full_header += parsed_newline
        full_header += @raw_email[newline_bounds[1]..colon_idx]
        idx = colon_idx
      else
        body_found = true
        idx = newline_bounds[0]
      end
    end

    parsed_email = full_header + @raw_email[idx...@raw_email.length]
    @raw_email = parsed_email
  end

  def get_newline_bounds(start_idx)
    start_idx += 1 until @raw_email[start_idx] == "\n" || @raw_email[start_idx] == "\r"

    stop_idx = start_idx
    stop_idx += 1 while @raw_email[stop_idx] == "\n" || @raw_email[stop_idx] == "\r"

    [start_idx, stop_idx]
  end

  def is_legal_header?(start_idx)
    curr_idx = start_idx
    curr_idx += 1 while @raw_email[curr_idx] && (@raw_email[curr_idx] != ":" &&  curr_idx - start_idx - 1 < @max_header_length)

    return @raw_email[curr_idx] == ":" && @header_hash[@raw_email[start_idx...curr_idx]] ? curr_idx : false
  end

  def parse_into_legal_newline(bounds)
    return @raw_email[bounds[0]] if bounds[0] == bounds[1]
    # this part needs some work...how do we parse in general?
    return "\n" if @raw_email[bounds[0]] == "\n"
    return "\r\n" if @raw_email[bounds[0]] == "\r"
  end
end

describe Email do
  aol_mail = EmailHelper.new('./email_3.txt')
  spam_gmail = EmailHelper.new('./email_1.txt')
  reg_gmail = EmailHelper.new('./email_2.txt')

  describe "#remove_double_new_lines_between_headers" do

    ## TASK 2 ##

    describe "raw_email contains one set of double new lines in headers" do
      it "removes extra new line from headers" do
        raw_email = "From: \"Cliff Clavin\"<cliff@cheers.com>\n\nTo: \"Randall Flagg\" <walkindude@lasvegas.com>\n\nMade it!!!!\n\nYay!"
        expected  = "From: \"Cliff Clavin\"<cliff@cheers.com>\nTo: \"Randall Flagg\" <walkindude@lasvegas.com>\n\nMade it!!!!\n\nYay!"
        assert_equal expected, Email.new(raw_email: raw_email).remove_double_new_lines_between_headers
      end
    end

    ## TASK 3 ##

    describe "raw_email contains multiple sets of double new lines in headers" do
      it "removes extra new lines from headers" do
        raw_email = "From: \"Cliff Clavin\"<cliff@cheers.com>\n\nTo: \"Randall Flagg\" <walkindude@lasvegas.com>\n\nSubject: What! What!\n\nMade it!!!!\n\nYay!"
        expected  = "From: \"Cliff Clavin\"<cliff@cheers.com>\nTo: \"Randall Flagg\" <walkindude@lasvegas.com>\nSubject: What! What!\n\nMade it!!!!\n\nYay!"
        assert_equal expected, Email.new(raw_email: raw_email).remove_double_new_lines_between_headers
      end
    end

    ## TASK 4 ##

    describe "raw_email doesn't contain double new lines in headers" do
      it "does nothing" do
        raw_email = "From: \"Cliff Clavin\"<cliff@cheers.com>\nTo: \"Randall Flagg\" <walkindude@lasvegas.com>\n\nMade it!!!!\n\nYay!"
        assert_equal raw_email, Email.new(raw_email: raw_email).remove_double_new_lines_between_headers
      end
    end

    ## TASK 5 ##

    describe "raw_email has multiple sets of double (windows style) new lines in headers" do
      it "removes extra new lines from headers" do
        raw_email = "From: \"Cliff Clavin\"<cliff@cheers.com>\r\n\r\nTo: \"Randall Flagg\" <walkindude@lasvegas.com>\r\n\r\nSubject: What! What!\r\n\r\nMade it!!!!\r\n\r\nYay!"
        expected  = "From: \"Cliff Clavin\"<cliff@cheers.com>\r\nTo: \"Randall Flagg\" <walkindude@lasvegas.com>\r\nSubject: What! What!\r\n\r\nMade it!!!!\r\n\r\nYay!"
        assert_equal expected, Email.new(raw_email: raw_email).remove_double_new_lines_between_headers
      end
    end

    ## TASK 6 ##

    describe "Meme Benchmark" do
      raw_email = "From: \"Cliff Clavin\"<cliff@cheers.com>\r\n\r\nTo: \"Randall Flagg\" <walkindude@lasvegas.com>\r\n\r\nSubject: What! What!\r\n\r\nMade it!!!!\r\n\r\nYay!"
      email = Email.new(raw_email: raw_email)

      if ENV["BENCH"] then
        bench_performance_linear "remove_double_new_lines_between_headers", 0.9999 do |n|
          100.times do
            email.remove_double_new_lines_between_headers
          end
        end
      end
    end
    # Raise an error if the header is malformed
    # Read in some emails from different sources and make sure timing is good
    # candidate to provide additional tests as necessary...

  end
end
