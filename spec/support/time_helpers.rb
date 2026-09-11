# Anything touching dates freezes time. The reminder specs are entirely
# time travel, so these are included everywhere rather than per file.
RSpec.configure do |config|
  config.include ActiveSupport::Testing::TimeHelpers
end
