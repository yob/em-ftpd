module EM::FTPD
  module Files

    # delete a file
    def cmd_dele(param)
      send_unauthorised and return unless logged_in?
      send_param_required and return if param.nil?

      path = build_path(param)

      @driver.delete_file(path) do |result|
        if result
          send_response "250 File deleted"
        else
          send_action_not_taken
        end
      end
    end

    # resume downloads
    def cmd_rest(param)
      send_response "500 Feature not implemented"
    end

    # send a file to the client
    def cmd_retr(param)
      send_unauthorised and return unless logged_in?
      send_param_required and return if param.nil?

      path = build_path(param)

      @driver.get_file(path) do |data|
        if data
          send_response "150 Data transfer starting #{data.size} bytes"
          send_outofband_data(data)
        else
          send_response "551 file not available"
        end
      end
    end

    # rename a file
    def cmd_rnfr(param)
      send_unauthorised and return unless logged_in?
      send_param_required and return if param.nil?

      @from_filename = build_path(param)
      send_response "350 Requested file action pending further information."
    end

    # rename a file
    def cmd_rnto(param)
      send_unauthorised and return unless logged_in?
      send_param_required and return if param.nil?

      @driver.rename(@from_filename, build_path(param)) do |result|
        if result
          send_response "250 File renamed."
        else
          send_action_not_taken
        end
      end
    end

    # return the size of a file in bytes
    def cmd_size(param)
      send_unauthorised and return unless logged_in?
      send_param_required and return if param.nil?

      @driver.bytes(build_path(param)) do |bytes|
        if bytes
          send_response "213 #{bytes}"
        else
          send_response "450 file not available"
        end
      end
    end

    # save a file from a client
    def cmd_stor(param)
      send_unauthorised and return unless logged_in?
      send_param_required and return if param.nil?

      path = build_path(param)

      if driver_supports :streaming
        wait_for_datasocket do |datasocket|
          if datasocket
            send_response "150 Data transfer starting"
            @driver.put_file(path, datasocket) do |size|
              case size
              when FalseClass
                send_action_not_taken
              else
                send_response "200 OK, received #{size} bytes"
              end
            end
          else
            send_response "425 Error establishing connection"
          end
        end
      else
        receive_outofband_data do |data|
          @driver.put_file(path, data) do |result|
            send_action_not_taken unless result
          end
        end
      end
      
    end

  end
end
