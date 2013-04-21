# coding: utf-8

# a super simple driver that is used in our specs


class TestDriver
  FILE_ONE = "This is the first file available for download.\n\nBy James"
  FILE_TWO = "This is the file number two.\n\n2009-03-21"

  def change_dir(path, &block)
    yield path == "/" || path == "/files"
  end

  def dir_contents(path, &block)
    yield case path
          when "/"      then
            [ dir_item("."), dir_item(".."), dir_item("files"), file_item("one.txt", FILE_ONE.bytesize) ]
          when "/files" then
            [ dir_item("."), dir_item(".."), file_item("two.txt", FILE_TWO.bytesize) ]
          else
            []
          end
  end

  def authenticate(user, pass, &block)
    yield user == "test" && pass == "1234"
  end

  def bytes(path, &block)
    yield case path
          when "/one.txt"       then FILE_ONE.size
          when "/files/two.txt" then FILE_TWO.size
          else
            false
          end
  end

  def get_file(path, &block)
    yield case path
          when "/one.txt"       then FILE_ONE
          when "/files/two.txt" then FILE_TWO
          else
            false
          end
  end

  def put_file(path, data, &block)
    yield path == "/three.txt"
  end

  def delete_file(path, &block)
    yield path == "/four.txt"
  end

  def delete_dir(path, &block)
    yield path == "/four"
  end

  def rename(from, to, &block)
    yield from == "/one.txt"
  end

  def make_dir(path, &block)
    yield path == "/four"
  end

  def mtime(path, &block)
    yield case path
          when "/files"         then Time.utc(2013,4,21,11,0,0)
          when "/one.txt"       then Time.utc(2013,4,21,12,0,0)
          when "/files/two.txt" then Time.utc(2013,4,21,13,0,0)
          else
            false
          end
  end

  private

  def dir_item(name)
    EM::FTPD::DirectoryItem.new(:name => name, :directory => true, :size => 0, :permissions => "rwxr-xr-x")
  end

  def file_item(name, bytes)
    EM::FTPD::DirectoryItem.new(:name => name, :directory => false, :size => bytes, :permissions => "rwxr-xr-x")
  end

end
