require "simplecov"

# Coverage has to start before the application is loaded, or everything
# required at boot is missed. No minimum_coverage: a threshold invites tests
# written to satisfy the number rather than the behaviour.
SimpleCov.start "rails" do
  enable_coverage :branch
end

RSpec.configure do |config|
  config.expect_with :rspec do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end

  config.shared_context_metadata_behavior = :apply_to_host_groups

  config.disable_monkey_patching!
  config.filter_run_when_matching :focus
  config.example_status_persistence_file_path = "tmp/rspec_examples.txt"

  # Random order, with the seed printed so any failure can be reproduced.
  config.order = :random
  Kernel.srand config.seed
end
