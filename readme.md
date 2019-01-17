# EDNS Flagday Bulk Tester!

Sorry, this is a bit rubbish but I just wanted to hack something together.

## Requirements
You'll need to have memcached running locally and ensure infile.csv has a column
called "domain". You'll also need a working ruby & bundler, and to bundle this
project. Lastly, you'll need to have DiG version 9.11 or 9.12.

On MacOS this can be installed using the homebrew `bind` package.

Also, this will hit your DNS server fairly hard (though only once per nameserver)

## Usage
Fill in the domains to be tested into infile.csv, then run `ruby test.rb`. The
script will run as quickly as it can, and upon completion you'll have an outfile.csv
that contains a row for each domain & nameserver IP.

## Results
The resulting CSV will have the following columns:

|Column|Meaning|
|------|-------|
|domain|Domain name tested|
|server_name|Reverse DNS of Server tested|
|server|IP of Server Tested|
|soa|Server correctly configured for domain (no EDNS)|
|edns|Server correctly configured for EDNS|
|do|Server correctly configured for DNSSEC|
|edns1|Server rejects EDNSv1|
|optlist|Server survives common EDNS Options|

## License
Copyright 2019 Alex Conner

Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

1. Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.

2. Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
