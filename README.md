Initial Thoughts:

- It's essential to process the smallest amount of an email possible to save on processing time
- Emails can come in many different formats -- find a list of those formats and figure out a parsing method for each
- Limit scope to a few common formats
- The first three headers are strings without any special characters -- what's a reasonable assumption for what that list could include?
- How can double new lines occur within a string? Certainly \n\n, but what else?
- How should lookup of a header occur? A Trie comes to mind as a good data structure to use
- Read and review these specifications a couple times: https://www.ietf.org/rfc/rfc5322.txt
- Use their sample emails to create test cases 
