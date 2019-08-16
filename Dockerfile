FROM debian:buster

RUN apt-get update -q && apt-get install -qy ca-certificates mailutils postfix procps

COPY run.sh /usr/local/bin

EXPOSE 25

CMD ["/usr/local/bin/run.sh"]