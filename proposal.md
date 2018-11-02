Name: Henry Warren          ID: 44534169

## Proposed Project
My project will be a security application for protecting sensitive files 
through the use of fragmentation and (in practice) distribution of chunks 
of the file. The general idea is that it has two key functions:

    - fragment(password, n)
    - reassemble(dir, password)

Fragment breaks the file into n parts, pads them to be equal size, 
encrypts each, generates an integrity check (an HMAC, in this case), 
serializes it with something like JSON, and writes it to disk.

Reassembly takes a directory path, finds all fragments in that directory, 
then verifies, decrypts, and reappends them together to produce the 
original file.

Use-case wise, this would be a good tactic for distributing highly sensitive 
information across a number of servers, as to minimize the risk of a file 
being compromised.

This project is based on a write-up I did last year (and previously implemented in 
both Python and Java): http://henrysprojects.net/projects/file-frag-proto.html

## Outline Structure

> Describe how you'll organize your code. What is the process and
> supervision structure? If it uses a framework, how does it fit in. I
> just need to understand the direction you plan to take. Again, three
> or four sentences are probably enough.



> replace all the ">" lines with your content, then push this to
> github and issue a merge request.
