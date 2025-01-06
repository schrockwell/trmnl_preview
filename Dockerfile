# ----- BUILD -----

FROM ruby:3.4.1 AS builder

WORKDIR /app

COPY Gemfile Gemfile.lock ./

RUN bundle install

# ----- RUN -----

FROM ruby:3.4.1 AS runner

WORKDIR /app

COPY --from=builder /usr/local/bundle/ /usr/local/bundle/

COPY Gemfile \
    Gemfile.lock \
    LICENSE.txt \
    README.md \
    /app/

COPY lib/ /app/lib/
COPY web/ /app/web/
COPY exe/ /app/exe/

RUN bundle install

EXPOSE 4567

ENTRYPOINT [ "/app/exe/trmnlp", "serve", "/plugin", "-b", "0.0.0.0" ]
