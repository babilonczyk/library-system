require "rails_helper"

# Zeitwerk cannot verify the preview directory, since eager loading spec files
# would be wrong. This does the same job better: it renders every preview, so a
# preview that has drifted from its mailer fails here rather than in a browser.
RSpec.describe "Mailer previews" do
  it "all render" do
    create(:loan)

    aggregate_failures do
      ActionMailer::Preview.all.each do |preview|
        preview.emails.each do |email|
          expect { preview.call(email) }.not_to raise_error, "#{preview.name}##{email} failed to render"
        end
      end
    end
  end

  it "covers both reminders" do
    expect(ReminderMailerPreview.emails).to contain_exactly("upcoming_due", "due_today")
  end
end
