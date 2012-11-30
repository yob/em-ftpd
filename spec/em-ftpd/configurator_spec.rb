require 'spec_helper'

describe EM::FTPD::Configurator do  
  describe "initialization" do    
    its(:user)        { should be_nil }
    its(:group)       { should be_nil }
    its(:daemonise)   { should be_false }
    its(:name)        { should be_nil }
    its(:pid_file)    { should be_nil }
    its(:port)        { should == 21 }
    its(:driver)      { should be_nil }
    its(:driver_args) { should == [ ] }
  end
  
  describe "#user" do
    it "should set the user to the specified value" do
      subject.user 'bob'
      subject.user.should == 'bob'
    end
    
    it "should set the value to a String if another input type is given" do
      subject.user :bob
      subject.user.should == 'bob'
    end
  end

  describe "#uid" do
    it "should retrieve the user id based on the user name" do
      subject.user 'justin'
      Etc.should_receive(:getpwnam).with('justin').
        and_return(Struct::Passwd.new('staff', '*********', 501, 20, 'Justin Leitgeb', '/Users/justin', '/bin/bash', 0, '', 0))
        
      subject.uid.should == 501
    end
    
    it "should return nil when the user is not set" do
      subject.uid.should be_nil
    end
    
    it "should print an error and capture an Exception if the user entry is not able to be determined with Etc.getpwnam" do
      subject.user 'justin'
      Etc.should_receive(:getpwnam).with('justin').and_return(nil)
      $stderr.should_receive(:puts).with('user must be nil or a real account')
      expect { subject.uid }.to_not raise_error
    end
  end
    

  describe "#group" do
    it "should set the group to the specified value" do
      subject.group 'staff'
      subject.group.should == 'staff'
    end
    
    it "should set the value to a String if another input type is given" do
      subject.group :staff
      subject.group.should == 'staff'
    end    
  end

  describe "#gid" do
    it "should retrieve the group id based on the group name" do
      subject.group 'testgroup'
      Etc.should_receive(:getgrnam).with('testgroup').and_return(Struct::Group.new('staff', '*', 20, ['root']))
      subject.gid.should == 20
    end
    
    it "should return nil when the group is not set" do
      subject.gid.should be_nil
    end
    
    it "should print an error and capture an Exception  if the group entry is not able to be determined with Etc.getgrnam" do
      subject.group 'testgroup'
      Etc.should_receive(:getgrnam).with('testgroup').and_return(nil)
      $stderr.should_receive(:puts).with('group must be nil or a real group')
      expect { subject.gid }.to_not raise_error
    end
  end

  describe "#daemonise" do
    it "should set the daemonise option to the specified value" do
      subject.daemonise true
      subject.daemonise.should be_true
    end    
  end

  describe "#driver" do
    class FauxDriver ; end
    
    it "should set the driver to the specified value" do
      subject.driver FauxDriver
      subject.driver.should == FauxDriver
    end
  end

  describe "#pid_file" do
    it "should set the pid_file to the specified value" do
      subject.pid_file 'mypidfile.pid'
      subject.pid_file.should == 'mypidfile.pid'
    end
    
    it "should set the value to a String if another input type is given" do
      subject.pid_file :mypidfile
      subject.pid_file.should == 'mypidfile'
    end
  end

  describe "#port" do
    it "should set the port option to the specified value" do
      subject.port 2120
      subject.port.should == 2120
    end
    
    it "should set the value to an Integer if another input type is given" do
      subject.port '2120'
      subject.port.should == 2120
    end
  end

  describe "#name" do
    it "should set the name to the specified value" do
      subject.name 'server'
      subject.name.should == 'server'
    end

    it "should set the value to a String if another input type is given" do
      subject.name :server
      subject.name.should == 'server'
    end    
  end

  describe "#driver_args" do
    it "should set the driver args to the arguments given" do
      subject.driver_args :a, :b, :c
      subject.driver_args.should == [:a, :b, :c]
    end
  end
  
  describe "#check!" do
    it "should raise an error and Exit if the driver is not set" do
      $stderr.should_receive(:puts).with('driver MUST be specified in the config file')
      expect { subject.check! }.to raise_error SystemExit
    end
  end
end