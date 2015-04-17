require 'httpclient'
require 'sitemap_check/page'
require 'nokogiri'
require 'colorize'

class SitemapCheck
  class Sitemap
    def initialize(url)
      self.url = url
      self.checked = 0
      setup_doc
    end

    attr_accessor :doc, :url, :checked

    def sitemaps
      maps.map do |sitemap|
        map = Sitemap.new(sitemap.loc.text)
        [self, map] + map.sitemaps
      end.flatten.uniq(&:url)
    end

    def missing_pages
      @_misssing ||= find_missing_pages
    end

    def exists? # rubocop:disable Style/TrivialAccessors
      @ok
    end

    private

    def http
      @_http ||= HTTPClient.new
    end

    def concurency
      ENV.fetch('CONCURENCY', 10)
    end

    def find_missing_pages
      q = Queue.new
      mutex = Mutex.new
      pages.each { |page| q.push page }
      concurency.times.map do
        Thread.new do
          begin
            while page = q.pop(true)
              unless page.exists?
                puts "  missing: #{page.url}".red
                page
              end
              mutex.synchronize { self.checked +=1 }
            end
          rescue ThreadError
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
