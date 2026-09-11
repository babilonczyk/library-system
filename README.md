# Library System

A Rails API for library staff to manage books, borrowing and returns, with
automated return reminders.

## Reminder Mails Templates

Two emails: one for a book due in three days, one for a book due today. Both
are sent as multipart, with a plain text part and an HTML part.

Preview them in a browser:

```sh
bin/rails server
```

Open `/rails/mailers` and pick a reminder. Each one renders with a switcher
between its HTML and text parts.

Reminders sent in development are written to `tmp/mails` as `.eml` files, one
per recipient, appended to on each send.

## Gems

Everything added beyond a stock `rails new --api`, and why.

| Gem                 |                                                                                                    |
| ------------------- | -------------------------------------------------------------------------------------------------- |
| `pg`                | Plan is to use PostgreSQL db                                                                       |
| `alba`              | Serialization stays explicit and out of the models, didn't go with jsonapi standard for simplicity |
| `oj`                | JSON backend Alba supports                                                                         |
| `sidekiq`           | Retries and monitoring come built in                                                               |
| `sidekiq-cron`      | Scheduling without a second process or system cron                                                 |
| `pagy`              | Smallest and fastest of the pagination gems                                                        |
| `rspec-rails`       | Test library                                                                                       |
| `factory_bot_rails` | Named, composable states rather than fixtures                                                      |
| `faker`             |
| `shoulda-matchers`  | One line per validation instead of hand-rolled assertions                                          |
| `simplecov`         | Shows what the suite misses                                                                        |

Retained from the generator: `puma`, `bootsnap`, `debug`, `tzinfo-data`,
`brakeman`, `bundler-audit` and `rubocop-rails-omakase`.
