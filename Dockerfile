FROM ruby:2.4.4-alpine

RUN apk add --update alpine-sdk

WORKDIR /app

RUN gem install bundler
RUN bundle config --global jobs 7

COPY Gemfile Gemfile.lock ./
RUN bundle install --retry 5

EXPOSE 4567

COPY . ./
CMD ["bundle", "exec", "ruby", "app.rb"]
