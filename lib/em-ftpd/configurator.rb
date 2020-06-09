# coding: utf-8

module EM::FTPD

  class Configurator

    def initialize
      @name      = nil
      @pid_file  = nil
      @port      = 21

      @driver    = nil
      @driver_args = []
    end

    def driver(klass = nil)
      get_or_set(:driver, klass)
    end

    def driver_args(*args)
      if args.empty?
        @driver_args
      else
        @driver_args = args
      end
    end

    def name(val = nil)
      get_or_set(:name, val, :to_s)
    end

    def pid_file(val = nil)
      get_or_set(:pid_file, val, :to_s)
    end

    def port(val = nil)
      get_or_set(:port, val, :to_i)
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

    def get_or_set(attribute, value, coercion_method = nil)
      if value
        converted_value = coercion_method ? value.send(coercion_method) : value
        instance_variable_set(variable_name_for(attribute), converted_value)
      else
        instance_variable_get(variable_name_for(attribute))
      end
    end

    def variable_name_for(attribute)
      :"@#{attribute}"
    end
  end

end
