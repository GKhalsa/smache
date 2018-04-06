FROM bitwalker/alpine-elixir:1.6.3

EXPOSE 4000
ENV PORT=4000 \
  VERSION=0.0.1 \
  APP=smache \
  MIX_ENV=prod

RUN apk --update add make bash && rm -rf /var/cache/apk/*

WORKDIR ${HOME}

COPY smache .
COPY .env .
RUN source .env \
  && mix do deps.get, compile, release --verbose --env=prod \
  && mkdir -p /opt/$APP/log \
  && cp _build/prod/rel/$APP/releases/$VERSION/$APP.tar.gz /opt/$APP/ \
  && cd /opt/$APP \
  && tar -xzf $APP.tar.gz \
  && rm $APP.tar.gz \
  && rm -rf /opt/app/* \
  && chmod -R 777 /opt/$APP \
  && echo "$APP $PORT"

WORKDIR /opt/$APP

CMD ["./bin/smache", "foreground"]