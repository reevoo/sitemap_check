require 'httpclient'

class SitemapCheck
  class Page
    def initialize(url, http = HTTPClient.new, holdoff = 1)
      self.url = url
      self.http = http
      self.tries = 0
      self.holdoff = holdoff
    end

    attr_reader :url

    def exists?
      @_exists ||= http.head(url, follow_redirect: true).ok?
    rescue SocketError, HTTPClient::ConnectTimeoutError, Errno::ETIMEDOUT
      self.tries += 1
      if tries < 5
        sleep holdoff
        retry
      else
        @_exists = false
      end
    rescue HTTPClient::BadResponseError
      @_exists = false
    end

    protected

    attr_accessor :http, :tries, :holdoff
    attr_writer :url
  end
end
