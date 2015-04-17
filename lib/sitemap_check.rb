require 'colorize'
require 'sitemap_check/sitemap'

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
end
