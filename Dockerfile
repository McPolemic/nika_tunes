FROM resin/rpi-raspbian
MAINTAINER Adam Lukens <adam.lukens@mcpolemic.com>

RUN apt-get update && apt-get install -y ruby2.1         \
                                         ruby2.1-dev     \
                                         libffi-dev      \
                                         autoconf        \
                                         automake        \
                                         libtool         \
                                         libltdl-dev     \
                                         libevdev-dev    \
                                         build-essential \
                                         zlib1g-dev
RUN update-alternatives --install /usr/bin/ruby ruby /usr/bin/ruby2.1 1 && \
    update-alternatives --install /usr/bin/gem gem /usr/bin/gem2.1 1
RUN gem install bundler
RUN bundle config --global silence_root_warning 1

WORKDIR /app
ADD Gemfile* /app/
RUN bundle install

ADD . /app/
CMD ruby nika_tunes.rb
