# coding: utf-8

require 'spec_helper'

describe EM::FTPD::Server, "initialisation" do

  before(:each) do
    @c = EM::FTPD::Server.new(nil, TestDriver.new)
  end

  it "should default to a root name_prefix" do
    expect(@c.name_prefix).to eql("/")
  end

  it "should respond with 220 when connection is opened" do
    expect(@c.sent_data).to match(/^220/)
  end
end

describe EM::FTPD::Server, "ALLO" do

  it "should always respond with 202 when called" do
    @c = EM::FTPD::Server.new(nil, TestDriver.new)
    @c.reset_sent!
    @c.receive_line("ALLO")
    expect(@c.sent_data).to match(/^202/)
  end
end

describe EM::FTPD::Server, "USER" do

  before(:each) do
    @c = EM::FTPD::Server.new(nil,TestDriver.new)
  end

  it "should respond with 331 when called by non-logged in user" do
    @c.reset_sent!
    @c.receive_line("USER jh")
    expect(@c.sent_data).to match(/331.+/)
  end

  it "should respond with 500 when called by a logged in user" do
    @c.receive_line("USER test")
    @c.receive_line("PASS 1234")
    @c.reset_sent!
    @c.receive_line("USER test")
    expect(@c.sent_data).to match(/500.+/)
  end

end

describe EM::FTPD::Server, "PASS" do
  before(:each) do
    @c = EM::FTPD::Server.new(nil, TestDriver.new)
  end

  it "should respond with 202 when called by logged in user" do
    @c.receive_line("USER test")
    @c.receive_line("PASS 1234")
    @c.reset_sent!
    @c.receive_line("PASS 1234")
    expect(@c.sent_data).to match(/202.+/)
  end

  it "should respond with 553 when called with no param" do
    @c.receive_line("USER test")
    @c.reset_sent!
    @c.receive_line("PASS")
    expect(@c.sent_data).to match(/553.+/)
  end

  it "should respond with 530 when called without first providing a username" do
    @c.reset_sent!
    @c.receive_line("PASS 1234")
    expect(@c.sent_data).to match(/530.+/)
  end

  it "should respond with 230 when user is authenticated" do
    @c.receive_line("USER test")
    @c.reset_sent!
    @c.receive_line("PASS 1234")
    expect(@c.sent_data).to match(/230.+/)
  end

  it "should respond with 530 when password is incorrect" do
    @c.receive_line("USER test")
    @c.reset_sent!
    @c.receive_line("PASS 1235")
    expect(@c.sent_data).to match(/530.+/)
  end
end

%w(CDUP XCUP).each do |command|

  describe EM::FTPD::Server, command do
    before(:each) do
      @c = EM::FTPD::Server.new(nil, TestDriver.new)
    end

    it "should respond with 530 if user is not logged in" do
      @c.reset_sent!
      @c.receive_line(command)
      expect(@c.sent_data).to match(/530.*/)
      expect(@c.name_prefix).to eql("/")
    end

    it "should respond with 250 if called from root" do
      @c.receive_line("USER test")
      @c.receive_line("PASS 1234")
      @c.reset_sent!
      @c.receive_line(command)
      expect(@c.sent_data).to match(/250.+/)
      expect(@c.name_prefix).to eql("/")
    end

    it "should respond with 250 if called from incoming dir" do
      @c.receive_line("USER test")
      @c.receive_line("PASS 1234")
      @c.receive_line("CWD files")
      @c.reset_sent!
      @c.receive_line(command)
      expect(@c.sent_data).to match(/250.+/)
      expect(@c.name_prefix).to eql("/")
    end
  end
end

describe EM::FTPD::Server, "CWD" do
  before(:each) do
    @c = EM::FTPD::Server.new(nil, TestDriver.new)
  end

  it "should respond with 530 if user is not logged in" do
    @c.reset_sent!
    @c.receive_line("CWD")
    expect(@c.sent_data).to match(/530.*/)
  end

  it "should respond with 250 if called with '..' from users home" do
    @c.receive_line("USER test")
    @c.receive_line("PASS 1234")
    @c.reset_sent!
    @c.receive_line("CWD ..")
    expect(@c.sent_data).to match(/250.+/)
    expect(@c.name_prefix).to eql("/")
  end

  it "should respond with 250 if called with '.' from users home" do
    @c.receive_line("USER test")
    @c.receive_line("PASS 1234")
    @c.reset_sent!
    @c.receive_line("CWD .")
    expect(@c.sent_data).to match(/250.+/)
    expect(@c.name_prefix).to eql("/")
  end

  it "should respond with 250 if called with '/' from users home" do
    @c.receive_line("USER test")
    @c.receive_line("PASS 1234")
    @c.reset_sent!
    @c.receive_line("CWD /")
    expect(@c.sent_data).to match(/250.+/)
    expect(@c.name_prefix).to eql("/")
  end

  it "should respond with 250 if called with 'files' from users home" do
    @c.receive_line("USER test")
    @c.receive_line("PASS 1234")
    @c.reset_sent!
    @c.receive_line("CWD files")
    expect(@c.sent_data).to match(/250.+/)
    expect(@c.name_prefix).to eql("/files")
  end

  it "should respond with 250 if called with 'files/' from users home" do
    @c.receive_line("USER test")
    @c.receive_line("PASS 1234")
    @c.reset_sent!
    @c.receive_line("CWD files/")
    expect(@c.sent_data).to match(/250.+/)
    expect(@c.name_prefix).to eql("/files")
  end

  it "should respond with 250 if called with '/files/' from users home" do
    @c.receive_line("USER test")
    @c.receive_line("PASS 1234")
    @c.reset_sent!
    @c.receive_line("CWD /files/")
    expect(@c.sent_data).to match(/250.+/)
    expect(@c.name_prefix).to eql("/files")
  end

  it "should respond with 250 if called with '..' from the files dir" do
    @c.receive_line("USER test")
    @c.receive_line("PASS 1234")
    @c.receive_line("CWD files")
    @c.reset_sent!
    @c.receive_line("CWD ..")
    expect(@c.sent_data).to match(/250.+/)
    expect(@c.name_prefix).to eql("/")
  end

  it "should respond with 250 if called with '/files' from the files dir" do
    @c.receive_line("USER test")
    @c.receive_line("PASS 1234")
    @c.receive_line("CWD files")
    @c.reset_sent!
    @c.receive_line("CWD /files")
    expect(@c.sent_data).to match(/250.+/)
    expect(@c.name_prefix).to eql("/files")
  end

  it "should respond with 550 if called with unrecognised dir" do
    @c.receive_line("USER test")
    @c.receive_line("PASS 1234")
    @c.reset_sent!
    expect(@c.name_prefix).to eql("/")
    @c.receive_line("CWD test")
    expect(@c.sent_data).to match(/550.+/)
    expect(@c.name_prefix).to eql("/")
  end

end

describe EM::FTPD::Server, "DELE" do
  before(:each) do
    @c = EM::FTPD::Server.new(nil, TestDriver.new)
  end

  it "should respond with 530 if user is not logged in" do
    @c.reset_sent!
    @c.receive_line("DELE x")
    expect(@c.sent_data).to match(/530.*/)
  end

  it "should respond with 553 when the paramater is omitted" do
    @c.receive_line("USER test")
    @c.receive_line("PASS 1234")
    @c.reset_sent!
    @c.reset_sent!
    @c.receive_line("DELE")
    expect(@c.sent_data).to match(/553.+/)
  end

  it "should respond with 250 when the file is deleted" do
    @c.receive_line("USER test")
    @c.receive_line("PASS 1234")
    @c.reset_sent!
    @c.reset_sent!
    @c.receive_line("DELE four.txt")
    expect(@c.sent_data).to match(/250.+/)
  end

  it "should respond with 550 when the file is not deleted" do
    @c.receive_line("USER test")
    @c.receive_line("PASS 1234")
    @c.reset_sent!
    @c.reset_sent!
    @c.receive_line("DELE one.txt")
    expect(@c.sent_data).to match(/550.+/)
  end

end

describe EM::FTPD::Server, "HELP" do
  before(:each) do
    @c = EM::FTPD::Server.new(nil, TestDriver.new)
  end
  it "should always respond with 214 when called" do
    @c.reset_sent!
    @c.receive_line("HELP")
    expect(@c.sent_data).to match(/214.+/)
  end
end

describe EM::FTPD::Server, "LIST" do
  # TODO: nlist

  before(:each) do
    @c = EM::FTPD::Server.new(nil, TestDriver.new)
  end
  let!(:root_files) {
    timestr = Time.now.strftime("%b %d %H:%M")
    [
      "drwxr-xr-x 1 owner  group            0 #{timestr} .",
      "drwxr-xr-x 1 owner  group            0 #{timestr} ..",
      "drwxr-xr-x 1 owner  group            0 #{timestr} files",
      "-rwxr-xr-x 1 owner  group           56 #{timestr} one.txt"
    ]
  }
  let!(:dir_files) {
    timestr = Time.now.strftime("%b %d %H:%M")
    [
      "drwxr-xr-x 1 owner  group            0 #{timestr} .",
      "drwxr-xr-x 1 owner  group            0 #{timestr} ..",
      "-rwxr-xr-x 1 owner  group           40 #{timestr} two.txt"
    ]
  }

  it "should respond with 530 when called by non-logged in user" do
    @c.reset_sent!
    @c.receive_line("LIST")
    expect(@c.sent_data).to match(/530.+/)
  end

  it "should respond with 150 ...425  when called with no data socket" do
    @c.receive_line("USER test")
    @c.receive_line("PASS 1234")
    @c.reset_sent!
    @c.receive_line("LIST")
    expect(@c.sent_data).to match(/150.+425.+/m)
  end

  it "should respond with 150 ... 226 when called in the root dir with no param" do
    @c.receive_line("USER test")
    @c.receive_line("PASS 1234")
    @c.receive_line("PASV")
    @c.reset_sent!
    @c.receive_line("LIST")
    expect(@c.sent_data).to match(/150.+226.+/m)
    expect(@c.oobdata.split(EM::FTPD::Server::LBRK)).to eql(root_files)
  end

  it "should respond with 150 ... 226 when called in the files dir with no param" do
    @c.receive_line("USER test")
    @c.receive_line("PASS 1234")
    @c.receive_line("CWD files")
    @c.receive_line("PASV")
    @c.reset_sent!
    @c.receive_line("LIST")
    expect(@c.sent_data).to match(/150.+226.+/m)
    expect(@c.oobdata.split(EM::FTPD::Server::LBRK)).to eql(dir_files)
  end

  it "should respond with 150 ... 226 when called in the files dir with wildcard (LIST *.txt)"

  it "should respond with 150 ... 226 when called in the subdir with .. param" do
    @c.receive_line("USER test")
    @c.receive_line("PASS 1234")
    @c.receive_line("CWD files")
    @c.receive_line("PASV")
    @c.reset_sent!
    @c.receive_line("LIST ..")
    expect(@c.sent_data).to match(/150.+226.+/m)
    expect(@c.oobdata.split(EM::FTPD::Server::LBRK)).to eql(root_files)
  end

  it "should respond with 150 ... 226 when called in the subdir with / param" do
    @c.receive_line("USER test")
    @c.receive_line("PASS 1234")
    @c.receive_line("CWD files")
    @c.receive_line("PASV")
    @c.reset_sent!
    @c.receive_line("LIST /")
    expect(@c.sent_data).to match(/150.+226.+/m)
    expect(@c.oobdata.split(EM::FTPD::Server::LBRK)).to eql(root_files)
  end

  it "should respond with 150 ... 226 when called in the root with files param" do
    @c.receive_line("USER test")
    @c.receive_line("PASS 1234")
    @c.receive_line("PASV")
    @c.reset_sent!
    @c.receive_line("LIST files")
    expect(@c.sent_data).to match(/150.+226.+/m)
    expect(@c.oobdata.split(EM::FTPD::Server::LBRK)).to eql(dir_files)
  end

  it "should respond with 150 ... 226 when called in the root with files/ param" do
    @c.receive_line("USER test")
    @c.receive_line("PASS 1234")
    @c.receive_line("PASV")
    @c.reset_sent!
    @c.receive_line("LIST files/")
    expect(@c.sent_data).to match(/150.+226.+/m)
    expect(@c.oobdata.split(EM::FTPD::Server::LBRK)).to eql(dir_files)
  end

  it "should properly list subdirs etc."

end

describe EM::FTPD::Server, "MKD" do
  before(:each) do
    @c = EM::FTPD::Server.new(nil, TestDriver.new)
  end

  it "should respond with 530 if user is not logged in" do
    @c.reset_sent!
    @c.receive_line("MKD x")
    expect(@c.sent_data).to match(/530.*/)
  end

  it "should respond with 553 when the paramater is omitted" do
    @c.receive_line("USER test")
    @c.receive_line("PASS 1234")
    @c.reset_sent!
    @c.receive_line("MKD")
    expect(@c.sent_data).to match(/553.+/)
  end

  it "should respond with 257 when the directory is created" do
    @c.receive_line("USER test")
    @c.receive_line("PASS 1234")
    @c.reset_sent!
    @c.receive_line("MKD four")
    expect(@c.sent_data).to match(/257.+/)
  end


  it "should respond with 550 when the directory is not created" do
    @c.receive_line("USER test")
    @c.receive_line("PASS 1234")
    @c.reset_sent!
    @c.receive_line("MKD five")
    expect(@c.sent_data).to match(/550.+/)
  end

end

describe EM::FTPD::Server, "MODE" do
  before(:each) do
    @c = EM::FTPD::Server.new(nil, TestDriver.new)
  end

  it "should respond with 553 when called with no param" do
    @c.receive_line("USER test")
    @c.receive_line("PASS 1234")
    @c.reset_sent!
    @c.receive_line("MODE")
    expect(@c.sent_data).to match(/553.+/)
  end

  it "should always respond with 530 when called by user not logged in" do
    @c.reset_sent!
    @c.receive_line("MODE S")
    expect(@c.sent_data).to match(/530.+/)
  end

  it "should always respond with 200 when called with S param" do
    @c.receive_line("USER test")
    @c.receive_line("PASS 1234")
    @c.reset_sent!
    @c.receive_line("MODE S")
    expect(@c.sent_data).to match(/200.+/)
  end

  it "should always respond with 504 when called with non-S param" do
    @c.receive_line("USER test")
    @c.receive_line("PASS 1234")
    @c.reset_sent!
    @c.receive_line("MODE F")
    expect(@c.sent_data).to match(/504.+/)
  end
end

describe EM::FTPD::Server, "NOOP" do
  before(:each) do
    @c = EM::FTPD::Server.new(nil, TestDriver.new)
  end

  it "should always respond with 202 when called" do
    @c.reset_sent!
    @c.receive_line("NOOP")
    expect(@c.sent_data).to match(/200.*/)
  end
end

# TODO PASV

%w(PWD XPWD).each do |command|
  describe EM::FTPD::Server, command do
    before(:each) do
      @c = EM::FTPD::Server.new(nil, TestDriver.new)
    end

    it "should always respond with 550 (permission denied) when called by non-logged in user" do
      @c.reset_sent!
      @c.receive_line(command)
      expect(@c.sent_data).to match(/530.+/)
    end

    it 'should always respond with 257 "/" when called from root dir' do
      @c.receive_line("USER test")
      @c.receive_line("PASS 1234")
      @c.reset_sent!
      @c.receive_line(command)
      expect(@c.sent_data.strip).to eql('257 "/" is the current directory')
    end

    it 'should always respond with 257 "/files" when called from files dir' do
      @c.receive_line("USER test")
      @c.receive_line("PASS 1234")
      @c.receive_line("CWD files")
      @c.reset_sent!
      @c.receive_line(command)
      expect(@c.sent_data.strip).to eql('257 "/files" is the current directory')
    end
  end
end

describe EM::FTPD::Server, "RETR" do
  before(:each) do
    @c = EM::FTPD::Server.new(nil, TestDriver.new)
  end

  it "should respond with 553 when called with no param" do
    @c.receive_line("USER test")
    @c.receive_line("PASS 1234")
    @c.reset_sent!
    @c.receive_line("RETR")
    expect(@c.sent_data).to match(/553.+/)
  end

  it "should always respond with 530 when called by user not logged in" do
    @c.reset_sent!
    @c.receive_line("RETR blah.txt")
    expect(@c.sent_data).to match(/530.+/)
  end

  it "should always respond with 551 when called with an invalid file" do
    @c.receive_line("USER test")
    @c.receive_line("PASS 1234")
    @c.receive_line("PASV")
    @c.reset_sent!
    @c.receive_line("RETR blah.txt")
    expect(@c.sent_data).to match(/551.+/)
  end

  it "should always respond with 150..226 when called with valid file" do
    @c.receive_line("USER test")
    @c.receive_line("PASS 1234")
    @c.receive_line("PASV")
    @c.reset_sent!
    @c.receive_line("RETR one.txt")
    expect(@c.sent_data).to match(/150.+226.+/m)
  end

  it "should always respond with 150..226 when called outside files dir with appropriate param" do
    @c.receive_line("USER test")
    @c.receive_line("PASS 1234")
    @c.receive_line("PASV")
    @c.reset_sent!
    @c.receive_line("RETR files/two.txt")
    expect(@c.sent_data).to match(/150.+226.+/m)
  end
end

describe EM::FTPD::Server, "REST" do
  before(:each) do
    @c = EM::FTPD::Server.new(nil, TestDriver.new)
  end

  it "should accept a valid offset" do
    @c.reset_sent!
    @c.receive_line("REST 1001")
    expect(@c.sent_data).to match(/350 Restart position accepted \(1001\)\./)
  end

  it "should reject an invalid offset" do
    @c.reset_sent!
    @c.receive_line("REST seven")
    expect(@c.sent_data).to match(/554 Invalid REST position \(seven\)\./)
  end
end

%w(RMD XRMD).each do |command|
  describe EM::FTPD::Server, command do
    before(:each) do
      @c = EM::FTPD::Server.new(nil, TestDriver.new)
    end

    it "should respond with 530 if user is not logged in" do
      @c.reset_sent!
      @c.receive_line("#{command} x")
      expect(@c.sent_data).to match(/530.*/)
    end

    it "should respond with 553 when the paramater is omitted" do
      @c.receive_line("USER test")
      @c.receive_line("PASS 1234")
      @c.reset_sent!
      @c.reset_sent!
      @c.receive_line("#{command}")
      expect(@c.sent_data).to match(/553.+/)
    end

    it "should respond with 250 when the directory is deleted" do
      @c.receive_line("USER test")
      @c.receive_line("PASS 1234")
      @c.reset_sent!
      @c.reset_sent!
      @c.receive_line("#{command} four")
      expect(@c.sent_data).to match(/250.+/)
    end

    it "should respond with 550 when the directory is not deleted" do
      @c.receive_line("USER test")
      @c.receive_line("PASS 1234")
      @c.reset_sent!
      @c.reset_sent!
      @c.receive_line("#{command} x")
      expect(@c.sent_data).to match(/550.+/)
    end
  end
end

describe EM::FTPD::Server, "RNFR" do
  before(:each) do
    @c = EM::FTPD::Server.new(nil, TestDriver.new)
  end

  it "should respond with 530 if user is not logged in" do
    @c.reset_sent!
    @c.receive_line("RNFR x")
    expect(@c.sent_data).to match(/530.*/)
  end

  it "should respond with 553 when the paramater is omitted" do
    @c.receive_line("USER test")
    @c.receive_line("PASS 1234")
    @c.reset_sent!
    @c.receive_line("RNFR")
    expect(@c.sent_data).to match(/553.+/)
  end

  it "should always respond with 350 when called" do
    @c.receive_line("USER test")
    @c.receive_line("PASS 1234")
    @c.reset_sent!
    @c.receive_line("RNFR x")
    expect(@c.sent_data).to match(/350.+/)
  end
end

describe EM::FTPD::Server, "RNTO" do
  before(:each) do
    @c = EM::FTPD::Server.new(nil, TestDriver.new)
  end

  it "should respond with 530 if user is not logged in" do
    @c.reset_sent!
    @c.receive_line("RNTO x")
    expect(@c.sent_data).to match(/530.*/)
  end

  it "should respond with 553 when the paramater is omitted" do
    @c.receive_line("USER test")
    @c.receive_line("PASS 1234")
    @c.reset_sent!
    @c.receive_line("RNTO")
    expect(@c.sent_data).to match(/553.+/)
  end

  it "should respond with XXX when the RNFR command is omitted"

  it "should respond with 250 when the file is renamed" do
    @c.receive_line("USER test")
    @c.receive_line("PASS 1234")
    @c.reset_sent!
    @c.reset_sent!
    @c.receive_line("RNFR one.txt")
    @c.receive_line("RNTO two.txt")
    expect(@c.sent_data).to match(/250.+/)
  end

  it "should respond with 550 when the file is not renamed" do
    @c.receive_line("USER test")
    @c.receive_line("PASS 1234")
    @c.reset_sent!
    @c.reset_sent!
    @c.receive_line("RNFR two.txt")
    @c.receive_line("RNTO one.txt")
    expect(@c.sent_data).to match(/550.+/)
  end

end

describe EM::FTPD::Server, "QUIT" do
  before(:each) do
    @c = EM::FTPD::Server.new(nil, TestDriver.new)
  end

  it "should always respond with 221 when called" do
    @c.reset_sent!
    @c.receive_line("QUIT")
    expect(@c.sent_data).to match(/221.+/)
  end
end

describe EM::FTPD::Server, "SIZE" do

  before(:each) do
    @c = EM::FTPD::Server.new(nil, TestDriver.new)
  end

  it "should always respond with 530 when called by a non logged in user" do
    @c.reset_sent!
    @c.receive_line("SIZE one.txt")
    expect(@c.sent_data).to match(/530.+/)
  end

  it "should always respond with 553 when called with no param" do
    @c.receive_line("USER test")
    @c.receive_line("PASS 1234")
    @c.reset_sent!
    @c.receive_line("SIZE")
    expect(@c.sent_data).to match(/553.+/)
  end

  it "should always respond with 450 when called with a directory param" do
    @c.receive_line("USER test")
    @c.receive_line("PASS 1234")
    @c.reset_sent!
    @c.receive_line("SIZE files")
    expect(@c.sent_data).to match(/450.+/)
  end

  it "should always respond with 450 when called with a non-file param" do
    @c.receive_line("USER test")
    @c.receive_line("PASS 1234")
    @c.reset_sent!
    @c.receive_line("SIZE blah")
    expect(@c.sent_data).to match(/450.+/)
  end

  it "should always respond with 213 when called with a valid file param" do
    @c.receive_line("USER test")
    @c.receive_line("PASS 1234")
    @c.reset_sent!
    @c.receive_line("SIZE one.txt")
    expect(@c.sent_data).to match(/^213 56/)
  end

  it "should always respond with 213 when called with a valid file param" do
    @c.receive_line("USER test")
    @c.receive_line("PASS 1234")
    @c.reset_sent!
    @c.receive_line("SIZE files/two.txt")
    expect(@c.sent_data).to match(/^213 40/)
  end
end

# TODO STOR

describe EM::FTPD::Server, "STRU" do
  before(:each) do
    @c = EM::FTPD::Server.new(nil, TestDriver.new)
  end
  it "should respond with 553 when called with no param" do
    @c.receive_line("USER test")
    @c.receive_line("PASS 1234")
    @c.reset_sent!
    @c.receive_line("STRU")
    expect(@c.sent_data).to match(/553.+/)
  end

  it "should always respond with 530 when called by user not logged in" do
    @c.reset_sent!
    @c.receive_line("STRU F")
    expect(@c.sent_data).to match(/530.+/)
  end

  it "should always respond with 200 when called with F param" do
    @c.receive_line("USER test")
    @c.receive_line("PASS 1234")
    @c.reset_sent!
    @c.receive_line("STRU F")
    expect(@c.sent_data).to match(/200.+/)
  end

  it "should always respond with 504 when called with non-F param" do
    @c.receive_line("USER test")
    @c.receive_line("PASS 1234")
    @c.reset_sent!
    @c.receive_line("STRU S")
    expect(@c.sent_data).to match(/504.+/)
  end
end

describe EM::FTPD::Server, "SYST" do
  before(:each) do
    @c = EM::FTPD::Server.new(nil, TestDriver.new)
  end

  it "should respond with 530 when called by non-logged in user" do
    @c.reset_sent!
    @c.receive_line("SYST")
    expect(@c.sent_data).to match(/530.+/)
  end

  it "should respond with 215 when called by a logged in user" do
    @c.receive_line("USER test")
    @c.receive_line("PASS 1234")
    @c.reset_sent!
    @c.receive_line("SYST")
    expect(@c.sent_data).to match(/215.+/)
    expect(@c.sent_data.include?("UNIX")).to be_truthy
    expect(@c.sent_data.include?("L8")).to be_truthy
  end

end

describe EM::FTPD::Server, "TYPE" do
  before(:each) do
    @c = EM::FTPD::Server.new(nil, TestDriver.new)
  end

  it "should respond with 530 when called by non-logged in user" do
    @c.reset_sent!
    @c.receive_line("TYPE A")
    expect(@c.sent_data).to match(/530.+/)
  end

  it "should respond with 553 when called with no param" do
    @c.receive_line("USER test")
    @c.receive_line("PASS 1234")
    @c.reset_sent!
    @c.receive_line("TYPE")
    expect(@c.sent_data).to match(/553.+/)
  end

  it "should respond with 200 when called with 'A' by a logged in user" do
    @c.receive_line("USER test")
    @c.receive_line("PASS 1234")
    @c.reset_sent!
    @c.receive_line("TYPE A")
    expect(@c.sent_data).to match(/200.+/)
    expect(@c.sent_data.include?("ASCII")).to be_truthy
  end

  it "should respond with 200 when called with 'I' by a logged in user" do
    @c.receive_line("USER test")
    @c.receive_line("PASS 1234")
    @c.reset_sent!
    @c.receive_line("TYPE I")
    expect(@c.sent_data).to match(/200.+/)
    expect(@c.sent_data.include?("binary")).to be_truthy
  end

  it "should respond with 500 when called by a logged in user with un unrecognised param" do
    @c.receive_line("USER test")
    @c.receive_line("PASS 1234")
    @c.reset_sent!
    @c.receive_line("TYPE T")
    expect(@c.sent_data).to match(/500.+/)
  end

end
