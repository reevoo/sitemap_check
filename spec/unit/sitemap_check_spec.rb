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

  let(:http) { double(:httpclient) }
  subject { described_class.new(nil, http) }


  context "happy path" do
    before do
      allow(http).to receive(:get)
        .with(sitemap_index_url, anything)
        .and_return(double(ok?: true, body: sitemap_index_xml))
      allow(http).to receive(:get).with(sitemap_1_url, anything).and_return(double(ok?: true, body: sitemap_1_xml))
      allow(http).to receive(:get).with(sitemap_2_url, anything).and_return(double(ok?: true, body: sitemap_2_xml))
      [kitten_url, more_kittens_url, puppy_url, more_puppies_url].each do |url|
        allow(http).to receive(:head).with(url, anything).and_return(double(ok?: true))
      end
    end

    context "index url in environment" do
      it "checks all the urls correctly" do
        output = capture_stdout do
          with_env("CHECK_URL" => sitemap_index_url) do
            expect { subject.check }.to raise_error { |e| expect(e).to be_success }
          end
        end

        expect(output).to include "Expanding Sitemaps from https://www.example.com/sitemap_index.xml"
        expect(output).to include "Checking https://www.example.com/kittens.xml"
        expect(output).to include "Checking https://www.example.com/puppies.xml"
        expect(output).to include "checked 2 pages and everything was ok"
      end
    end

    context "index url as param" do
      subject { described_class.new(sitemap_index_url, http) }

      it "checks all the urls correctly" do
        output = capture_stdout do
          expect { subject.check }.to raise_error { |e| expect(e).to be_success }
        end

        expect(output).to include "Expanding Sitemaps from https://www.example.com/sitemap_index.xml"
        expect(output).to include "Checking https://www.example.com/kittens.xml"
        expect(output).to include "Checking https://www.example.com/puppies.xml"
        expect(output).to include "checked 2 pages and everything was ok"
      end
    end
  end

  context "happy path with errors" do
    before do
      allow(http).to receive(:get)
        .with(sitemap_index_url, anything)
        .and_return(double(ok?: true, body: sitemap_index_xml))
      allow(http).to receive(:get).with(sitemap_1_url, anything).and_return(double(ok?: true, body: sitemap_1_xml))
      allow(http).to receive(:get).with(sitemap_2_url, anything).and_return(double(ok?: true, body: sitemap_2_xml))
      [kitten_url, puppy_url, more_puppies_url].each do |url|
        allow(http).to receive(:head).with(url, anything).and_return(double(ok?: true))
      end
      allow(http).to receive(:head).with(more_kittens_url, anything).and_raise(HTTPClient::BadResponseError, "timeout")
    end

    it "checks all the urls correctly" do
      output = capture_stdout do
        with_env("CHECK_URL" => sitemap_index_url) do
          expect { subject.check }.to raise_error { |e| expect(e).to be_success }
        end
      end

      expect(output).to include "Expanding Sitemaps from https://www.example.com/sitemap_index.xml"
      expect(output).to include "Checking https://www.example.com/kittens.xml"
      expect(output).to include "warning: error connecting to http://example.com/more_kittens"
      expect(output).to include "Checking https://www.example.com/puppies.xml"
      expect(output).to include "checked 2 pages and everything was ok"
    end
  end

  context "unhappy path" do
    before do
      allow(http).to receive(:get)
        .with(sitemap_index_url, anything)
        .and_return(double(ok?: true, body: sitemap_index_xml))
      allow(http).to receive(:get).with(sitemap_1_url, anything).and_return(double(ok?: true, body: sitemap_1_xml))
      allow(http).to receive(:get).with(sitemap_2_url, anything).and_return(double(ok?: false))
      allow(http).to receive(:head).with(kitten_url, anything).and_return(double(ok?: true))
      allow(http).to receive(:head).with(more_kittens_url, anything).and_return(double(ok?: false))
    end

    it "checks all the urls correctly" do
      output = capture_stdout do
        with_env("CHECK_URL" => sitemap_index_url) do
          expect { subject.check }.to raise_error { |e| expect(e).to_not be_success }
        end
      end

      expect(output).to include "Expanding Sitemaps from https://www.example.com/sitemap_index.xml"
      expect(output).to include "https://www.example.com/puppies.xml does not exist"
      expect(output).to include "Checking https://www.example.com/kittens.xml"
      expect(output).to include "missing: http://example.com/more_kittens"
      expect(output).to include "checked 2 pages and 1 were missing"
    end
  end
end
