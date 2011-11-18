# coding: utf-8

require 'singleton'

module EM::FTPD

  class App
    include Singleton

    def daemonise!(config)
      return unless config.daemonise

      ## close unneeded descriptors,
      $stdin.reopen("/dev/null")
      $stdout.reopen("/dev/null","w")
      $stderr.reopen("/dev/null","w")

      ## drop into the background.
      pid = fork
      if pid
        ## parent: save pid of child, then exit
        if config.pid_file
          File.open(config.pid_file, "w") { |io| io.write pid }
        end
        exit!
      end
    end

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

        daemonise!(config)
        change_gid(config.gid)
        change_uid(config.uid)
        setup_signal_handlers
      end
    end

    private

    def update_procline(name)
      if name
        $0 = "em-ftp - #{name}"
      else
        $0 = "em-ftp"
      end
    end

    def change_gid(gid)
      if gid && Process.gid == 0
        Process.gid = gid
      end
    end

    def change_uid(uid)
      if uid && Process.euid == 0
        Process::Sys.setuid(uid)
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
