# frozen_string_literal: true
require "w3c_validators"

class SitemapCheck
  class Validator
    LIMIT = 100

    attr_accessor :logger, :response

    class << self
      attr_accessor :message_count
    end

    def initialize(response, logger = Logger.new)
      self.logger = logger
      self.response = response
      self.class.message_count ||= 0
    end

    def validate
      validator = W3CValidators::NuValidator.new
      result = validator.validate_text(response.body)
      return if result.errors.empty? && result.warnings.empty?

      log_url
      log_errors(result)
      log_warnings(result)
      fail_if_too_many_messages
    end

    private

    def log_url
      logger.log "-" * 80
      logger.log response.effective_url.cyan
    end

    def log_errors(result)
      result.errors.each do |e|
        logger.log "  ERROR: #{e.message}".red
        logger.log "         #{e.source.inspect}"

        self.class.message_count += 1
      end
    end

    def log_warnings(result)
      result.warnings.each do |w|
        logger.log "  WARNING: #{w.message}".yellow
        logger.log "           #{w.source.inspect}"

        self.class.message_count += 1
      end
    end

    def fail_if_too_many_messages
      error = "Stopping because there are more than #{LIMIT} messages."
      fail error if self.class.message_count > LIMIT
    end
  end
end
