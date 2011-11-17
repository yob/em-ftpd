# coding: utf-8

require 'singleton'

module EM::FTPD

  class Configurator

    def initialize
      @user      = nil
      @group     = nil
      @daemonise = false
      @name      = nil
      @pid_file  = nil
      @port      = 21

      @driver    = nil
      @driver_args = nil
    end

    def user(val = nil)
      if val
        @user = val.to_s
      else
        @user
      end
    end

    def uid
      return nil if @user.nil?

      begin
        detail = Etc.getpwnam(@user)
        return detail.uid
      rescue
        $stderr.puts "user must be nil or a real account" if detail.nil?
      end
    end

    def group(val = nil)
      if val
        @group = val.to_s
      else
        @group
      end
    end

    def gid
      return nil if @group.nil?

      begin
        detail = Etc.getpwnam(@group)
        return detail.gid
      rescue
        $stderr.puts "group must be nil or a real group" if detail.nil?
      end
    end


    def daemonise(val = nil)
      if val
        @daemonise = val
      else
        @daemonise
      end
    end

    def driver(klass = nil)
      if klass
        @driver = klass
      else
        @driver
      end
    end

    def driver_args(*args)
      if args.empty?
        @driver_args
      else
        @driver_args = args
      end
    end

    def name(val = nil)
      if val
        @name = val.to_s
      else
        @name
      end
    end

    def pid_file(val = nil)
      if val
        @pid_file = val.to_s
      else
        @pid_file
      end
    end

    def port(val = nil)
      if val
        @port = val.to_i
      else
        @port
      end
    end

    def check!
      if @driver.nil?
        die("driver MUST be specified in the config file")
      end
    end

    private

    def die(msg)
      $stderr.puts msg
      exit 1
    end
  end

end
