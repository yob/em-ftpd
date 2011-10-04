require 'socket'
require 'stringio'

module EM::FTPD
  class Server < EM::Protocols::LineAndTextProtocol

    LBRK = "\r\n"

    include Authentication
    include Directories
    include Files

    COMMANDS = %w[quit type user retr stor port cdup cwd dele rmd pwd list size
                  syst mkd pass xcup xpwd xcwd xrmd rest allo nlst pasv allo help
                  noop mode rnfr rnto stru]

    attr_reader :root, :name_prefix
    attr_accessor :datasocket

    def initialize(driver)
      super
      @driver = driver
    end

    def post_init
      @mode   = :binary
      @name_prefix = "/"

      send_response "220 FTP server (rftpd) ready"
    end

    def receive_line(str)
      Fiber.new do
        cmd, param = parse_request(str)

        # if the command is contained in the whitelist, and there is a method
        # to handle it, call it. Otherwise send an appropriate response to the
        # client
        if COMMANDS.include?(cmd) && self.respond_to?("cmd_#{cmd}".to_sym, true)
          begin
            self.__send__("cmd_#{cmd}".to_sym, param)
          rescue Exception => err
            puts "#{err.class}: #{err}"
            puts err.backtrace.join("\n")
          end
        else
          send_response "500 Sorry, I don't understand #{cmd.upcase}"
        end
      end.resume
    end

    private

    def build_path(filename = nil)
      if filename && filename[0,1] == "/"
        path = File.expand_path(filename)
      elsif filename && filename != '-a'
        path = File.expand_path("#{@name_prefix}/#{filename}")
      else
        path = File.expand_path(@name_prefix)
      end
      path.gsub(/\/+/,"/")
    end

    # split a client's request into command and parameter components
    def parse_request(data)
      data.strip!
      space = data.index(" ")
      if space
        cmd = data[0, space]
        param = data[space+1, data.length - space]
        param = nil if param.strip.size == 0
      else
        cmd = data
        param = nil
      end

      [cmd.downcase, param]
    end


    def close_datasocket
      if @datasocket
        @datasocket.close_connection_after_writing
        @datasocket = nil
      end

      # stop listening for data socket connections, we have one
      if @listen_sig
        PassiveSocket.stop(@listen_sig)
        @listen_sig = nil
      end
    end

    def cmd_allo(param)
      send_response "202 Obsolete"
    end

    # handle the HELP FTP command by sending a list of available commands.
    def cmd_help(param)
      commands = COMMANDS
      commands.sort!
      send_response "214- The following commands are recognized."
      i   = 1
      str = "  "
      commands.each do |c|
        str += "#{c}"
        str += "\t\t"
        str += LBRK << "  " if (i % 3) == 0
        i   += 1
      end
      send_response str, true
    end


    # the original FTP spec had various options for hosts to negotiate how data
    # would be sent over the data socket, In reality these days (S)tream mode
    # is all that is used for the mode - data is just streamed down the data
    # socket unchanged.
    #
    def cmd_mode(param)
      send_unauthorised and return unless logged_in?
      send_param_required and return if param.nil?
      if param.upcase.eql?("S")
        send_response "200 OK"
      else
        send_response "504 MODE is an obsolete command"
      end
    end


    # handle the NOOP FTP command. This is essentially a ping from the client
    # so we just respond with an empty 200 message.
    def cmd_noop(param)
      send_response "200"
    end

    # Passive FTP. At the clients request, listen on a port for an incoming
    # data connection. The listening socket is opened on a random port, so
    # the host and port is sent back to the client on the control socket.
    def cmd_pasv(param)
      send_unauthorised and return unless logged_in?

      # close any existing data socket
      close_datasocket

      # grab the host/address the current connection is
      # operating on
      host = Socket.unpack_sockaddr_in( self.get_sockname ).last

      # open a listening socket on the appropriate host
      # and on a random port
      @listen_sig = PassiveSocket.start(host, self)
      port = PassiveSocket.get_port(@listen_sig)

      # let the client know where to connect
      p1 = (port / 256).to_i
      p2 = port % 256

      send_response "227 Entering Passive Mode (" + host.split(".").join(",") + ",#{p1},#{p2})"
    end

    # Active FTP. An alternative to Passive FTP. The client as a listening socket
    # open, waiting for us to connect and establish a data socket. Attempt to
    # open a connection to the host and port they specify and save the connection,
    # ready for either end to send something down it.
    def cmd_port(param)
      send_unauthorised and return unless logged_in?
      send_param_required and return if param.nil?

      nums = param.split(',')
      port = nums[4].to_i * 256 + nums[5].to_i
      host = nums[0..3].join('.')
      close_datasocket

      puts "connecting to client #{host} on #{port}"
      @datasocket = ActiveSocket.open(host, port)

      puts "Opened active connection at #{host}:#{port}"
      send_response "200 Connection established (#{port})"
    rescue
      puts "Error opening data connection to #{host}:#{port}"
      send_response "425 Data connection failed"
    end



    # handle the QUIT FTP command by closing the connection
    def cmd_quit(param)
      send_response "221 Bye"
      close_datasocket
      close_connection_after_writing
    end


    # like the MODE and TYPE commands, stru[cture] dates back to a time when the FTP
    # protocol was more aware of the content of the files it was transferring, and
    # would sometimes be expected to translate things like EOL markers on the fly.
    #
    # These days files are sent unmodified, and F(ile) mode is the only one we
    # really need to support.
    def cmd_stru(param)
      send_param_required and return if param.nil?
      send_unauthorised and return unless logged_in?
      if param.upcase.eql?("F")
        send_response "200 OK"
      else
        send_response "504 STRU is an obsolete command"
      end
    end

    # return the name of the server
    def cmd_syst(param)
      send_response "530 Not logged in" and return unless @user
      send_response "215 UNIX Type: L8"
    end

    # like the MODE and STRU commands, TYPE dates back to a time when the FTP
    # protocol was more aware of the content of the files it was transferring, and
    # would sometimes be expected to translate things like EOL markers on the fly.
    #
    # Valid options were A(SCII), I(mage), E(BCDIC) or LN (for local type). Since
    # we plan to just accept bytes from the client unchanged, I think Image mode is
    # adequate. The RFC requires we accept ASCII mode however, so accept it, but
    # ignore it.
    def cmd_type(param)
      send_unauthorised and return unless logged_in?
      send_param_required and return if param.nil?
      if param.upcase.eql?("A")
        send_response "200 Type set to ASCII"
      elsif param.upcase.eql?("I")
        send_response "200 Type set to binary"
      else
        send_response "500 Invalid type"
      end
    end


    # send data to the client across the data socket.
    #
    # The data socket is NOT guaranteed to be setup by the time this method runs.
    # If it isn't ready yet, exit the method and try again on the next reactor
    # tick. This is particularly likely with some clients that operate in passive
    # mode. They get a message on the control port with the data port details, so
    # they start up a new data connection AND send they command that will use it
    # in close succession.
    #
    # The data port setup needs to complete a TCP handshake before it will be
    # ready to use, so it may take a few RTTs after the command is received at
    # the server before the data socket is ready.
    #
    def send_outofband_data(data, interval = 0.1)
      if @datasocket.nil? && interval < 25
        EventMachine.add_timer(interval) { send_outofband_data(data, interval * 2)}
        return
      elsif @datasocket.nil?
        send_response "425 Error establishing connection"
        return
      end

      if data.is_a?(Array)
        data = data.join(LBRK) << LBRK
      end
      data = StringIO.new(data) if data.kind_of?(String)
      begin
        bytes = 0
        data.each do |line|
          @datasocket.send_data(line)
          bytes += line.length
        end
        send_response "226 Closing data connection, sent #{bytes} bytes"
      ensure
        close_datasocket
        data.close if data.class == File
      end
    rescue
      send_response "425 Error establishing connection"
    end

    # receive a file data from the client across the data socket.
    #
    # The data socket is NOT guaranteed to be setup by the time this method runs.
    # If this happens, exit the method early and try again later. See the method
    # comments to send_outofband_data for further explanation.
    #
    def receive_outofband_data(fiber = nil)
      fiber = Fiber.current

      10.times do |i|
        if @datasocket.nil? && interval < 25
          EventMachine.add_timer(0.1 * (i + 1) ** 2) { fiber.resume }
          Fiber.yield
        else
          break
        end
      end

      if @datasocket.nil?
        send_response "425 Error establishing connection"
        return false
      end

      # let the client know we're ready to start
      send_response "150 Data transfer starting"

      fiber = Fiber.current # not sure why we have to do this again, but it's required
      @datasocket.callback do |data|
        send_response "200 OK, received #{data.size} bytes"
        fiber.resume(data)
      end
      Fiber.yield
    end

    # all responses from an FTP server end with \r\n, so wrap the
    # send_data callback
    def send_response(msg, no_linebreak = false)
      msg += LBRK unless no_linebreak
      send_data msg
    end

    def send_param_required
      send_response "553 action aborted, required param missing"
    end

    def send_permission_denied
      send_response "550 Permission denied"
    end

    def send_action_not_taken
      send_response "550 Action not taken"
    end

    def send_illegal_params
      send_response "553 action aborted, illegal params"
    end

    def send_unauthorised
      send_response "530 Not logged in"
    end

  end
end
