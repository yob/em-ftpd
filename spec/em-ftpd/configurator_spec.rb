require 'spec_helper'
require 'ostruct'

describe EM::FTPD::Configurator do  
  describe "initialization" do    
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
