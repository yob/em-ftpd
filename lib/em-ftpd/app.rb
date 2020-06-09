# coding: utf-8

require 'singleton'

module EM::FTPD

  class App
    include Singleton

    def self.start(config_path)
      self.instance.start(config_path)
    end

    def start(config_path)
      config_data = File.read(config_path)
      config = EM::FTPD::Configurator.new
      config.instance_eval(config_data)
      config.check!
      update_procline(config.name)

      EventMachine.epoll

      EventMachine::run do
        puts "Starting ftp server on 0.0.0.0:#{config.port}"
        EventMachine::start_server("0.0.0.0", config.port, EM::FTPD::Server, config.driver, *config.driver_args)

        setup_signal_handlers
      end
    end

    private

    def update_procline(name)
      if name
        $0 = "em-ftp [#{name}]"
      else
        $0 = "em-ftp"
      end
    end

    def setup_signal_handlers
      trap('QUIT') do
        EM.stop
      end
      trap('TERM') do
        EM.stop
      end
      trap('INT') do
        EM.stop
      end
    end

  end
end
