FROM alpine:latest

RUN apk add swaks --repository=http://dl-cdn.alpinelinux.org/alpine/edge/testing/
RUN apk update && apk add --no-cache docker-cli perl-net-ssleay perl-net-dns curl tzdata  

COPY cluster_show_dummy /usr/local/bin/cluster_show_dummy
COPY repmgr-checker.sh /usr/local/bin/repmgr-checker.sh

# Set the script as the entrypoint
ENTRYPOINT ["/bin/sh", "/usr/local/bin/repmgr-checker.sh"]

