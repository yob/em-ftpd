# coding: utf-8

# a super simple FTP server with hard coded auth details and only two files
# available for download.
#
# Usage:
#
#   ruby -Ilib examples/fake.rb

require 'rubygems'
require 'bundler'

Bundler.setup

require 'ftpd'

class FakeFTPServer < FTPServer
  FILE_ONE = "This is the first file available for download.\n\nBy James"
  FILE_TWO = "This is the file number two.\n\n2009-03-21"

  def change_dir(path)
    path == "/" || path == "/files"
  end

  def dir_contents(path)
    case path
    when "/"      then
      [
        DirectoryItem.new(:name => "files", :directory => true, :size => 0),
        DirectoryItem.new(:name => "one.txt", :directory => false, :size => FILE_ONE.bytesize)
      ]
    when "/files" then
      [
        DirectoryItem.new(:name => "two.txt", :directory => false, :size => FILE_TWO.bytesize)
      ]
    else
      []
    end
  end

  def authenticate(user, pass)
    user == "test" && pass == "1234"
  end

  def get_file(path)
    case path
    when "/one.txt"       then FILE_ONE
    when "/files/two.txt" then FILE_TWO
    else
      false
    end
  end

  def can_put_file(path)
    false
  end

  def put_file(path, data)
    false
  end

  def delete_file(path)
    false
  end

  def delete_dir(path)
    false
  end

  def move_file(from, to)
    false
  end

  def move_dir(from, to)
    false
  end

  def rename(from, to)
    false
  end

  def make_dir(path)
    false
  end

end

# signal handling, ensure we exit gracefully
trap "SIGCLD", "IGNORE"
trap "INT" do
  puts "exiting..."
  puts
  EventMachine::run
  exit
end

EM.run do
  puts "Starting ftp server on 0.0.0.0:5555"
  EventMachine::start_server("0.0.0.0", 5555, FakeFTPServer)
end
