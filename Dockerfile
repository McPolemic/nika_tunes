FROM ubuntu:17.10
MAINTAINER Adam Lukens <adam.lukens@mcpolemic.com>

RUN apt-get update && apt-get install -y ruby2.3 ruby2.3-dev build-essential zlib1g-dev
RUN gem install bundler
RUN bundle config --global silence_root_warning 1

WORKDIR /app
ADD Gemfile* /app/
RUN bundle install

ADD . /app/
CMD bash
