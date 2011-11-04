module EM::FTPD

  # An eventmachine module for opening a socket for the client to connect
  # to and send a file
  #
  class PassiveSocket < EventMachine::Connection
    include EM::Deferrable

    def self.start(host, control_server)
      EventMachine.start_server(host, 0, self) do |conn|
        control_server.datasocket = conn
      end
    end

    # stop the server with signature "sig"
    def self.stop(sig)
      EventMachine.stop_server(sig)
    end

    # return the port the server with signature "sig" is listening on
    #
    def self.get_port(sig)
      Socket.unpack_sockaddr_in( EM.get_sockname( sig ) ).first
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
