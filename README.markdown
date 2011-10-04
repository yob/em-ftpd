## em-ftpd

A mini-FTP server framework built on top of the EventMacine gem. By providing a
simple driver class that responds to a handful of methods you can have a
complete FTP server.

The library is extracted from real world situations where an FTP interface was
required to sit in front of a non-filesystem persistence layer.

Some sample use cases include persisting data to:

* an Amazon S3 bucket
* a relational database
* redis
* memory

For some examples that demonstrate redis and memory persistence, check the
examples/ directory.

# Authors

Chris Wanstrath <chris@wanstrath.com>
James Healy <james@yob.id.au> [http://www.yob.id.au](http://www.yob.id.au)
John Nunemaker <nunemaker@gmail.com>
Elijah Miller <elijah.miller@gmail.com>

## Warning

FTP is an incredibly insecure protocol. Be careful about forcing users to authenticate
with a username or password that are important.

## License

This library is distributed under the terms of the MIT License. See the included file for
more detail.

## Contributing

All suggestions and patches welcome, preferably via a git repository I can pull from.
If this library proves useful to you, please let me know.

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
