require "spec_helper"
require "sitemap_check/sitemap"

describe SitemapCheck::Sitemap do
  let(:http) { double }
  let(:url) { "http://example.com/sitemap.xml" }
  let(:response) { Typhoeus::Response.new }
  subject { described_class.new(url) }

  before do
    Typhoeus.stub(url).and_return(response)
  end

  describe "#exists?" do
    context "when the sitemap cannot be found" do
      let(:response) { Typhoeus::Response.new(code: 404) }

      specify { expect(subject.exists?).to be_falsey }
    end

    context "when the sitemap is found" do
      let(:response) { Typhoeus::Response.new(code: 200, body: "") }

      specify { expect(subject.exists?).to be_truthy }
    end
  end

  describe "#sitemaps" do
    context "simple sitemap" do
      let(:response) { Typhoeus::Response.new(code: 200, body: "") }

      it "returns an array containing subject" do
        expect(subject.sitemaps).to eq([subject])
      end
    end

    context "a sitemap index" do
      before do
      end

      let(:url) { "http://example.com/sitemap_index.xml" }
      let(:response) { Typhoeus::Response.new(code: 200, body: xml) }
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
    let(:response)       { Typhoeus::Response.new(code: 200, body: xml) }
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
      Typhoeus.stub("good_page").and_return(Typhoeus::Response.new(code: 200))
      Typhoeus.stub("missing_page_1").and_return(Typhoeus::Response.new(code: 404))
      Typhoeus.stub("missing_page_2").and_return(Typhoeus::Response.new(code: 404))
      Typhoeus.stub("error_page").and_return(Typhoeus::Response.new(code: 500))
      capture_stdout { subject.check_pages }
    end

    it "only returns the pages that dont exist" do
      expect(subject.missing_pages.count).to eq 3
      expect(subject.missing_pages.map(&:url)).to eq(%w(missing_page_1 missing_page_2 error_page))
    end

    describe "#errored_page" do
      it "returns the pages that returned an error" do
        expect(subject.errored_pages.count).to eq 1
        expect(subject.errored_pages.map(&:url)).to eq(%w(error_page))
      end
    end

    context "with CONCURRENCY set" do
      it "still works" do
        with_env("CONCURRENCY" => "2") do
          expect(subject.missing_pages.count).to eq 3
          expect(subject.missing_pages.map(&:url)).to eq(%w(missing_page_1 missing_page_2 error_page))
        end
      end
    end

    context "when there are no pages" do
      let(:xml) { "" }

      specify { expect(subject.missing_pages).to be_empty }
    end
  end
end
