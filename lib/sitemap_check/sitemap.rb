require 'httpclient'
require 'sitemap_check/page'
require 'nokogiri'
require 'colorize'

class SitemapCheck
  class Sitemap
    def initialize(url, http = HTTPClient.new)
      self.url = url
      self.checked = 0
      self.http = http
      setup_doc
    end

    attr_reader :url, :checked

    def sitemaps
      expanded_sitemaps = maps.map do |sitemap|
        map = Sitemap.new(sitemap.loc.text, http)
        [map] + map.sitemaps
      end.flatten
      (expanded_sitemaps + [self]).uniq(&:url)
    end

    def missing_pages
      @_misssing ||= find_missing_pages
    end

    def exists? # rubocop:disable Style/TrivialAccessors
      @ok
    end

    protected

    attr_accessor :http, :doc
    attr_writer :url, :checked

    private

    def concurency
      ENV.fetch('CONCURRENCY', '10').to_i
    end

    def find_missing_pages # rubocop:disable Metrics/AbcSize
      q = Queue.new
      mutex = Mutex.new
      pages.each { |page| q.push page }
      concurency.times.map do
        Thread.new do
          begin
            while (page = q.pop(true))
              unless page.exists?
                puts "  missing: #{page.url}".red
                page
              end
              mutex.synchronize { self.checked += 1 }
            end
          rescue ThreadError # rubocop:disable Lint/HandleExceptions
          end
        end
      end.each(&:join)
      pages.reject(&:exists?)
    end

    def setup_doc
      response = http.get(url, follow_redirect: true)
      return unless (@ok = response.ok?)
      self.doc = Nokogiri::Slop(response.body)
      doc.remove_namespaces!
    rescue HTTPClient::BadResponseError
      @ok = false
    end

    def pages
      doc.urlset.url.map { |url| Page.new(url.loc.text, http) }
    rescue NoMethodError
      []
    end

    def maps
      doc.sitemapindex.sitemap
    rescue NoMethodError
      []
    end
  end
end
