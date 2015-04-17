require 'httpclient'

class SitemapCheck
  class Page
    def initialize(url, client = HTTPClient.new)
      self.url = url
      self.http = http
    end

    attr_reader :url

    def exists?
      tries = 0
      @_exists ||= http.head(url, follow_redirect: true).ok?
    rescue SocketError, HTTPClient::ConnectTimeoutError
      tries += 1
      if tries < 5
        sleep 1
        retry
      else
        @_exists = false
      end
    rescue HTTPClient::BadResponseError
      @_exists = false
    end

    protected

    attr_accessor :http
    attr_writer :url
  end
end
