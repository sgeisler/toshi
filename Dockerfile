# Start with an Ubuntu 14.04 image with ruby 2.1.2
FROM quay.io/coinbase/rails:latest

# Install dependencies
RUN apt-get -y install libpq-dev
RUN gem install bundler

# Install gems
ADD Gemfile /toshi/Gemfile
ADD Gemfile.lock /toshi/Gemfile.lock
WORKDIR /toshi
RUN bundle install

# Add the source dir
ADD . /toshi

# Copy the config template
ADD config/toshi.yml.example /toshi/config/toshi.yml

# Expose port 5000 of the container to the host
EXPOSE 5000