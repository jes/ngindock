FROM alpine:latest

WORKDIR /usr/src/app
COPY app /usr/src/app

RUN apk update && \
  apk add perl perl-dev g++ make wget curl && \
  curl -L https://cpanmin.us | perl - App::cpanminus && \
  cpanm Mojolicious -M https://cpan.metacpan.org && \
  apk del perl-dev g++ make wget && \
  rm -rf /root/.cpanm/* /usr/local/share/man/*

EXPOSE 3000

HEALTHCHECK --interval=5s --timeout=2s CMD curl --silent --fail localhost:3000/ || exit 1

CMD [ "./app", "daemon" ]
