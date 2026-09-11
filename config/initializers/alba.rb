require "alba"

# Oj in Rails mode, so that Date, Time and ActiveSupport::TimeWithZone
# serialize the way the rest of Rails renders them. Strict mode raises on
# those types instead.
Alba.backend = :oj_rails

# Keys follow the same inflection rules as the rest of the application.
Alba.inflector = :active_support
