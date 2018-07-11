require 'spec_helper'
require 'ostruct'

describe EM::FTPD::Configurator do  
  describe "initialization" do    
    describe '#user' do
      subject { super().user }
      it { is_expected.to be_nil }
    end

    describe '#group' do
      subject { super().group }
      it { is_expected.to be_nil }
    end

    describe '#daemonise' do
      subject { super().daemonise }
      it { is_expected.to be_falsey }
    end

    describe '#name' do
      subject { super().name }
      it { is_expected.to be_nil }
    end

    describe '#pid_file' do
      subject { super().pid_file }
      it { is_expected.to be_nil }
    end

    describe '#port' do
      subject { super().port }
      it { is_expected.to eq(21) }
    end

    describe '#driver' do
      subject { super().driver }
      it { is_expected.to be_nil }
    end

    describe '#driver_args' do
      subject { super().driver_args }
      it { is_expected.to eq([ ]) }
    end
  end
  
  describe "#user" do
    it "should set the user to the specified value" do
      subject.user 'bob'
      expect(subject.user).to eq('bob')
    end
    
    it "should set the value to a String if another input type is given" do
      subject.user :bob
      expect(subject.user).to eq('bob')
    end
  end

  describe "#uid" do
    it "should retrieve the user id based on the user name" do
      subject.user 'justin'
      expect(Etc).to receive(:getpwnam).with('justin').and_return(OpenStruct.new(:uid => 501))
        
      expect(subject.uid).to eq(501)
    end
    
    it "should return nil when the user is not set" do
      expect(subject.uid).to be_nil
    end
    
    it "should print an error and capture an Exception if the user entry is not able to be determined with Etc.getpwnam" do
      subject.user 'justin'
      expect(Etc).to receive(:getpwnam).with('justin').and_return(nil)
      expect($stderr).to receive(:puts).with('user must be nil or a real account')
      expect { subject.uid }.to_not raise_error
    end
  end
    

  describe "#group" do
    it "should set the group to the specified value" do
      subject.group 'staff'
      expect(subject.group).to eq('staff')
    end
    
    it "should set the value to a String if another input type is given" do
      subject.group :staff
      expect(subject.group).to eq('staff')
    end    
  end

  describe "#gid" do
    it "should retrieve the group id based on the group name" do
      subject.group 'testgroup'
      expect(Etc).to receive(:getgrnam).with('testgroup').and_return(Struct::Group.new('staff', '*', 20, ['root']))
      expect(subject.gid).to eq(20)
    end
    
    it "should return nil when the group is not set" do
      expect(subject.gid).to be_nil
    end
    
    it "should print an error and capture an Exception  if the group entry is not able to be determined with Etc.getgrnam" do
      subject.group 'testgroup'
      expect(Etc).to receive(:getgrnam).with('testgroup').and_return(nil)
      expect($stderr).to receive(:puts).with('group must be nil or a real group')
      expect { subject.gid }.to_not raise_error
    end
  end

  describe "#daemonise" do
    it "should set the daemonise option to the specified value" do
      subject.daemonise true
      expect(subject.daemonise).to be_truthy
    end    
  end

  describe "#driver" do
    class FauxDriver ; end
    
    it "should set the driver to the specified value" do
      subject.driver FauxDriver
      expect(subject.driver).to eq(FauxDriver)
    end
  end

  describe "#pid_file" do
    it "should set the pid_file to the specified value" do
      subject.pid_file 'mypidfile.pid'
      expect(subject.pid_file).to eq('mypidfile.pid')
    end
    
    it "should set the value to a String if another input type is given" do
      subject.pid_file :mypidfile
      expect(subject.pid_file).to eq('mypidfile')
    end
  end

  describe "#port" do
    it "should set the port option to the specified value" do
      subject.port 2120
      expect(subject.port).to eq(2120)
    end
    
    it "should set the value to an Integer if another input type is given" do
      subject.port '2120'
      expect(subject.port).to eq(2120)
    end
  end

  describe "#name" do
    it "should set the name to the specified value" do
      subject.name 'server'
      expect(subject.name).to eq('server')
    end

    it "should set the value to a String if another input type is given" do
      subject.name :server
      expect(subject.name).to eq('server')
    end    
  end

  describe "#driver_args" do
    it "should set the driver args to the arguments given" do
      subject.driver_args :a, :b, :c
      expect(subject.driver_args).to eq([:a, :b, :c])
    end
  end
  
  describe "#check!" do
    it "should raise an error and Exit if the driver is not set" do
      expect($stderr).to receive(:puts).with('driver MUST be specified in the config file')
      expect { subject.check! }.to raise_error SystemExit
    end
  end
end
