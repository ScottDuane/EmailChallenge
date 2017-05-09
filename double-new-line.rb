require "minitest/autorun"
require "minitest/reporters"
require "./email_helper.rb"


Minitest::Reporters.use!

class Email
  attr_accessor :raw_email

  VALID_HEADERS = ["From",
                   "To",
                   "Subject",
                   "Delivered-To",
                   "Received",
                   "X-Received",
                   "Return-Path",
                   "Received-SPF",
                   "Authentication-Results",
                   "DKIM-Signature",
                   "X-MSFBL",
                   "Message-ID",
                   "Date",
                   "Content-Type",
                   "MIME-Version",
                   "X-Transport",
                   "guid",
                   "X-Trulia-Platform",
                   "X-Sent-Using",
                   "X-Trulia-Campaign",
                   "X-Trulia-PayloadId",
                   "Reply-To",
                   "Feedback-ID",
                   "List-Unsubscribe",
                   "List-Id"]
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

    raise StandardError, "Malformed header" unless !!idx

    full_header = @raw_email[0..idx]
    body_found = false

    until body_found
      parsed_header_value = parse_header_value(idx + 1)
      full_header += parsed_header_value[0]
      idx = parsed_header_value[1]
      colon_idx = is_legal_header?(idx)
      if !!colon_idx
        full_header += @raw_email[idx..colon_idx]
        idx = colon_idx
      elsif !!parsed_header_value[2]
        full_header += parsed_header_value[2]
        body_found = true
      else
        raise StandardError, "Malformed header" unless parsed_header_value[2]
      end
    end

    parsed_email = full_header + @raw_email[idx...@raw_email.length]
    @raw_email = parsed_email
  end

  def is_legal_header?(start_idx)
    curr_idx = start_idx
    curr_idx += 1 while @raw_email[curr_idx] && (@raw_email[curr_idx] != ":" &&  curr_idx - start_idx - 1 < @max_header_length)

    return @raw_email[curr_idx] == ":" && @header_hash[@raw_email[start_idx...curr_idx]] ? curr_idx : false
  end

  def parse_header_value(start_idx)
    char_count = 0
    partial_header = ""
    idx = start_idx

    until char_count > 998
      if @raw_email[idx..idx+1] == "\n\n"
        next_line_idx = idx + 2
        partial_header += "\n"
        next_char = @raw_email[next_line_idx]
        return [partial_header, next_line_idx, "\n"] unless next_char == " " || next_char == "\t"

        char_count += next_line_idx - idx
        idx = next_line_idx
      elsif @raw_email[idx..idx+3] == "\r\n\r\n"
        next_line_idx = idx + 4
        partial_header += "\r\n"
        next_char = @raw_email[next_line_idx]
        return [partial_header, next_line_idx, "\r\n"] unless next_char == " " || next_char == "\t"

        char_count += next_line_idx - idx
        idx = next_line_idx
      elsif @raw_email[idx] == "\n" || @raw_email[idx..idx+1] == "\r\n"
        next_line_idx = @raw_email[idx] == "\r" ? idx + 2 : idx + 1
        partial_header = @raw_email[idx] == "\r" ? partial_header + "\r\n" : partial_header + "\n"

        return [partial_header, next_line_idx, false] unless @raw_email[next_line_idx] == " "

        char_count += next_line_idx - idx
        idx = next_line_idx
      else
        char_count += 1
        partial_header += @raw_email[idx]
        idx += 1
      end
    end

    raise StandardError, "Malformed header"
  end
end

describe Email do

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

    describe "raw_email has a malformed header" do
      it "raises an error when the body is not preceded by a double newline" do
        raw_email = "From: \"Cliff Clavin\"<cliff@cheers.com>\r\n\r\nTo: \"Randall Flagg\" <walkindude@lasvegas.com>\r\n\r\nSubject: What! What!\r\nMade it!!!!\r\n\r\nYay!"
        proc { Email.new(raw_email: raw_email).remove_double_new_lines_between_headers }.must_raise StandardError, "Malformed header"
      end

      it "raises an error when the first header is not valid" do
        raw_email = "Fromm: \"Cliff Clavin\"<cliff@cheers.com>\r\n\r\nTo: \"Randall Flagg\" <walkindude@lasvegas.com>\r\n\r\nSubject: What! What!\r\n\r\nMade it!!!!\r\n\r\nYay!"
        proc { Email.new(raw_email: raw_email).remove_double_new_lines_between_headers }.must_raise StandardError, "Malformed header"
      end

      it "raises an error when a header other than the first is not valid" do
        raw_email = "From: \"Cliff Clavin\"<cliff@cheers.com>\r\nTp: \"Randall Flagg\" <walkindude@lasvegas.com>\r\nSubject: What! What!\r\n\r\nMade it!!!!\r\n\r\nYay!"
        proc { email = Email.new(raw_email: raw_email).remove_double_new_lines_between_headers }.must_raise StandardError, "Malformed header"
      end

      it "breaks out of the header early when double newlines follow incorrect header" do
        raw_email = "From: \"Cliff Clavin\"<cliff@cheers.com>\r\n\r\nTo: \"Randall Flagg\" <walkindude@lasvegas.com>\r\n\r\nSubjokt: What! What!\r\n\r\nMade it!!!!\r\n\r\nYay!"
        email = Email.new(raw_email: raw_email).remove_double_new_lines_between_headers
        expected = "From: \"Cliff Clavin\"<cliff@cheers.com>\r\nTo: \"Randall Flagg\" <walkindude@lasvegas.com>\r\n\r\nSubjokt: What! What!\r\n\r\nMade it!!!!\r\n\r\nYay!"
        assert_equal email, expected
      end
    end

    describe "raw_email contains folded headers" do
      it "replaces double newlines in folded headers with single newlines" do
        raw_email = "Delivered-To: adrian.scott.duane@gmail.com\nReceived: by 10.237.61.142 with SMTP id i14csp775851qtf;\n\n  Sat, 6 May 2017 11:19:14 -0700 (PDT)\n\n X-Received: by 10.98.40.4 with SMTP id o4mr22962811pfo.113.1494094754150;\n\n  Sat, 06 May 2017 11:19:14 -0700 (PDT)\n\nNow we're in the body"
        email = Email.new(raw_email: raw_email).remove_double_new_lines_between_headers
        expected = "Delivered-To: adrian.scott.duane@gmail.com\nReceived: by 10.237.61.142 with SMTP id i14csp775851qtf;\n  Sat, 6 May 2017 11:19:14 -0700 (PDT)\n X-Received: by 10.98.40.4 with SMTP id o4mr22962811pfo.113.1494094754150;\n  Sat, 06 May 2017 11:19:14 -0700 (PDT)\n\nNow we're in the body"
        assert_equal email, expected
      end

      it "replaces CRLF-style double newlines in folded headers" do
        raw_email = "Delivered-To: adrian.scott.duane@gmail.com\nReceived: by 10.237.61.142 with SMTP id i14csp775851qtf;\r\n\r\n  Sat, 6 May 2017 11:19:14 -0700 (PDT)\r\n\r\n X-Received: by 10.98.40.4 with SMTP id o4mr22962811pfo.113.1494094754150;\r\n\r\n  Sat, 06 May 2017 11:19:14 -0700 (PDT)\n\nNow we're in the body"
        email = Email.new(raw_email: raw_email).remove_double_new_lines_between_headers
        expected = "Delivered-To: adrian.scott.duane@gmail.com\nReceived: by 10.237.61.142 with SMTP id i14csp775851qtf;\r\n  Sat, 6 May 2017 11:19:14 -0700 (PDT)\r\n X-Received: by 10.98.40.4 with SMTP id o4mr22962811pfo.113.1494094754150;\r\n  Sat, 06 May 2017 11:19:14 -0700 (PDT)\n\nNow we're in the body"
        assert_equal email, expected
      end

      it "handles folded headers that are folded with tabbed whitespace" do
        raw_email = "Delivered-To: adrian.scott.duane@gmail.com\nReceived: by 10.237.61.142 with SMTP id i14csp775851qtf;\r\n\r\n\tSat, 6 May 2017 11:19:14 -0700 (PDT)\r\n\r\n    X-Received: by 10.98.40.4 with SMTP id o4mr22962811pfo.113.1494094754150;\r\n\r\n   Sat, 06 May 2017 11:19:14 -0700 (PDT)\n\nNow we're in the body"
        email = Email.new(raw_email: raw_email).remove_double_new_lines_between_headers
        expected = "Delivered-To: adrian.scott.duane@gmail.com\nReceived: by 10.237.61.142 with SMTP id i14csp775851qtf;\r\n\tSat, 6 May 2017 11:19:14 -0700 (PDT)\r\n    X-Received: by 10.98.40.4 with SMTP id o4mr22962811pfo.113.1494094754150;\r\n   Sat, 06 May 2017 11:19:14 -0700 (PDT)\n\nNow we're in the body"
        assert_equal email, expected
      end
    end

  end
end
