# coding: utf-8

require 'rubygems'
require 'spec'
require 'ftpd'

class FTPServer
  def send_data(data)
    sent_data << data
  end

  def sent_data
    @sent_data ||= ''
  end

  def reset_sent!
    @sent_data = ""
  end

  def initialize
    connection_completed
  end

  # fake the socket data the server is running on. Resolves
  # to 127.0.0.1
  def get_sockname
    "\002\000\000\025\177\000\000\001\000\000\000\000\000\000\000\000"
  end

  def close_connection_after_writing
    true
  end
end

class FTPServerInterceptData < FTPServer

  def oobdata
    @oobdata ||= ""
  end

  private

  def send_outofband_data(data)
    oobdata << data
  end
end

class FTPPassiveDataSocket
  class << self
    def start(host, control_server)
      control_server.datasocket = self.new(nil)
      "12345"
    end

    def stop(*args)
      true
    end

    def get_port(*args)
      40000
    end
  end

  def send_data(data)
    sent_data << data
  end

  def sent_data
    @sent_data ||= ''
  end

  def reset_sent!
    @sent_data = ""
  end

  def close_connection_after_writing
    true
  end

end

context FTPServer, "initialisation" do

  before(:each) do
    @c = FTPServer.new(nil)
  end

  specify "should default to a root name_prefix" do
    @c.name_prefix.should eql("/")
  end

  specify "should respond with 220 when connection is opened" do
    @c.sent_data.should match(/220.+/)
  end
end

context FTPServer, "ALLO" do

  specify "should always respond with 202 when called" do
    @c = FTPServer.new(nil)
    @c.reset_sent!
    @c.receive_line("ALLO")
    @c.sent_data.should match(/200.*/)
  end
end

context FTPServer, "CDUP" do
  before(:each) do
    @c = FTPServer.new(nil)
  end

  specify "should respond with 530 if user is not logged in" do
    @c.reset_sent!
    @c.receive_line("CDUP")
    @c.sent_data.should match(/530.*/)
    @c.name_prefix.should eql("/")
  end

  specify "should respond with 250 if called from root" do
    @c.receive_line("USER test")
    @c.receive_line("PASS 1234")
    @c.reset_sent!
    @c.receive_line("CDUP")
    @c.sent_data.should match(/250.+/)
    @c.name_prefix.should eql("/")
  end

  specify "should respond with 250 if called from incoming dir" do
    @c.receive_line("USER test")
    @c.receive_line("PASS 1234")
    @c.receive_line("CWD files")
    @c.reset_sent!
    @c.receive_line("CDUP")
    @c.sent_data.should match(/250.+/)
    @c.name_prefix.should eql("/")
  end

end

context FTPServer, "CWD" do
  before(:each) do
    @c = FTPServer.new(nil)
  end

  specify "should respond with 530 if user is not logged in" do
    @c.reset_sent!
    @c.receive_line("CWD")
    @c.sent_data.should match(/530.*/)
  end

  specify "should respond with 250 if called with '..' from users home" do
    @c.receive_line("USER test")
    @c.receive_line("PASS 1234")
    @c.reset_sent!
    @c.receive_line("CWD ..")
    @c.sent_data.should match(/250.+/)
    @c.name_prefix.should eql("/")
  end

  specify "should respond with 250 if called with '.' from users home" do
    @c.receive_line("USER test")
    @c.receive_line("PASS 1234")
    @c.reset_sent!
    @c.receive_line("CWD .")
    @c.sent_data.should match(/250.+/)
    @c.name_prefix.should eql("/")
  end

  specify "should respond with 250 if called with '/' from users home" do
    @c.receive_line("USER test")
    @c.receive_line("PASS 1234")
    @c.reset_sent!
    @c.receive_line("CWD /")
    @c.sent_data.should match(/250.+/)
    @c.name_prefix.should eql("/")
  end

  specify "should respond with 250 if called with 'files' from users home" do
    @c.receive_line("USER test")
    @c.receive_line("PASS 1234")
    @c.reset_sent!
    @c.receive_line("CWD files")
    @c.sent_data.should match(/250.+/)
    @c.name_prefix.should eql("/files")
  end

  specify "should respond with 250 if called with 'files/' from users home" do
    @c.receive_line("USER test")
    @c.receive_line("PASS 1234")
    @c.reset_sent!
    @c.receive_line("CWD files/")
    @c.sent_data.should match(/250.+/)
    @c.name_prefix.should eql("/files")
  end

  specify "should respond with 250 if called with '/files/' from users home" do
    @c.receive_line("USER test")
    @c.receive_line("PASS 1234")
    @c.reset_sent!
    @c.receive_line("CWD /files/")
    @c.sent_data.should match(/250.+/)
    @c.name_prefix.should eql("/files")
  end

  specify "should respond with 250 if called with '..' from the files dir" do
    @c.receive_line("USER test")
    @c.receive_line("PASS 1234")
    @c.receive_line("CWD files")
    @c.reset_sent!
    @c.receive_line("CWD ..")
    @c.sent_data.should match(/250.+/)
    @c.name_prefix.should eql("/")
  end

  specify "should respond with 250 if called with '/files' from the files dir" do
    @c.receive_line("USER test")
    @c.receive_line("PASS 1234")
    @c.receive_line("CWD files")
    @c.reset_sent!
    @c.receive_line("CWD /files")
    @c.sent_data.should match(/250.+/)
    @c.name_prefix.should eql("/files")
  end

  specify "should respond with 550 if called with unrecognised dir" do
    @c.receive_line("USER test")
    @c.receive_line("PASS 1234")
    @c.reset_sent!
    @c.name_prefix.should eql("/")
    @c.receive_line("CWD test")
    @c.sent_data.should match(/550.+/)
    @c.name_prefix.should eql("/")
  end

end

context FTPServer, "DELE" do
  before(:each) do
    @c = FTPServer.new(nil)
  end
  specify "should always respond with 550 (permission denied) when called" do
    @c.reset_sent!
    @c.receive_line("DELE")
    @c.sent_data.should match(/550.+/)
  end
end

context FTPServer, "HELP" do
  before(:each) do
    @c = FTPServer.new(nil)
  end
  specify "should always respond with 214 when called" do
    @c.reset_sent!
    @c.receive_line("HELP")
    @c.sent_data.should match(/214.+/)
  end
end

context FTPServer, "LIST" do

  before(:each) do
    timestr = Time.now.strftime("%b %d %H:%M")
    @root_array     = [
      "drwxr-xr-x 1 owner group            0 #{timestr} .",
      "drwxr-xr-x 1 owner group            0 #{timestr} ..",
      "drwxr-xr-x 1 owner group            0 #{timestr} files",
      "-rwxr-xr-x 1 owner group           56 #{timestr} one.txt"
    ]
    @files_array =[
      "drwxr-xr-x 1 owner group            0 #{timestr} .",
      "drwxr-xr-x 1 owner group            0 #{timestr} ..",
      "-rwxr-xr-x 1 owner group           40 #{timestr} two.txt"
    ]
    @c = FTPServerInterceptData.new(nil)
  end

  specify "should respond with 530 when called by non-logged in user" do
    @c.reset_sent!
    @c.receive_line("LIST")
    @c.sent_data.should match(/530.+/)
  end

  specify "should respond with 150 ...425  when called with no data socket" do
    @c = FTPServer.new(nil)
    @c.receive_line("USER test")
    @c.receive_line("PASS 1234")
    @c.reset_sent!
    @c.receive_line("LIST")
    @c.sent_data.should match(/150.+425.+/m)
  end

  specify "should respond with 150 ... 226 when called in the root dir with no param" do
    @c.receive_line("USER test")
    @c.receive_line("PASS 1234")
    @c.receive_line("PASV")
    @c.reset_sent!
    @c.receive_line("LIST")
    @c.sent_data.should match(/150.+226.+/m)
    @c.oobdata.split(FTPServer::LBRK).should eql(@root_array)
  end

  specify "should respond with 150 ... 226 when called in the files dir with no param" do
    @c.receive_line("USER test")
    @c.receive_line("PASS 1234")
    @c.receive_line("CWD files")
    @c.receive_line("PASV")
    @c.reset_sent!
    @c.receive_line("LIST")
    @c.sent_data.should match(/150.+226.+/m)
    @c.oobdata.split(FTPServer::LBRK).should eql(@files_array)
  end

  specify "should respond with 150 ... 226 when called in the files dir with wildcard (LIST *.txt)"

  specify "should respond with 150 ... 226 when called in the subdir with .. param" do
    @c.receive_line("USER test")
    @c.receive_line("PASS 1234")
    @c.receive_line("CWD files")
    @c.receive_line("PASV")
    @c.reset_sent!
    @c.receive_line("LIST ..")
    @c.sent_data.should match(/150.+226.+/m)
    @c.oobdata.split(FTPServer::LBRK).should eql(@root_array)
  end

  specify "should respond with 150 ... 226 when called in the subdir with / param" do
    @c.receive_line("USER test")
    @c.receive_line("PASS 1234")
    @c.receive_line("CWD files")
    @c.receive_line("PASV")
    @c.reset_sent!
    @c.receive_line("LIST /")
    @c.sent_data.should match(/150.+226.+/m)
    @c.oobdata.split(FTPServer::LBRK).should eql(@root_array)
  end

  specify "should respond with 150 ... 226 when called in the root with files param" do
    @c.receive_line("USER test")
    @c.receive_line("PASS 1234")
    @c.receive_line("PASV")
    @c.reset_sent!
    @c.receive_line("LIST files")
    @c.sent_data.should match(/150.+226.+/m)
    @c.oobdata.split(FTPServer::LBRK).should eql(@files_array)
  end

  specify "should respond with 150 ... 226 when called in the root with files/ param" do
    @c.receive_line("USER test")
    @c.receive_line("PASS 1234")
    @c.receive_line("PASV")
    @c.reset_sent!
    @c.receive_line("LIST files/")
    @c.sent_data.should match(/150.+226.+/m)
    @c.oobdata.split(FTPServer::LBRK).should eql(@files_array)
  end

end

context FTPServer, "MKD" do
  before(:each) do
    @c = FTPServer.new(nil)
  end
  specify "should always respond with 550 (permission denied) when called" do
    @c.reset_sent!
    @c.receive_line("MKD")
    @c.sent_data.should match(/550.+/)
  end
end

context FTPServer, "MODE" do
  before(:each) do
    @c = FTPServer.new(nil)
  end
  specify "should respond with 553 when called with no param" do
    @c.receive_line("USER test")
    @c.receive_line("PASS 1234")
    @c.reset_sent!
    @c.receive_line("MODE")
    @c.sent_data.should match(/553.+/)
  end

  specify "should always respond with 530 when called by user not logged in" do
    @c.reset_sent!
    @c.receive_line("MODE S")
    @c.sent_data.should match(/530.+/)
  end

  specify "should always respond with 200 when called with S param" do
    @c.receive_line("USER test")
    @c.receive_line("PASS 1234")
    @c.reset_sent!
    @c.receive_line("MODE S")
    @c.sent_data.should match(/200.+/)
  end

  specify "should always respond with 504 when called with non-S param" do
    @c.receive_line("USER test")
    @c.receive_line("PASS 1234")
    @c.reset_sent!
    @c.receive_line("MODE F")
    @c.sent_data.should match(/504.+/)
  end
end

context FTPServer, "NLST" do

  before(:each) do
    timestr = Time.now.strftime("%b %d %H:%M")
    @root_array  = %w{ . .. files one.txt }
    @files_array = %w{ . .. two.txt}
    @c = FTPServerInterceptData.new(nil)
  end

  specify "should respond with 530 when called by non-logged in user" do
    @c.reset_sent!
    @c.receive_line("NLST")
    @c.sent_data.should match(/530.+/)
  end

  specify "should respond with 150 ...425  when called with no data socket" do
    @c = FTPServer.new(nil)
    @c.receive_line("USER test")
    @c.receive_line("PASS 1234")
    @c.reset_sent!
    @c.receive_line("NLST")
    @c.sent_data.should match(/150.+425.+/m)
  end

  specify "should respond with 150 ... 226 when called in the root dir with no param" do
    @c.receive_line("USER test")
    @c.receive_line("PASS 1234")
    @c.receive_line("PASV")
    @c.reset_sent!
    @c.receive_line("NLST")
    @c.sent_data.should match(/150.+226.+/m)
    @c.oobdata.split(FTPServer::LBRK).should eql(@root_array)
  end

  specify "should respond with 150 ... 226 when called in the files dir with no param" do
    @c.receive_line("USER test")
    @c.receive_line("PASS 1234")
    @c.receive_line("CWD files")
    @c.receive_line("PASV")
    @c.reset_sent!
    @c.receive_line("NLST")
    @c.sent_data.should match(/150.+226.+/m)
    @c.oobdata.split(FTPServer::LBRK).should eql(@files_array)
  end

  specify "should respond with 150 ... 226 when called in the files dir with wildcard (LIST *.txt)"

  specify "should respond with 150 ... 226 when called in the subdir with .. param" do
    @c.receive_line("USER test")
    @c.receive_line("PASS 1234")
    @c.receive_line("CWD files")
    @c.receive_line("PASV")
    @c.reset_sent!
    @c.receive_line("NLST ..")
    @c.sent_data.should match(/150.+226.+/m)
    @c.oobdata.split(FTPServer::LBRK).should eql(@root_array)
  end

  specify "should respond with 150 ... 226 when called in the subdir with / param" do
    @c.receive_line("USER test")
    @c.receive_line("PASS 1234")
    @c.receive_line("CWD files")
    @c.receive_line("PASV")
    @c.reset_sent!
    @c.receive_line("NLST /")
    @c.sent_data.should match(/150.+226.+/m)
    @c.oobdata.split(FTPServer::LBRK).should eql(@root_array)
  end

  specify "should respond with 150 ... 226 when called in the root with files param" do
    @c.receive_line("USER test")
    @c.receive_line("PASS 1234")
    @c.receive_line("PASV")
    @c.reset_sent!
    @c.receive_line("NLST files")
    @c.sent_data.should match(/150.+226.+/m)
    @c.oobdata.split(FTPServer::LBRK).should eql(@files_array)
  end

  specify "should respond with 150 ... 226 when called in the root with files/ param" do
    @c.receive_line("USER test")
    @c.receive_line("PASS 1234")
    @c.receive_line("PASV")
    @c.reset_sent!
    @c.receive_line("NLST files/")
    @c.sent_data.should match(/150.+226.+/m)
    @c.oobdata.split(FTPServer::LBRK).should eql(@files_array)
  end

end

context FTPServer, "NOOP" do
  before(:each) do
    @c = FTPServer.new(nil)
  end

  specify "should always respond with 202 when called" do
    @c.reset_sent!
    @c.receive_line("NOOP")
    @c.sent_data.should match(/200.*/)
  end
end

# TODO PASV

context FTPServer, "PWD" do
  before(:each) do
    @c = FTPServer.new(nil)
  end
  
  specify "should always respond with 550 (permission denied) when called by non-logged in user" do
    @c.reset_sent!
    @c.receive_line("PWD")
    @c.sent_data.should match(/530.+/)
  end

  specify "should always respond with 257 \"/\" when called from root dir" do
    @c.receive_line("USER test")
    @c.receive_line("PASS 1234")
    @c.reset_sent!
    @c.receive_line("PWD")
    @c.sent_data.strip.should eql("257 \"/\" is the current directory")
  end

  specify "should always respond with 257 \"/files\" when called from files dir" do
    @c.receive_line("USER test")
    @c.receive_line("PASS 1234")
    @c.receive_line("CWD files")
    @c.reset_sent!
    @c.receive_line("PWD")
    @c.sent_data.strip.should eql("257 \"/files\" is the current directory")
  end
end

context FTPServer, "PASS" do
  before(:each) do
    @c = FTPServer.new(nil)
  end

  specify "should respond with 202 when called by logged in user" do
    @c.receive_line("USER test")
    @c.receive_line("PASS 1234")
    @c.reset_sent!
    @c.receive_line("PASS 1234")
    @c.sent_data.should match(/202.+/)
  end

  specify "should respond with 553 when called with no param" do
    @c.receive_line("USER test")
    @c.reset_sent!
    @c.receive_line("PASS")
    @c.sent_data.should match(/553.+/)
  end

  specify "should respond with 530 when called without first providing a username" do
    @c.reset_sent!
    @c.receive_line("PASS 1234")
    @c.sent_data.should match(/530.+/)
  end

end

context FTPServer, "RETR" do
  before(:each) do
    @c = FTPServer.new(nil)
  end

  specify "should respond with 553 when called with no param" do
    @c.receive_line("USER test")
    @c.receive_line("PASS 1234")
    @c.reset_sent!
    @c.receive_line("RETR")
    @c.sent_data.should match(/553.+/)
  end

  specify "should always respond with 530 when called by user not logged in" do
    @c.reset_sent!
    @c.receive_line("RETR blah.txt")
    @c.sent_data.should match(/530.+/)
  end

  specify "should always respond with 551 when called with an invalid file" do
    @c.receive_line("USER test")
    @c.receive_line("PASS 1234")
    @c.receive_line("PASV")
    @c.reset_sent!
    @c.receive_line("RETR blah.txt")
    @c.sent_data.should match(/551.+/)
  end

  specify "should always respond with 150..226 when called with valid file" do
    @c.receive_line("USER test")
    @c.receive_line("PASS 1234")
    @c.receive_line("PASV")
    @c.reset_sent!
    @c.receive_line("RETR one.txt")
    @c.sent_data.should match(/150.+226.+/m)
  end

  specify "should always respond with 150..226 when called outside files dir with appropriate param" do
    @c.receive_line("USER test")
    @c.receive_line("PASS 1234")
    @c.receive_line("PASV")
    @c.reset_sent!
    @c.receive_line("RETR files/two.txt")
    @c.sent_data.should match(/150.+226.+/m)
  end
end

context FTPServer, "REST" do
  before(:each) do
    @c = FTPServer.new(nil)
  end

  specify "should always respond with 500 when called" do
    @c.reset_sent!
    @c.receive_line("REST")
    @c.sent_data.should match(/500.+/)
  end
end

context FTPServer, "RMD" do
  before(:each) do
    @c = FTPServer.new(nil)
  end

  specify "should always respond with 550 when called" do
    @c.reset_sent!
    @c.receive_line("RMD")
    @c.sent_data.should match(/550.+/)
  end
end

context FTPServer, "RNFR" do
  before(:each) do
    @c = FTPServer.new(nil)
  end

  specify "should always respond with 550 when called" do
    @c.reset_sent!
    @c.receive_line("RNFR")
    @c.sent_data.should match(/550.+/)
  end
end

context FTPServer, "RNTO" do
  before(:each) do
    @c = FTPServer.new(nil)
  end

  specify "should always respond with 550 when called" do
    @c.reset_sent!
    @c.receive_line("RNTO")
    @c.sent_data.should match(/550.+/)
  end
end

context FTPServer, "QUIT" do
  before(:each) do
    @c = FTPServer.new(nil)
  end

  specify "should always respond with 221 when called" do
    @c.reset_sent!
    @c.receive_line("QUIT")
    @c.sent_data.should match(/221.+/)
  end
end


context FTPServer, "SIZE" do

  before(:each) do
    @c = FTPServer.new(nil)
  end

  specify "should always respond with 530 when called by a non logged in user" do
    @c.reset_sent!
    @c.receive_line("SIZE one.txt")
    @c.sent_data.should match(/530.+/)
  end

  specify "should always respond with 553 when called with no param" do
    @c.receive_line("USER test")
    @c.receive_line("PASS 1234")
    @c.reset_sent!
    @c.receive_line("SIZE")
    @c.sent_data.should match(/553.+/)
  end

  specify "should always respond with 450 when called with a directory param" do
    @c.receive_line("USER test")
    @c.receive_line("PASS 1234")
    @c.reset_sent!
    @c.receive_line("SIZE files")
    @c.sent_data.should match(/450.+/)
  end

  specify "should always respond with 450 when called with a non-file param" do
    @c.receive_line("USER test")
    @c.receive_line("PASS 1234")
    @c.reset_sent!
    @c.receive_line("SIZE blah")
    @c.sent_data.should match(/450.+/)
  end

  specify "should always respond with 213 when called with a valid file param" do
    @c.receive_line("USER test")
    @c.receive_line("PASS 1234")
    @c.receive_line("CWD outgoing")
    @c.reset_sent!
    @c.receive_line("SIZE one.txt")
    @c.sent_data.strip.should eql("213 56")
  end

  specify "should always respond with 213 when called with a valid file param" do
    @c.receive_line("USER test")
    @c.receive_line("PASS 1234")
    @c.reset_sent!
    @c.receive_line("SIZE files/two.txt")
    @c.sent_data.strip.should eql("213 40")
  end
end

# TODO STOR

context FTPServer, "STRU" do
  before(:each) do
    @c = FTPServer.new(nil)
  end
  specify "should respond with 553 when called with no param" do
    @c.receive_line("USER test")
    @c.receive_line("PASS 1234")
    @c.reset_sent!
    @c.receive_line("STRU")
    @c.sent_data.should match(/553.+/)
  end

  specify "should always respond with 530 when called by user not logged in" do
    @c.reset_sent!
    @c.receive_line("STRU F")
    @c.sent_data.should match(/530.+/)
  end

  specify "should always respond with 200 when called with F param" do
    @c.receive_line("USER test")
    @c.receive_line("PASS 1234")
    @c.reset_sent!
    @c.receive_line("STRU F")
    @c.sent_data.should match(/200.+/)
  end

  specify "should always respond with 504 when called with non-F param" do
    @c.receive_line("USER test")
    @c.receive_line("PASS 1234")
    @c.reset_sent!
    @c.receive_line("STRU S")
    @c.sent_data.should match(/504.+/)
  end
end

context FTPServer, "SYST" do
  before(:each) do
    @c = FTPServer.new(nil)
  end

  specify "should respond with 530 when called by non-logged in user" do
    @c.reset_sent!
    @c.receive_line("SYST")
    @c.sent_data.should match(/530.+/)
  end

  specify "should respond with 215 when called by a logged in user" do
    @c.receive_line("USER test")
    @c.receive_line("PASS 1234")
    @c.reset_sent!
    @c.receive_line("SYST")
    @c.sent_data.should match(/215.+/)
    @c.sent_data.include?("UNIX").should be_true
    @c.sent_data.include?("L8").should be_true
  end

end

context FTPServer, "TYPE" do
  before(:each) do
    @c = FTPServer.new(nil)
  end

  specify "should respond with 530 when called by non-logged in user" do
    @c.reset_sent!
    @c.receive_line("TYPE A")
    @c.sent_data.should match(/530.+/)
  end

  specify "should respond with 553 when called with no param" do
    @c.receive_line("USER test")
    @c.receive_line("PASS 1234")
    @c.reset_sent!
    @c.receive_line("TYPE")
    @c.sent_data.should match(/553.+/)
  end

  specify "should respond with 200 when with 'A' called by a logged in user" do
    @c.receive_line("USER test")
    @c.receive_line("PASS 1234")
    @c.reset_sent!
    @c.receive_line("TYPE A")
    @c.sent_data.should match(/200.+/)
    @c.sent_data.include?("ASCII").should be_true
  end

  specify "should respond with 200 when with 'I' called by a logged in user" do
    @c.receive_line("USER test")
    @c.receive_line("PASS 1234")
    @c.reset_sent!
    @c.receive_line("TYPE I")
    @c.sent_data.should match(/200.+/)
    @c.sent_data.include?("binary").should be_true
  end

  specify "should respond with 500 when called by a logged in user with un unrecognised param" do
    @c.receive_line("USER test")
    @c.receive_line("PASS 1234")
    @c.reset_sent!
    @c.receive_line("TYPE T")
    @c.sent_data.should match(/500.+/)
  end

end

context FTPServer, "USER" do

  before(:each) do
    @c = FTPServer.new(nil)
  end

  specify "should respond with 331 when called by non-logged in user" do
    @c.reset_sent!
    @c.receive_line("USER jh")
    @c.sent_data.should match(/331.+/)
  end

  specify "should respond with 500 when called by a logged in user" do
    @c.receive_line("USER test")
    @c.receive_line("PASS 1234")
    @c.reset_sent!
    @c.receive_line("USER test")
    @c.sent_data.should match(/500.+/)
  end

end

context FTPServer, "XCUP" do
  before(:each) do
    @c = FTPServer.new(nil)
  end

  specify "should respond with 530 if user is not logged in" do
    @c.reset_sent!
    @c.receive_line("XCUP")
    @c.sent_data.should match(/530.*/)
  end

  specify "should respond with 250 if called from users home" do
    @c.receive_line("USER test")
    @c.receive_line("PASS 1234")
    @c.reset_sent!
    @c.receive_line("XCUP")
    @c.sent_data.should match(/250.+/)
    @c.name_prefix.should eql("/")
  end

  specify "should respond with 250 if called from files dir" do
    @c.receive_line("USER test")
    @c.receive_line("PASS 1234")
    @c.receive_line("CWD files")
    @c.reset_sent!
    @c.receive_line("XCUP")
    @c.sent_data.should match(/250.+/)
    @c.name_prefix.should eql("/")
  end
end

context FTPServer, "XPWD" do
  before(:each) do
    @c = FTPServer.new(nil)
  end

  specify "should always respond with 550 (permission denied) when called by non-logged in user" do
    @c.reset_sent!
    @c.receive_line("XPWD")
    @c.sent_data.should match(/530.+/)
  end

  specify "should always respond with 257 \"/\" when called from root dir" do
    @c.receive_line("USER test")
    @c.receive_line("PASS 1234")
    @c.reset_sent!
    @c.receive_line("XPWD")
    @c.sent_data.strip.should eql("257 \"/\" is the current directory")
  end

  specify "should always respond with 257 \"/files\" when called from incoming dir" do
    @c.receive_line("USER test")
    @c.receive_line("PASS 1234")
    @c.receive_line("CWD files")
    @c.reset_sent!
    @c.receive_line("XPWD")
    @c.sent_data.strip.should eql("257 \"/files\" is the current directory")
  end
end

context FTPServer, "XRMD" do
  before(:each) do
    @c = FTPServer.new(nil)
  end

  specify "should always respond with 550 when called" do
    @c.reset_sent!
    @c.receive_line("XRMD")
    @c.sent_data.should match(/550.+/)
  end
end
