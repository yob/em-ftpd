# coding: utf-8

# an FTP server that uses redis for persistance.
#
# NOTE: This may not be working as I don't have redis installed
#       to test it. Feel free to fix it and submit a patch
#
# Usage:
#
#   ruby -Ilib examples/redis.rb

require 'rubygems'
require 'bundler'

Bundler.setup

require 'em-ftpd'

class RedisFTPDriver

  def initialize(redis)
    @redis = redis
  end

  def change_dir(user, path, &block)
    yield path == "/" || @redis.sismember(directory_key(File.dirname(path)), File.basename(path) + "/")
  end

  def dir_contents(user, path, &block)
    response = @redis.smembers(directory_key(path))

    yield response.map do |key|
      name, size = key.sub(/ftp:\//, '').sub(%r{/$}, '')
      dir = key.match(%r{/$})
      EM::FPD::DirectoryItem.new(
        :name => name,
        :directory => dir,
        :size => size
      )
    end
  end

  def authenticate(user, pass, &block)
    yield true
  end

  def get_file(user, path, &block)
    yield @redis.get(file_data_key(path))
  end

  def put_file(user, path, data, &block)
    @redis.set(file_data_key(path), data)
    @redis.sadd(directory_key(File.dirname(path)), File.basename(path))
    yield
  end

  def delete_file(user, path, &block)
    @redis.del(file_data_key(path))
    @redis.srem(directory_key(File.dirname(path)), File.basename(path))
    yield true
  end


  def delete_dir(user, path, &block)
    (@redis.keys(directory_key(path + "/*") + @redis.keys(file_data_key(path + "/*")))).each do |key|
      @redis.del(key)
    end
    @redis.srem(directory_key(File.dirname(path), File.basename(path) + "/"))
    yield true
  end

  def rename(user, from, to, &block)
    if @redis.sismember(directory_key(File.dirname(from)), File.basename(from))
      yield move_file(from, to)
    elsif @redis.sismember(directory_key(File.dirname(from)), File.basename(from) + '/')
      yield move_dir(from, to)
    else
      yield false
    end
  end

  def make_dir(user, path, &block)
    @redis.sadd(directory_key(File.dirname(path)), File.basename(path) + "/")
    yield true
  end

  private

  def file_data_key(path)
    "ftp:data:#{path}"
  end

  def directory_key(path)
    "ftp:dir:#{path}"
  end

  def move_file(from, to)
    @redis.rename(file_data_key(from), file_data_key(to))
    @redis.srem(directory_key(File.dirname(from)), File.basename(from))
    @redis.sadd(directory_key(File.dirname(to)), File.basename(to))
  end

  def move_dir(from, to)
    if @redis.exists(directory_key(from))
      @redis.rename(directory_key(from), directory_key(to))
    end
    @redis.srem(directory_key(File.dirname(from)), File.basename(from) + "/")
    @redis.sadd(directory_key(File.dirname(to)), File.basename(to) + "/")
    @redis.keys(directory_key(from + "/*")).each do |key|
      new_key = directory_key(File.dirname(to)) + key.sub(directory_key(File.dirname(from)), '')
      @redis.rename(key, new_key)
    end
    @redis.keys(file_data_key(from + "/*")).each do |key|
      new_key = file_data_key(to) + key.sub(file_data_key(from), '/')
      @redis.rename(key, new_key)
    end
  end

end

# signal handling, ensure we exit gracefully
trap "SIGCLD", "IGNORE"
trap "INT" do
  puts "exiting..."
  puts
  EventMachine::run
  exit
end

EM.run do
  redis  = EM::Protocols::Redis.connect
  driver = RedisFTPDriver.new(redis)
  puts "Starting ftp server on 0.0.0.0:5555"
  EventMachine::start_server("0.0.0.0", 5555, FTPServer, driver)
end
