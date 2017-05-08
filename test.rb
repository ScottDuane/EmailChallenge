require './double-new-line.rb'

raw_email_1 = "From: \"Cliff Clavin\"<cliff@cheers.com>\r\n\r\nTo: \"Randall Flagg\" <walkindude@lasvegas.com>\r\n\r\nSubject: What! What!\r\n\r\nMade it!!!!\r\n\r\nYay!"
email = Email.new(raw_email: raw_email_1)
puts email.remove_double_new_lines_between_headers
