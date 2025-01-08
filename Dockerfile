# ----- BUILD -----

FROM ruby:3.4.1 AS builder

WORKDIR /app

RUN mkdir -p ./lib/trmnl_preview/

COPY Gemfile \
    Gemfile.lock \
    trmnl_preview.gemspec \
    ./

COPY /lib/ /app/lib/

RUN bundle install

# ----- RUN -----

FROM ruby:3.4.1 AS runner

WORKDIR /app

COPY --from=builder /usr/local/bundle/ /usr/local/bundle/

COPY Gemfile \
    Gemfile.lock \
    trmnl_preview.gemspec \
    LICENSE.txt \
    README.md \
    /app/

COPY lib/ /app/lib/
COPY web/ /app/web/
COPY exe/ /app/exe/

RUN bundle install

RUN apt-get update && apt-get install -y \
    imagemagick \
    firefox-esr

EXPOSE 4567

ENTRYPOINT [ "bundle", "exec", "/app/exe/trmnlp", "serve", "/plugin", "-b", "0.0.0.0" ]
