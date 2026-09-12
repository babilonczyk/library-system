# Library System

A Rails API for library staff to manage books, borrowing and returns, with
automated return reminders.

## Running It

```sh
docker compose up
```

That is the whole setup. Four services come up in order: PostgreSQL and Redis
first, then the API once they are healthy, then the Sidekiq worker once the API
has prepared the database. The catalogue is created and seeded on first boot, so
there is something to read straight away.

The API is on `http://localhost:3000`. If something already holds that port,
move it:

```sh
PORT=3003 docker compose up
```

Database contents survive `docker compose down`. To start over from an empty
catalogue, remove the volume with `docker compose down -v`.

## The API

The full contract is `openapi.yaml` in the repository root. It is also browsable
at `/api-docs`, which renders it with Swagger UI.

| Method | Path | What it does |
| --- | --- | --- |
| GET | `/api/v1/books` | The catalogue, filterable by availability |
| POST | `/api/v1/books` | Add a book |
| GET | `/api/v1/books/:id` | One book with its full borrowing history |
| DELETE | `/api/v1/books/:id` | Remove a book from the catalogue |
| POST | `/api/v1/books/:id/borrow` | Lend it to a reader |
| POST | `/api/v1/books/:id/return` | Take it back |
| GET | `/api/v1/readers` | The readers |
| POST | `/api/v1/readers` | Register a reader |

Successful responses are wrapped in `data`, with `meta` alongside on lists.
Failures are a list of `errors`, each with a machine-readable `code`, a
human-readable `detail`, and `source` naming the field at fault where there is
one.

## Background Jobs

Reminders go out on a schedule, so the app needs Redis and a Sidekiq process
next to the web server. The compose stack starts both. Outside it:

```sh
redis-server
bundle exec sidekiq
```

The sweep runs daily at 07:00 UTC. It mails every reader whose book falls due
in three days, and every reader whose book is due that day. Each reminder is
stamped on the loan as it is sent, so a second run the same day sends nothing.

To see it work without waiting for the schedule:

```sh
docker compose exec web bin/rails reminders:sweep
docker compose exec web bin/rails reminders:sweep DATE=2026-09-14
```

The mails land as `.eml` files inside the worker, one per reader:

```sh
docker compose exec worker ls tmp/mails
```

The seeds leave one loan in each reminder state, so the first sweep on a fresh
database sends two mails.

Open `/sidekiq` for the dashboard: queues, retries, and a Cron tab showing the
schedule and when it last ran. It has no authentication, which is fine for a
local stack and would not be in production.

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
