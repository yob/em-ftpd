module EM::FTPD
  module Directories
    # go up a directory, really just an alias
    def cmd_cdup(param)
      send_unauthorised and return unless logged_in?
      cmd_cwd("..")
    end

    # As per RFC1123, XCUP is a synonym for CDUP
    alias cmd_xcup cmd_cdup


    # change directory
    def cmd_cwd(param)
      send_unauthorised and return unless logged_in?
      path = build_path(param)

      @driver.change_dir(path) do |result|
        if result
          @name_prefix = path
          send_response "250 Directory changed to #{path}"
        else
          send_permission_denied
        end
      end
    end

    # As per RFC1123, XCWD is a synonym for CWD
    alias cmd_xcwd cmd_cwd

    # make directory
    def cmd_mkd(param)
      send_unauthorised and return unless logged_in?
      send_param_required and return if param.nil?

      @driver.make_dir(build_path(param)) do |result|
        if result
          send_response "257 Directory created"
        else
          send_action_not_taken
        end
      end
    end

    # return a listing of the current directory, one per line, each line
    # separated by the standard FTP EOL sequence. The listing is returned
    # to the client over a data socket.
    #
    def cmd_nlst(param)
      send_unauthorised and return unless logged_in?
      send_response "150 Opening ASCII mode data connection for file list"

      @driver.dir_contents(build_path(param)) do |files|
        send_outofband_data(files.map(&:name))
      end
    end


    def default_files(dir)
      [
        DirectoryItem.new(:name => '.', :permissions => 'rwxrwxrwx', :directory => true),
        DirectoryItem.new(:name => '..', :permissions => 'rwxrwxrwx', :directory => true),
      ]
    end

    # return a detailed list of files and directories
    def cmd_list(param)
      send_unauthorised and return unless logged_in?
      send_response "150 Opening ASCII mode data connection for file list"

      param = '' if param.to_s == '-a'


      @driver.dir_contents(build_path(param)) do |files|
        now = Time.now
        lines = files.map { |item|
          sizestr = (item.size || 0).to_s.rjust(12)
          "#{item.directory ? 'd' : '-'}#{item.permissions || 'rwxrwxrwx'} 1 #{item.owner || 'owner'} #{item.group || 'group'} #{sizestr} #{(item.time || now).strftime("%b %d %H:%M")} #{item.name}"
        }
        send_outofband_data(lines)
      end
    end

    # return the current directory
    def cmd_pwd(param)
      send_unauthorised and return unless logged_in?
      send_response "257 \"#{@name_prefix}\" is the current directory"
    end

    # As per RFC1123, XPWD is a synonym for PWD
    alias cmd_xpwd cmd_pwd

    # delete a directory
    def cmd_rmd(param)
      send_unauthorised and return unless logged_in?
      send_param_required and return if param.nil?

      @driver.delete_dir(build_path(param)) do |result|
        if result
          send_response "250 Directory deleted."
        else
          send_action_not_taken
        end
      end
    end

    # As per RFC1123, XRMD is a synonym for RMD
    alias cmd_xrmd cmd_rmd

  end
end
