require 'nokogiri'
require 'httpclient'
require 'colorize'
require 'thread'

class SitemapCheck

  def self.check
    $stdout.sync = true
    new.check
  end

  def initialize
    puts "Expanding Sitemaps from #{ENV['CHECK_URL']}"
    self.sitemaps = Sitemap.new(ENV['CHECK_URL']).sitemaps
  end

  def check
    check_indexes
    check_pages
    exit exit_code
  end

  protected

  attr_accessor :sitemaps, :exit_code

  private

  def check_indexes
    sitemaps.reject(&:exists?).each do |sitemap|
      puts "#{sitemap.url} does not exist".red.bold
      self.exit_code = 1
    end
    puts ''
  end

  def check_pages
    sitemaps.select(&:exists?).each do |sitemap|
      puts "Checking #{sitemap.url}"
      if sitemap.missing_pages.any?
        self.exit_code = 1
        puts "checked #{sitemap.checked} pages and #{sitemap.missing_pages.count} were missing".red.bold
      else
        if sitemap.checked > 0
          puts "checked #{sitemap.checked} pages and everything was ok".green.bold
        else
          puts 'this sitemap did not contain any pages'.green
        end
      end
      puts ''
    end
  end

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

  class Page
    def initialize(url, client = HTTPClient.new)
      self.url = url
      self.http = http
    end

    attr_accessor :url, :http

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
  end
end

SitemapCheck.check
