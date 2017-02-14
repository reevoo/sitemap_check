require "spec_helper"
require "sitemap_check/page"

describe SitemapCheck::Page do
  let(:httpclient) { double }
  let(:url) { "https://example.com/foo.html" }
  subject { described_class.new(url, httpclient, 0) }

  describe "#url" do
    specify { expect(subject.url).to eq url }
  end

  describe "#exists?" do
    context "the url is ok" do
      before do
        response = double(ok?: true)
        allow(httpclient).to receive(:head).with(url, anything).and_return(response)
      end

      specify { expect(subject.exists?).to be_truthy }
    end

    context "the url is not ok" do
      before do
        response = double(ok?: false)
        allow(httpclient).to receive(:head).with(url, anything).and_return(response)
      end

      specify { expect(subject.exists?).to be_falsey }
    end

    context "on a SocketError" do
      it "tries 5 times then returns true and saves the error" do
        expect(httpclient).to receive(:head).exactly(5).times.and_raise(SocketError)
        expect(subject.exists?).to be_truthy
        expect(subject.error).to be_a SocketError
      end
    end

    context "on a ConnectTimeoutError" do
      it "tries 5 times then returns false" do
        expect(httpclient).to receive(:head).exactly(5).times.and_raise(HTTPClient::ConnectTimeoutError)
        expect(subject.exists?).to be_truthy
        expect(subject.error).to be_a HTTPClient::ConnectTimeoutError
      end
    end

    context "on a Errno::ETIMEDOUT" do
      it "tries 5 times then returns false" do
        expect(httpclient).to receive(:head).exactly(5).times.and_raise(Errno::ETIMEDOUT)
        expect(subject.exists?).to be_truthy
        expect(subject.error).to be_a Errno::ETIMEDOUT
      end
    end

    context "on a HTTPClient::BadResponseError" do
      it "tries 5 times then returns false" do
        expect(httpclient).to receive(:head).exactly(1).times.and_raise(HTTPClient::BadResponseError, "bad response")
        expect(subject.exists?).to be_truthy
        expect(subject.error).to be_a HTTPClient::BadResponseError
      end
    end
  end
end
