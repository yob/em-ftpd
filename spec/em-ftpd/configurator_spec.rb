describe EM::FTPD::Configurator do
  describe "#gid" do
    it "should retrieve the group using Etc.getgrnam" do
      configurator = EM::FTPD::Configurator.new
      configurator.group 'testgroup'
      Etc.should_receive(:getgrnam).with('testgroup').and_return(Struct::Group.new('staff', '*', 20, ['root']))
      configurator.gid.should == 20
    end
  end
end