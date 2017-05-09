require 'rspec'
require 'rspec-benchmark'
require './email_helper.rb'
require './double-new-line.rb'

RSpec.describe "Performance testing" do
  include RSpec::Benchmark::Matchers

  it "handles a standard case fast" do
    raw_email = "From: \"Cliff Clavin\"<cliff@cheers.com>\r\n\r\nTo: \"Randall Flagg\" <walkindude@lasvegas.com>\r\n\r\nSubject: What! What!\r\n\r\nMade it!!!!\r\n\r\nYay!"
    email = Email.new(raw_email: raw_email)

    expect { email.remove_double_new_lines_between_headers }.to perform_under(0.01).sec
  end

  it "handles multiple calls fast" do
    raw_email = EmailHelper.new("./test_emails/email_1.txt").raw_email
    email = Email.new(raw_email: raw_email)

    expect { 10000.times do |i|
              email.remove_double_new_lines_between_headers
            end
           }.to perform_under(1).sec
  end

  # big_header_email has a header that is 10x the size of email_1
  it "scales linearly with the size of header" do
    raw_email = EmailHelper.new("./test_emails/big_header_email.txt").raw_email
    big_header_email = Email.new(raw_email: raw_email)

    expect { 10000.times do |i|
                big_header_email.remove_double_new_lines_between_headers
              end
           }.to perform_under(10).sec
  end
end
