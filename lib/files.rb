module Files
  # delete a file
  def cmd_dele(param)
    send_unauthorised and return unless logged_in?
    send_param_required and return if param.nil?

    path = build_path(param)

    if delete_file(path)
      send_response "250 File deleted"
    else
      send_action_not_taken
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

    if data = get_file(path)
      send_response "150 Data transfer starting #{data.size} bytes"
      send_outofband_data(data)
    else
      send_response "551 file not available"
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

    if rename(@from_filename, build_path(param))
      send_response "250 File renamed."
    else
      send_action_not_taken
    end
  end

  # return the size of a file in bytes
  def cmd_size(param)
    # safety checks to make sure clients can't request files they're
    # not allowed to
    send_unauthorised and return unless logged_in?
    send_param_required and return if param.nil?

    path = build_path(param)

    # if file exists, send it to the client
    if path == "/one.txt"
      send_response "213 #{FILE_ONE.size}"
    elsif path == "/files/two.txt"
      send_response "213 #{FILE_TWO.size}"
    else
      # otherwise, inform the user the file doesn't exist
      send_response "450 file not available"
    end
  end

  # save a file from a client
  def cmd_stor(param)
    send_unauthorised and return unless logged_in?
    send_param_required and return if param.nil?

    filename = build_path(param)

    if can_put_file(filename)
      put_file(filename, receive_outofband_data)
    else
      send_action_not_taken
    end
  end

end