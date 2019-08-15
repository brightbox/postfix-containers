FROM ubuntu:eoan

RUN apt-get update -q && apt-get install -qy ca-certificates mailutils postfix

COPY run.sh /usr/local/bin
#STOPSIGNAL SIGKILL

#/usr/lib/postfix/sbin/master -i -d

EXPOSE 25

ENTRYPOINT /usr/local/bin/run.sh