require 'nokogiri'
require 'httpclient'

class Sitemap
  def initialize(url)
    self.url = url
    setup_doc
  end

  attr_accessor :doc, :url

  def sitemaps
    maps.map do |sitemap|
      map = Sitemap.new(sitemap.loc.text)
      [map] + map.sitemaps
    end.flatten.uniq(&:url)
  end

  def missing_pages
    @_misssing ||= page_urls.map do |page_url|
      unless page_exists?(page_url)
        puts "  missing: #{page_url}"
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
puts 'Expanding Sitemaps'
sitemaps = Sitemap.new(ENV['CHECK_URL']).sitemaps

sitemaps.reject(&:exists?).each do |sitemap|
  puts "#{sitemap.url} does not exist"
  exit_code = 1
end

puts ''

sitemaps.select(&:exists?).each do |sitemap|
  puts "Checking #{sitemap.url}"
  exit_code = 1 if sitemap.missing_pages.any?
  puts ''
end

exit exit_code
