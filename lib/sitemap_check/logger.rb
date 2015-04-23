class SitemapCheck
  class Logger
    def initialize(stream = $stdout)
      self.stream = stream
      self.mutex = Mutex.new
    end

    def log(message)
      mutex.synchronize { stream.puts message }
    end

    protected

    attr_accessor :stream, :mutex
  end
end
