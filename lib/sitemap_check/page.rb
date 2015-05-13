require 'httpclient'

class SitemapCheck
  class Page
    def initialize(url, http = HTTPClient.new, holdoff = 1)
      self.url = url
      self.http = http
      self.tries = 0
      self.holdoff = holdoff
    end

    attr_reader :url, :error

    def exists?
      @_exists ||= http.head(url, follow_redirect: true).ok?
    rescue SocketError, HTTPClient::ConnectTimeoutError, Errno::ETIMEDOUT => e
      self.tries += 1
      if tries < 5
        sleep holdoff
        retry
      else
        self.error = e
        @_exists = true
      end
    rescue HTTPClient::BadResponseError => e
      self.error = e
      @_exists = true
    end

    protected

    attr_accessor :http, :tries, :holdoff
    attr_writer :url, :error
  end
end
