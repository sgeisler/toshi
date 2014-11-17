# start with the container built by fig
FROM toshi_web
# for java integration specs
RUN apt-get update -qq && apt-get install -y default-jre
# get our tets gems back
RUN bundle install --without=development
# set rack env and toshi env
ENV RACK_ENV test
ENV TOSHI_ENV test

# start app
CMD ["bundle", "exec", "rake", "test"]
