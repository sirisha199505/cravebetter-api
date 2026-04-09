FROM ruby:3.4

RUN apt-get update && apt-get -y install --no-install-recommends libpq-dev gcc make && rm -rf /var/lib/apt/lists/*

WORKDIR /app

COPY Gemfile* .

ENV BUNDLE_FROZEN=false
ENV RACK_ENV=production

RUN gem install bundler -v 2.6.2 && \
    bundle config set --local without 'development' && \
    bundle install

COPY . .

CMD ["sh", "-c", "bundle exec puma -p ${PORT:-8080} -b tcp://0.0.0.0 -w 0 -t 1:5"]