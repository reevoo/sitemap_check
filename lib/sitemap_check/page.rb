require "typhoeus"
require "sitemap_check/logger"
require "sitemap_check/validator"
require "colorize"
require "uri"

class SitemapCheck
  class Page
    def initialize(url, logger = Logger.new)
      self.uri = URI(url)
      self.logger = logger

      replace_host

      self.request = Typhoeus::Request.new(
        self.url,
        method: request_method,
        followlocation: true,
      )

      setup_callbacks
    end

    attr_reader :request, :exists, :error

    def url
      uri.to_s
    end

    protected

    attr_writer :uri, :request
    attr_accessor :logger, :uri

    def replace_host
      return unless (host = ENV["REPLACEMENT_HOST"])
      uri.host = host
    end

    def setup_callbacks # rubocop:disable Metrics/AbcSize
      request.on_complete do |response|
        if response.success?
          validate(response)
          @exists = true
        elsif response.timed_out?
          @exists = true
          logger.log "  warning: request to #{url} timed out".magenta
        elsif response.code == 404
          @exists = false
          logger.log "  missing: #{url}".magenta
        else
          @error = true
          logger.log "  error: (#{response.code}) while connecting to #{url}".magenta
        end
      end
    end

    def request_method
      validate? ? :get : :head
    end

    def validate(response)
      Validator.new(response, logger).validate if validate?
    end

    def validate?
      ENV["VALIDATE"]
    end
  end
end
