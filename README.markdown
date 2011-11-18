# em-ftpd

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

## Usage

To boot an FTP server you will need to provide a driver that speaks to your
persistence layer.

Create a config.rb file that loads the driver and then configures the server

    require 'my_fancy_driver'

    driver    MyFancyDriver
    user      'ftp'
    group     'ftp'

Run your server like so:

    em-ftpd config.rb

## Config File

Valid options for the config file are:

* user        [name of system user to run the process as]
* group       [name of group to run the process as]
* daemonise   [true/false]
* name        [a string to include in the process description]
* pid_file    [a path to save the pid to. Useful in conjunction with daemonise]
* port        [the TCP port to bind to. Defaults to 21]
* driver      [the class that connects to the persistance layer]
* driver_args [any arguments that need to be passed to the driver constructor]

## The Driver Contract

The driver MUST have the following methods. Each method MUST accept a block and
yield the appropriate value:

    authenticate(user, pass, &block)
    - boolean indicating if the provided details are valid

    bytes(path, &block)
    - an integer with the number of bytes in the file or nil if the file
      doesn't exist

    change_dir(path, &block)
    - a boolen indicating if the current user is permitted to change to the
      requested path

    dir_contents(path, &block)
    - an array of the contents of the requested path or nil if the dir
      doesn't exist. Each entry in the array should be
      EM::FTPD::DirectoryItem-ish

    delete_dir(path, &block)
    - a boolean indicating if the directory was successfully deleted

    delete_file(path, &block)
    - a boolean indicating if path was successfully deleted

    rename(from_path, to_path, &block)
    - a boolean indicating if from_path was successfully renamed to to_path

    make_dir(path, &block)
    - a boolean indicating if path was successfully created as a new directory

    get_file(path, &block)
    - nil if the user isn't permitted to access that path
    - an IOish (File, StringIO, IO, etc) object with data to send back to the
      client
    - a string with the file data to send to the client
    - an array of strings to join with the standard FTP line break and send to
      the client

The driver MUST have one of the following methods. Each method MUST accept a
block and yield the appropriate value:

    put_file(path, tmp_file_path, &block)
    - an integer indicating the number of bytes received or False if there
      was an error

    put_file_streamed(path, datasocket, &block)
    - an integer indicating the number of bytes received or False if there
      was an error

## Authors

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
