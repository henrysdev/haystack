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

I plan to organize my code as follows:
lib/
    file_shredder/
        fragmentor
        reassembler
    utils/
        crypto
        file
        parallel
    file_shredder (API)

I am not using a framework. The only external dependency that I will 
have is the Poison library for JSON (subject to change). I plan for 
this project to take shape as a light-weight CLI application with just 
2-3 commands (fragment, reassemble, help, etc).