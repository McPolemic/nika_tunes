FROM resin/rpi-raspbian
MAINTAINER Adam Lukens <adam.lukens@mcpolemic.com>

RUN echo 'deb http://archive.raspbian.org/raspbian/ stretch main' >> /etc/apt/sources.list
RUN apt-get update && apt-get install -y ruby2.3         \
                                         ruby2.3-dev     \
                                         libffi-dev      \
                                         autoconf        \
                                         automake        \
                                         libtool         \
                                         libltdl-dev     \
                                         libevdev-dev    \
                                         build-essential \
                                         zlib1g-dev
RUN update-alternatives --install /usr/bin/ruby ruby /usr/bin/ruby2.3 1 && \
    update-alternatives --install /usr/bin/gem gem /usr/bin/gem2.3 1
RUN gem install bundler
RUN bundle config --global silence_root_warning 1

RUN apt-get install -y python-pip python-dev python-setuptools && pip install evdev

WORKDIR /app
ADD Gemfile* /app/
RUN bundle install

ADD . /app/
CMD dotenv python reader.py | bundle exec ruby nika_tunes.rb
