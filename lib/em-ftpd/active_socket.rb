module EM::FTPD
  # An eventmachine module for connecting to a remote
  # port and downloading a file
  #
  class ActiveSocket < EventMachine::Connection
    include EM::Deferrable

    def self.open(host, port)
      EventMachine.connect(host, port, self)
    end

    def data
      @data ||= ""
    end

    def receive_data(chunk)
      data << chunk
    end

    def unbind
      self.set_deferred_status :succeeded, data
    end
  end
end
