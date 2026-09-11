require "rails_helper"

# Runs every factory and every trait. Without this a factory rots quietly as the
# schema moves, and the failure surfaces later in some unrelated spec.
RSpec.describe "Factories" do
  it "all produce valid records" do
    FactoryBot.lint(traits: true)
  end
end
