require "rails_helper"

RSpec.describe ReminderMailer do
  let(:reader) { create(:reader, name: "Ada Lovelace", email: "ada@example.com") }
  let(:book) { create(:book, title: "Solaris", author: "Stanisław Lem") }
  let(:loan) do
    create(:loan, book: book, reader: reader,
                  borrowed_on: Date.new(2026, 9, 7), due_on: Date.new(2026, 10, 7))
  end

  describe "#upcoming_due" do
    subject(:mail) { described_class.with(loan: loan).upcoming_due }

    it "writes to the reader who has the book" do
      aggregate_failures do
        expect(mail.to).to eq([ "ada@example.com" ])
        expect(mail.from).to eq([ "library@example.com" ])
      end
    end

    it "names the book and the due date in the subject" do
      expect(mail.subject).to eq("Solaris is due back on October 07, 2026")
    end

    it "tells the reader everything they need in the text part" do
      text = mail.parts.first.body.to_s

      aggregate_failures do
        expect(text).to include("Dear Ada Lovelace")
        expect(text).to include("Solaris")
        expect(text).to include("Stanisław Lem")
        expect(text).to include("October 07, 2026")
      end
    end

    it "carries both a text and an HTML part, text first" do
      aggregate_failures do
        expect(mail.mime_type).to eq("multipart/alternative")
        expect(mail.parts.map(&:mime_type)).to eq([ "text/plain", "text/html" ])
      end
    end

    it "says the same thing in both parts" do
      aggregate_failures do
        mail.parts.each do |part|
          expect(part.body.to_s).to include("Ada Lovelace")
          expect(part.body.to_s).to include("Solaris")
          expect(part.body.to_s).to include("Stanis\u0142aw Lem")
          expect(part.body.to_s).to include("October 07, 2026")
        end
      end
    end
  end

  describe "#due_today" do
    subject(:mail) { described_class.with(loan: loan).due_today }

    it "says the book is due today rather than giving a future date" do
      aggregate_failures do
        expect(mail.subject).to eq("Solaris is due back today")
        mail.parts.each { |part| expect(part.body.to_s).to include("due back today") }
      end
    end

    it "still names the book and the reader, in both parts" do
      aggregate_failures do
        expect(mail.to).to eq([ "ada@example.com" ])
        mail.parts.each do |part|
          expect(part.body.to_s).to include("Ada Lovelace")
          expect(part.body.to_s).to include("Solaris")
        end
      end
    end
  end
end
