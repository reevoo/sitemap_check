require 'nokogiri'
require 'httpclient'
require 'colorize'

class Sitemap
  def initialize(url)
    self.url = url
    setup_doc
    self.checked = 0
  end

  attr_accessor :doc, :url, :checked

  def sitemaps
    maps.map do |sitemap|
      map = Sitemap.new(sitemap.loc.text)
      [map] + map.sitemaps
    end.flatten.uniq(&:url)
  end

  def missing_pages
    @_misssing ||= page_urls.map do |page_url|
      self.checked += 1
      unless page_exists?(page_url)
        puts "  missing: #{page_url}".red
        page_url
      end
    end.compact
  end

  def exists? # rubocop:disable Style/TrivialAccessors
    @ok
  end

  private

  def page_exists?(page_url)
    tries = 0
    http = HTTPClient.new
    http.get(page_url, follow_redirect: true).ok?
  rescue SocketError, HTTPClient::ConnectTimeoutError
    tries += 1
    if tries < 5
      sleep 1
      retry
    else
      false
    end
  rescue HTTPClient::BadResponseError
    false
  end

  def setup_doc
    http = HTTPClient.new
    response = http.get(url, follow_redirect: true)
    return unless (@ok = response.ok?)
    self.doc = Nokogiri::Slop(response.body)
    doc.remove_namespaces!
  rescue HTTPClient::BadResponseError
    @ok = false
  end

  def page_urls
    doc.urlset.url.map { |url| url.loc.text }
  rescue NoMethodError
    []
  end

  def maps
    doc.sitemapindex.sitemap
  rescue NoMethodError
    []
  end
end

$stdout.sync = true
exit_code = 0
puts "Expanding Sitemaps from #{ENV['CHECK_URL']}"
sitemaps = Sitemap.new(ENV['CHECK_URL']).sitemaps

sitemaps.reject(&:exists?).each do |sitemap|
  puts "#{sitemap.url} does not exist".red.bold
  exit_code = 1
end

puts ''

sitemaps.select(&:exists?).each do |sitemap|
  puts "Checking #{sitemap.url}"
  if sitemap.missing_pages.any?
    exit_code = 1
    puts "checked #{sitemap.checked} pages and #{sitemap.missing_pages.count} were missing".red.bold
  else
    if sitemap.checked > 0
      puts "checked #{sitemap.checked} pages and everything was ok".green.bold
    else
      puts "this sitemap did not contain any pages".green
    end
  end
  puts ''
end

exit exit_code
