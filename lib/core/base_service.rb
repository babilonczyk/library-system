module Core
  # Every service in the application inherits from this.
  #
  # Services take keyword arguments only. Forwarding just `**arguments` makes
  # that structural rather than a convention: a positional argument fails at
  # the call site with an ArgumentError instead of quietly working.
  class BaseService
    def self.call(**arguments)
      new(**arguments).call
    end

    def call
      raise NotImplementedError, "#{self.class.name} must implement #call"
    end
  end
end
