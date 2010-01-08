## ftpd.rb

A demo FTP server, built on top of the EventMacine gem. For a few years I've run
a low traffic server based on Chris Wanstrath's ftpd.rb. Recently I ported it
to run on EventMachine, a rewrite that significantly simplified the code.

The FTP protocol requires multiple sockets to be opened between the client and server.
One for the control data, and one for each data transfer. The major challenge
I found while attempting the rewrite was a lack of EventMachine sample code
that demonstrated opening multiple, related concurrent sockets. It turned out
to be a solvable challenge, and I've released this stripped down demo as
an example for others.

This isn't a useful FTP server. It has hard coded authentication and an
emulated directory structure. I hope it serves as a useful piece of sample code
regardless.

# Author

James Healy <james@yob.id.au>
[http://www.yob.id.au](http://www.yob.id.au)

## License

This library is distributed under the terms of the MIT License. See the included file for
more detail.

## Contributing

All suggestions and patches welcome, preferably via a git repository I can pull from.
If this demo proves useful to you, please let me know.

## Usage

As root (so you can bind to a port < 1024):

    ruby ftpd.rb [uid] [gid]

## Authentication Details

The login details are hard coded. Username: test Password: 1234

## Further Reading

There are a range of RFCs that together specify the FTP protocol. In chronological
order, the more useful ones are:

- [http://tools.ietf.org/rfc/rfc959.txt](http://tools.ietf.org/rfc/rfc959.txt)
- [http://tools.ietf.org/rfc/rfc1123.txt](http://tools.ietf.org/rfc/rfc1123.txt)
- [http://tools.ietf.org/rfc/rfc2228.txt](http://tools.ietf.org/rfc/rfc2228.txt)
- [http://tools.ietf.org/rfc/rfc2389.txt](http://tools.ietf.org/rfc/rfc2389.txt)
- [http://tools.ietf.org/rfc/rfc2428.txt](http://tools.ietf.org/rfc/rfc2428.txt)
- [http://tools.ietf.org/rfc/rfc3659.txt](http://tools.ietf.org/rfc/rfc3659.txt)
- [http://tools.ietf.org/rfc/rfc4217.txt](http://tools.ietf.org/rfc/rfc4217.txt)

For an english summary that's somewhat more legible than the RFCs, and provides
some commentary on what features are actually useful or relevant 24 years after
RFC959 was published:

- [http://cr.yp.to/ftp.html](http://cr.yp.to/ftp.html)

For a history lesson, check out Appendix III of RCF959. It lists the preceding
(obsolete) RFC documents that relate to file transfers, including the ye old
RFC114 from 1971, "A File Transfer Protocol"

For more information on EventMacine, a library that (among other things) simplifies
writing applications that use sockets, check out their website.

- [http://rubyeventmachine.com/](http://rubyeventmachine.com/)
