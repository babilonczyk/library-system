# Counts the queries a block actually issues, so an N plus one guard can assert
# the count stays flat as the number of records grows, rather than trusting that
# someone remembered to write includes.
module QueryCounter
  IGNORED_NAMES = [ "SCHEMA", "TRANSACTION" ].freeze
  IGNORED_SQL = /\A\s*(SAVEPOINT|RELEASE SAVEPOINT|ROLLBACK|BEGIN|COMMIT)/i

  def count_queries(&block)
    count = 0

    counter = lambda do |_name, _started, _finished, _id, payload|
      next if IGNORED_NAMES.include?(payload[:name])
      next if payload[:sql].match?(IGNORED_SQL)

      count += 1
    end

    ActiveSupport::Notifications.subscribed(counter, "sql.active_record", &block)

    count
  end
end

RSpec.configure do |config|
  config.include QueryCounter
end
