require "typhoeus"
require "sitemap_check/logger"
require "colorize"

class SitemapCheck
  class Page
    def initialize(url, logger = Logger.new)
      self.url = url
      self.request = Typhoeus::Request.new(self.url, method: :head, followlocation: true)
      self.logger = logger
      setup_callbacks
    end

    attr_reader :url, :request, :exists, :error

    protected

    attr_writer :url, :request
    attr_accessor :logger

    def setup_callbacks # rubocop:disable Metrics/AbcSize
      request.on_complete do |response|
        if response.success?
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
  end
end
