# coding: utf-8

# monkey patch a few classes to allow testing without a network connection
class EM::FTPD::Server
  def send_data(data)
    sent_data << data
  end

  def sent_data
    @sent_data ||= ''
  end

  def reset_sent!
    @sent_data = ""
  end

  def oobdata
    @oobdata ||= ""
  end
  
  def reset_oobdata!
    @oobdata = ""
  end

  #def initialize
  #  connection_completed
  #end

  # fake the socket data the server is running on. Resolves
  # to 127.0.0.1
  def get_sockname
    if RUBY_PLATFORM =~ /darwin/
      "\020\002\010\111\177\000\000\001\000\000\000\000\000\000\000\000"
    elsif RUBY_PLATFORM =~ /linux/
      "\002\000\000\025\177\000\000\001\000\000\000\000\000\000\000\000"
    end
  end

  def close_connection_after_writing
    true
  end
end

class EM::FTPD::PassiveSocket
  class << self
    def start(host, control_server)
      control_server.datasocket = self.new(nil)
      @@control_server = control_server
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
    @@control_server.oobdata << data
  end

  def sent_data
    @@control_server.oobdata
  end

  def reset_sent!
    @@control_server.reset_oobdata!
  end

  def close_connection_after_writing
    true
  end

end
