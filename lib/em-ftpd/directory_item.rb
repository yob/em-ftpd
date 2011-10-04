module EM::FTPD
  class DirectoryItem
    ATTRS = [:name, :owner, :group, :size, :time, :permissions, :directory]
    attr_accessor *ATTRS

    def initialize(options)
      options.each do |attr, value|
        self.send("#{attr}=", value)
      end
    end
  end
end
