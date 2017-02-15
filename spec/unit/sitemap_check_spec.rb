require "spec_helper"
require "sitemap_check"

describe SitemapCheck do
  it "has a version number" do
    expect(SitemapCheck::VERSION).not_to be nil
  end

  let(:sitemap_index_url) { "https://www.example.com/sitemap_index.xml" }
  let(:sitemap_1_url) { "https://www.example.com/kittens.xml" }
  let(:sitemap_2_url) { "https://www.example.com/puppies.xml" }

  let(:sitemap_index_xml) do
    "
        <sitemapindex>
          <sitemap>
            <loc>#{sitemap_1_url}</loc>
          </sitemap>
          <sitemap>
            <loc>#{sitemap_2_url}</loc>
          </sitemap>
        </sitemapindex>
    "
  end

  let(:sitemap_1_xml) do
    "
        <urlset>
          <url>
            <loc>#{kitten_url}</loc>
          </url>
          <url>
            <loc>#{more_kittens_url}</loc>
          </url>
        </urlset>
    "
  end

  let(:sitemap_2_xml) do
    "
        <urlset>
          <url>
            <loc>#{puppy_url}</loc>
          </url>
          <url>
            <loc>#{more_puppies_url}</loc>
          </url>
        </urlset>
    "
  end

  let(:kitten_url) { "http://example.com/kittens" }
  let(:more_kittens_url) { "http://example.com/more_kittens" }
  let(:puppy_url) { "http://example.com/puppies" }
  let(:more_puppies_url) { "http://example.com/more_puppies" }

  context "happy path" do
    before do
      Typhoeus.stub(sitemap_index_url).and_return(Typhoeus::Response.new(code: 200, body: sitemap_index_xml))
      Typhoeus.stub(sitemap_1_url).and_return(Typhoeus::Response.new(code: 200, body: sitemap_1_xml))
      Typhoeus.stub(sitemap_2_url).and_return(Typhoeus::Response.new(code: 200, body: sitemap_2_xml))
      [kitten_url, more_kittens_url, puppy_url, more_puppies_url].each do |url|
        Typhoeus.stub(url).and_return(Typhoeus::Response.new(code: 200))
      end
    end

    it "checks all the urls correctly" do
      output = capture_stdout do
        expect { described_class.check(sitemap_index_url) }.to raise_error { |e| expect(e).to be_success }
      end

      expect(output).to include "Expanding Sitemaps from https://www.example.com/sitemap_index.xml"
      expect(output).to include "Checking https://www.example.com/kittens.xml"
      expect(output).to include "Checking https://www.example.com/puppies.xml"
      expect(output).to include "checked 2 pages and everything was ok"
    end
  end

  context "happy path with errors" do
    before do
      Typhoeus.stub(sitemap_index_url).and_return(Typhoeus::Response.new(code: 200, body: sitemap_index_xml))
      Typhoeus.stub(sitemap_1_url).and_return(Typhoeus::Response.new(code: 200, body: sitemap_1_xml))
      Typhoeus.stub(sitemap_2_url).and_return(Typhoeus::Response.new(code: 200, body: sitemap_2_xml))
      [kitten_url, puppy_url, more_puppies_url].each do |url|
        Typhoeus.stub(url).and_return(Typhoeus::Response.new(code: 200))
      end
      response = Typhoeus::Response.new
      allow(response).to receive(:timed_out?).and_return(true)
      Typhoeus.stub(more_kittens_url).and_return(response)
    end

    it "checks all the urls correctly" do
      output = capture_stdout do
        expect { described_class.check(sitemap_index_url) }.to raise_error { |e| expect(e).to be_success }
      end

      expect(output).to include "Expanding Sitemaps from https://www.example.com/sitemap_index.xml"
      expect(output).to include "Checking https://www.example.com/kittens.xml"
      expect(output).to include "warning: request to http://example.com/more_kittens timed out"
      expect(output).to include "Checking https://www.example.com/puppies.xml"
      expect(output).to include "checked 2 pages and everything was ok"
    end
  end

  context "unhappy path" do
    before do
      Typhoeus.stub(sitemap_index_url).and_return(Typhoeus::Response.new(code: 200, body: sitemap_index_xml))
      Typhoeus.stub(sitemap_1_url).and_return(Typhoeus::Response.new(code: 200, body: sitemap_1_xml))
      Typhoeus.stub(sitemap_2_url).and_return(Typhoeus::Response.new(code: 404))
      Typhoeus.stub(kitten_url).and_return(Typhoeus::Response.new(code: 200))
      Typhoeus.stub(more_kittens_url).and_return(Typhoeus::Response.new(code: 404))
    end

    it "checks all the urls correctly" do
      output = capture_stdout do
        expect { described_class.check(sitemap_index_url) }.to raise_error { |e| expect(e).to_not be_success }
      end

      expect(output).to include "Expanding Sitemaps from https://www.example.com/sitemap_index.xml"
      expect(output).to include "https://www.example.com/puppies.xml does not exist"
      expect(output).to include "Checking https://www.example.com/kittens.xml"
      expect(output).to include "missing: http://example.com/more_kittens"
      expect(output).to include "checked 2 pages and 1 were missing"
    end
  end
end
