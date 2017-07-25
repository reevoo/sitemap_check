# frozen_string_literal: true
require "spec_helper"
require "sitemap_check/page"

describe SitemapCheck::Page do
  let(:url) { "https://example.com/foo.html" }
  subject { described_class.new(url) }

  describe "#url" do
    specify { expect(subject.url).to eq url }

    context "with a replacement host" do
      it "uses the replacement host" do
        with_env("REPLACEMENT_HOST" => "staging.reevoo.com") do
          expect(subject.url).to eq "https://staging.reevoo.com/foo.html"
        end
      end
    end
  end

  describe "checking a page" do
    let(:output) { capture_stdout { subject.request.run } }

    context "the url is ok" do
      before do
        Typhoeus.stub(url).and_return(Typhoeus::Response.new(code: 200))
        output
      end

      specify { expect(subject.exists).to be_truthy }
    end

    context "the url is not ok" do
      before do
        Typhoeus.stub(url).and_return(Typhoeus::Response.new(code: 404))
        output
      end

      specify { expect(subject.exists).to be_falsey }
      specify { expect(subject.error).to be_falsey }

      it "logs an error" do
        expect(output).to include "missing: #{url}"
      end
    end

    context "the request timed out" do
      before do
        response = Typhoeus::Response.new
        allow(response).to receive(:timed_out?).and_return(true)
        Typhoeus.stub(url).and_return(response)
        output
      end

      specify { expect(subject.exists).to be_truthy }
      specify { expect(subject.error).to be_falsey }

      it "logs an error" do
        expect(output).to include "warning: request to #{url} timed out"
      end
    end
  end
end
