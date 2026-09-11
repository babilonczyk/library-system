module CirculationManagement
  module Jobs
    # A thin wrapper. The sweep itself is the service's job; this exists so
    # Sidekiq has something to schedule and something to retry.
    #
    # The date is an argument rather than read inside, so a missed day can be
    # swept by hand without pretending it is that day.
    class ReminderSweepJob < ApplicationJob
      queue_as :reminders

      def perform(on = Date.current)
        sent = DispatchRemindersService.call(on: on.to_date)

        logger.info("Reminders sent on #{on}: " \
                    "#{sent[:upcoming_due]} upcoming, #{sent[:due_today]} due today")

        sent
      end
    end
  end
end
