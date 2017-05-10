require 'rspec'
require 'rspec-benchmark'
require './double-new-line.rb'
require './test_emails/trulia_email.rb'

RSpec.describe "Performance testing" do
  include RSpec::Benchmark::Matchers

  trulia_raw_email = TRULIA_HEADER + TRULIA_BODY
  raw_header = TRULIA_HEADER
  small_raw_email = "From: \"Cliff Clavin\"<cliff@cheers.com>\r\n\r\nTo: \"Randall Flagg\" <walkindude@lasvegas.com>\r\n\r\nSubject: What! What!\r\n\r\nMade it!!!!\r\n\r\nYay!"

  big_header_raw_email = ""
  10.times do |i|
    big_header_raw_email += TRULIA_HEADER
  end

  big_header_raw_email += TRULIA_BODY

  it "handles a small case in under 10 milliseconds" do
    email = Email.new(raw_email: small_raw_email)
    expect { email.remove_double_new_lines_between_headers }.to perform_under(0.01).sec
  end

  it "handles multiple calls in a reasonable time" do
    email = Email.new(raw_email: trulia_raw_email)

    expect { 100.times do |i|
              email.remove_double_new_lines_between_headers
            end
           }.to perform_under(1).sec
  end

  it "is scalable with the size of header" do
    big_header_email = Email.new(raw_email: big_header_raw_email)

    expect { 100.times do |i|
                big_header_email.remove_double_new_lines_between_headers
              end
           }.to perform_under(10).sec
  end

  it "runs as fast as another linear algorithm" do
    big_header_email = Email.new(raw_email: big_header_raw_email)
    email = Email.new(raw_email: trulia_raw_email)

    expect { email.remove_double_new_lines_between_headers }.to perform_faster_than { 5.times do
                                                                                        split_email = raw_header.split("")
                                                                                      end }
    expect { big_header_email.remove_double_new_lines_between_headers }.to perform_faster_than { 50.times do
                                                                                        split_email = raw_header.split("")
                                                                                      end }
  end

end
