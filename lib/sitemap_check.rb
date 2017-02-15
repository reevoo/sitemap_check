require "colorize"
require "sitemap_check/sitemap"
require "sitemap_check/version"

class SitemapCheck


  def self.check(url)
    $stdout.sync = true
    new(url).check
  end

  def initialize(check_url)
    self.start_time = Time.now
    self.exit_code = 0
    check_url = check_url
    puts "Expanding Sitemaps from #{check_url}"
    self.sitemaps = Sitemap.new(check_url).sitemaps
    Typhoeus::Config.user_agent = "SitemapCheckbot/#{VERSION} (+https://github.com/reevoo/sitemap_check)"
  end

  def check
    check_indexes
    check_pages
    stats
    exit exit_code
  end

  protected

  attr_accessor :sitemaps, :exit_code, :start_time, :logger

  private

  def stats
    puts "checked #{sitemaps.count} sitemaps and #{checked_pages} pages in #{time_taken} seconds"
    puts "thats #{pages_per_second} pages per second"
  end

  def pages_per_second
    checked_pages / time_taken
  end

  def time_taken
    Time.now - start_time
  end

  def checked_pages
    sitemaps.map(&:checked).reduce(&:+)
  end

  def check_indexes
    sitemaps.reject(&:exists?).each do |sitemap|
      puts "  #{sitemap.url} does not exist".red.bold
      self.exit_code = 1
    end
    puts ""
  end

  def good_sitemaps
    sitemaps.select(&:exists?)
  end

  def check_pages
    good_sitemaps.each { |sitemap| check_pages_in(sitemap) }
  end

  def check_pages_in(sitemap)
    puts "Checking #{sitemap.url}"
    sitemap.check_pages
    if sitemap.missing_pages.any?
      missing_pages(sitemap)
    else
      if sitemap.checked > 0
        a_ok(sitemap)
      else
        nothing_doing
      end
    end
    puts ""
  end

  def missing_pages(sitemap)
    self.exit_code = 1
    puts "  checked #{sitemap.checked} pages and #{sitemap.missing_pages.count} were missing".red.bold
  end

  def a_ok(sitemap)
    puts "  checked #{sitemap.checked} pages and everything was ok".green.bold
  end

  def nothing_doing
    puts "  this sitemap did not contain any pages".green
  end
end
