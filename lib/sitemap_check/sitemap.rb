# frozen_string_literal: true
require "typhoeus"
require "sitemap_check/page"
require "sitemap_check/logger"
require "nokogiri"

class SitemapCheck
  class Sitemap
    def initialize(url, logger = Logger.new)
      self.logger = logger
      self.url = url
      self.checked = 0
      self.hydra = Typhoeus::Hydra.new(max_concurrency: concurency)
      setup_doc
    end

    attr_reader :url, :checked, :pages

    def check_pages
      queue_pages
      hydra.run
      self.checked = pages.count
    end

    def sitemaps
      expanded_sitemaps = maps.map do |sitemap|
        map = Sitemap.new(sitemap.loc.text)
        [map] + map.sitemaps
      end.flatten
      (expanded_sitemaps + [self]).uniq(&:url)
    end

    def missing_pages
      pages.reject(&:exists)
    end

    def errored_pages
      pages.select(&:error)
    end

    def exists?
      @ok
    end

    protected

    attr_accessor :hydra, :doc, :logger
    attr_writer :url, :checked

    private

    def concurency
      ENV.fetch("CONCURRENCY", "10").to_i
    end

    def queue_pages
      pages.each { |page| hydra.queue page.request }
    end

    def setup_doc
      response = Typhoeus.get(url, followlocation: true)
      return unless (@ok = response.success?)
      self.doc = Nokogiri::Slop(response.body)
      doc.remove_namespaces!
    end

    def pages
      @pages ||= doc.urlset.url.map { |url| Page.new(url.loc.text, logger) }
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
