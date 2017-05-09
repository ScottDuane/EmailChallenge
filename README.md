# Email Challenge

The goal of this project is to create a Ruby function that takes in an email in its raw form and removes double newlines.

### Background & Design Considerations

Newlines occur in emails as either a standard newline character `\n` or as the carriage return line feed (CRLF, `\r\n`). By the <a href="https://www.ietf.org/rfc/rfc5322.txt">IETF Standards</a>, an email header can be distinguished from an email body by the occurrence of a "double newline", either `\n\n` or `\r\n\r\n`. For that reason, a header that contains double newlines outside of the header/body separation can cause troubles.

One other complicating factor is that an email header can contain "folding headers", which are long header values that wrap to the next line. Folding headers are typically formatted with a newline, followed by whitespace, followed by the rest of the header value, looking something like this:

```ruby
Received: from mta1a4.update.trulia.com (mta1a4.update.trulia.com. [52.37.207.246])
        by mx.google.com with ESMTPS id r123si3746015pgr.62.2017.05.06.11.19.13
        for <adrian.scott.duane@gmail.com>
        (version=TLS1_2 cipher=ECDHE-RSA-AES128-GCM-SHA256 bits=128/128);
        Sat, 06 May 2017 11:19:14 -0700 (PDT)
```

The trickiest case of the double newline problem occurs because of folding headers -- if a folding header itself contains a double newline, we must make a reasonable determination as to whether we are still within the header, or whether we've progressed to the body of the email.

### Approach

Since emails can become large quickly and the header is typically a small portion of the entire raw email, our goal will be to make one pass through the header only. We'll build the parsed header as we go, and then concatenate that parsed header with the email body after parsing is complete. We'll use the following approach:

1. At the beginning of a line, determine if the string before the first `:` is a valid header.
  * If yes, move the pointer index to the space after the colon.
  * If no, we've reached the email body, so we break and concatenate (or throw an error if we're at the very start of `@raw_email`).
2. After our pointer moves to the right of the colon, we parse the value of this header character by character.
  * If a character does not belong to a newline block (e.g., not `\n\n`, `\n`, `\r\n\r\n` or `\r\n`), we concatenate it to a running string of header value characters and move on.
  * If the character belongs to a newline or double newline block, we test if the next line begins with whitespace. If so, we return the index of the new line as well as a substring of `@raw_email` that should be concatenated onto the full header. We then move our pointer index to the beginning of the new line and repeat Step 1.
3. If an invalid header is preceded by a single newline, we throw an error as the email is malformed.

### Time Complexity

Because we make a single pass through the characters of the header, this method runs in `O(number of characters in header)` in almost all cases, which is the best we can hope for. There are a few edge cases that will result in a runtime on the order of `O(length of raw_email)` -- in particular, our worst case scenario is if the entire email consisted of valid headers followed by colons on new lines. This seems unlikely in practice, and is thus probably worth the tradeoff.

Space complexity is also on the order of `O(number of characters in header)` with a similar worst case performance because of the substrings that are created when we make our new header. However, in practice, all of these substrings will get garbage collected after an email is processed, so again they're probably worth the tradeoff.

### Testing

In addition to the tests for a number of cases included in `double-new-line.rb`, there's also a performance spec that you can run with `rspec`. This tests the runtime and scaling power of this method, with some emails that are the size of a typical email we might see in production (the samples are taken from a couple of my own email inboxes).
