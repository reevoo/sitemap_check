# frozen_string_literal: true
require "spec_helper"
require "sitemap_check/sitemap"

describe SitemapCheck::Validator do
  let(:logger) { double(:logger) }
  let(:response) { double(:response, effective_url: "http://example.com", body: double(:body)) }
  let(:error) { double(:error, message: "error msg", source: "<foo>") }
  let(:warning) { double(:error, message: "warning msg", source: "<bar>") }

  let(:errors) { [] }
  let(:warnings) { [] }
  let(:messages) { [] }

  subject { described_class.new(response, logger) }

  before do
    allow_any_instance_of(W3CValidators::NuValidator)
      .to receive(:validate_text)
      .and_return(double(:result, errors: errors, warnings: warnings))

    allow(logger).to receive(:log) { |m| messages.push(m) }

    described_class.message_count = 0
  end

  context "when there are no errors or warnings" do
    it "doesn't log anything" do
      expect(logger).not_to receive(:log)
      subject.validate
    end
  end

  context "when there are errors" do
    let(:errors) { [error] }

    it "logs the URL, error and source" do
      subject.validate

      expect(messages.join).to include("http://example.com")
      expect(messages.join).to include("ERROR: error msg")
      expect(messages.join).to include("<foo>")
    end
  end

  context "when there are warnings" do
    let(:warnings) { [warning] }

    it "logs the URL, warning and source" do
      subject.validate

      expect(messages.join).to include("http://example.com")
      expect(messages.join).to include("WARNING: warning msg")
      expect(messages.join).to include("<bar>")
    end
  end

  context "when there are tonnes of messages" do
    let(:errors) { [error] * 50 }

    context "more than 100" do
      let(:warnings) { [warning] * 51 }

      it "raises an error and stops" do
        expect { subject.validate }
          .to raise_error(/more than 100 messages/)
      end
    end

    context "exactly 100" do
      let(:warnings) { [warning] * 50 }

      it "does not raise an error" do
        expect { subject.validate }
          .to_not raise_error
      end
    end

    context "the count of messages is over 100 across instances" do
      let(:errors) { [error] * 25 }
      let(:warnings) { [warning] * 26 }

      it "raises an error and stops" do
        subject.validate
        second_instance = described_class.new(response, logger)
        expect { second_instance.validate }
          .to raise_error(/more than 100 messages/)
      end
    end
  end
end
