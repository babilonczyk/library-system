namespace :reminders do
  desc "Send today's due reminders now, or those for DATE=2026-09-11"
  task sweep: :environment do
    on = ENV["DATE"] ? Date.parse(ENV["DATE"]) : Date.current
    sent = CirculationManagement::DispatchRemindersService.call(on: on)

    puts "#{on}: #{sent[:upcoming_due]} upcoming reminders, #{sent[:due_today]} due today"
  end
end
