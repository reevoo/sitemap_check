require "spec_helper"
require "sitemap_check/sitemap"

describe SitemapCheck::Sitemap do
  let(:http) { double }
  let(:url) { "http://example.com/sitemap.xml" }
  let(:response) { double(:response) }
  subject { described_class.new(url, http) }

  before do
    allow(http).to receive(:get).and_return(double(ok?: false))
    allow(http).to receive(:get).with(url, anything).and_return(response)
  end

  describe "#exists?" do
    context "when the sitemap cannot be found" do
      let(:response) { double(:response, ok?: false, body: "") }

      specify { expect(subject.exists?).to be_falsey }
    end

    context "when the request for the sitemap throws a HTTPClient::BadResponseError" do
      before do
        allow(http).to receive(:get).and_raise(HTTPClient::BadResponseError, "bad response")
      end

      specify { expect(subject.exists?).to be_falsey }
    end

    context "when the sitemap is found" do
      let(:response) { double(:response, ok?: true, body: "") }

      specify { expect(subject.exists?).to be_truthy }
    end
  end

  describe "#sitemaps" do
    context "simple sitemap" do
      let(:response) { double(:response, ok?: true, body: "") }

      it "returns an array containing subject" do
        expect(subject.sitemaps).to eq([subject])
      end
    end

    context "a sitemap index" do
      before do
      end

      let(:url) { "http://example.com/sitemap_index.xml" }
      let(:response) { double(:response, ok?: true, body: xml) }
      let(:xml) do
        '
        <sitemapindex xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">
          <sitemap>
            <loc>http://www.example.com/sitemap.xml</loc>
          </sitemap>
          <sitemap>
            <loc>http://www.example.com/sitemap2.xml</loc>
          </sitemap>
        </sitemapindex>
        '
      end

      it "returns an array containing all the sitemaps" do
        expect(subject.sitemaps.map(&:url)).to eq([
          "http://www.example.com/sitemap.xml",
          "http://www.example.com/sitemap2.xml",
          url,
        ])
      end
    end
  end

  describe "#missing_pages" do
    let(:missing_page_1) { double(:missing_page, exists?: false, error: nil, url: "missing_page_1") }
    let(:missing_page_2) { double(:missing_page, exists?: false, error: nil, url: "missing_page_2") }
    let(:error_page)     { double(:error_page, exists?: true, error: true, url: "error_page") }
    let(:good_page)      { double(:good_page, exists?: true, error: nil) }
    let(:response)       { double(:response, ok?: true, body: xml) }
    let(:xml) do
      '
        <urlset>
          <url>
            <loc>good_page</loc>
          </url>
          <url>
            <loc>missing_page_1</loc>
          </url>
          <url>
            <loc>good_page</loc>
          </url>
          <url>
            <loc>missing_page_2</loc>
          </url>
          <url>
            <loc>error_page</loc>
          </url>
        </urlset>
      '
    end

    before do
      allow(SitemapCheck::Page).to receive(:new).with("missing_page_1", anything).and_return(missing_page_1)
      allow(SitemapCheck::Page).to receive(:new).with("missing_page_2", anything).and_return(missing_page_2)
      allow(SitemapCheck::Page).to receive(:new).with("error_page", anything).and_return(error_page)
      allow(SitemapCheck::Page).to receive(:new).with("good_page", anything).and_return(good_page)
    end

    it "only returns the pages that dont exist" do
      capture_stdout do
        expect(subject.missing_pages).to eq([missing_page_1, missing_page_2])
      end
    end

    describe "#errored_page" do
      it "returns the pages that returned an error" do
        capture_stdout do
          expect(subject.errored_pages).to eq([error_page])
        end
      end
    end

    context "with CONCURRENCY set" do
      it "still works" do
        with_env("CONCURRENCY" => "2") do
          capture_stdout do
            expect(subject.missing_pages).to eq([missing_page_1, missing_page_2])
          end
        end
      end
    end

    it "outputs messages about the missing and errored pages to stout" do
      output = capture_stdout do
        subject.missing_pages
      end

      expect(output).to include "missing: missing_page_1"
      expect(output).to include "warning: error connecting to error_page"
      expect(output).to include "missing: missing_page_2"
    end

    context "when there are no pages" do
      let(:xml) { "" }

      specify { expect(subject.missing_pages).to be_empty }
    end
  end
end
