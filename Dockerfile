# Development mode on purpose: the database is seeded on first boot, reminder
# mails are written to tmp/mails where they can be read, and the mailer
# previews are reachable. A production image would hide all three behind
# configuration this stack has no use for.
#
# Single stage. The image is a little larger for keeping the build tools, and
# the file stays short enough to read in one go.
FROM ruby:3.4.2-slim

# build-essential and libpq-dev compile the pg gem. libyaml-dev is needed by
# psych, which the slim image does not carry. curl is for the healthcheck the
# compose stack waits on.
RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y build-essential libpq-dev libyaml-dev curl && \
    rm -rf /var/lib/apt/lists/*

ENV RAILS_ENV=development \
    BUNDLE_PATH=/usr/local/bundle \
    BUNDLE_JOBS=4 \
    # Logs go to the container's output, where docker compose logs can find
    # them, rather than to a file nobody opens.
    RAILS_LOG_TO_STDOUT=true

WORKDIR /app

# Copied first, so a change to application code does not reinstall the gems.
COPY Gemfile Gemfile.lock ./
RUN bundle install && \
    rm -rf "${BUNDLE_PATH}"/ruby/*/cache

COPY . .

# Nothing here needs root, so nothing here runs as root.
RUN useradd --create-home --shell /bin/bash library && \
    chown -R library:library /app
USER library

EXPOSE 3000

ENTRYPOINT ["bin/docker-entrypoint"]
CMD ["bin/rails", "server", "-b", "0.0.0.0"]
