require 'eventmachine'

module EM::FTPD
  #
  # Like EventMachine::FileStreamer, this class handles streaming of (potientially huge amounts of) data.
  # This class can stream arbitrary IO objects. It is not bound to only stream files.
  #
  # The caller is responsible for closing the IO object if it needs closing.
  #
  # @example
  #
  # module IOSender
  #    def post_init
  #      file = File.new('/tmp/bigfile.tar')
  #      streamer = EM::FTPD::IOStreamer.new(self, file)
  #      streamer.callback{
  #        # file was sent successfully
  #        close_connection_after_writing
  #        file.close
  #      }
  #    end
  #  end
  #
  class IOStreamer
    include EM::Deferrable

    ChunkSize         = EM::FileStreamer::ChunkSize
    BackpressureLevel = EM::FileStreamer::BackpressureLevel

    def initialize(connection, io)
      @connection       = connection
      @io               = io
      @bytes_streamed   = 0

      stream_one_chunk
    end

    attr_reader :bytes_streamed

    private

    def stream_one_chunk
      loop {
        if !@io.eof
          if @connection.get_outbound_data_size > BackpressureLevel
            EventMachine::next_tick {stream_one_chunk}
            break
          else
            begin
              chunk_data = @io.readpartial ChunkSize
            rescue EOFError
              next
            end
            @connection.send_data(chunk_data)
            @bytes_streamed += chunk_data.bytesize
          end
        else
          succeed
          break
        end
      }
    rescue IOError => ex
      fail ex
    end
  end
end
