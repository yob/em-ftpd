module EM::FTPD
  # An eventmachine module for connecting to a remote
  # port and downloading a file
  #
  class ActiveSocket < EventMachine::Connection
    include EM::Deferrable
    include BaseSocket

    def self.open(host, port)
      EventMachine.connect(host, port, self)
    end

  end
end
