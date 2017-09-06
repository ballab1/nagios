FROM alpine:3.4
    
ARG TZ=UTC

ENV VERSION=0.4 \
    BUILDTIME_PKGS="alpine-sdk curl busybox bash rsync perl gd zlib libpng jpeg freetype mysql perl-plack findutils" \
    RUNTIME_PKGS="nagios nagios-plugins nagios-web nagiosql bash" \
    USER=nagios

ADD docker-entrypoint.sh /

# Run-time Dependencies
RUN apk upgrade --update

# Run-time dependencies
RUN apk add --no-cache $RUNTIME_PKGS && \
    apk add tzdata && cp /usr/share/zoneinfo/$TZ /etc/timezone && apk del tzdata && \
    chmod u+rx,g+rx,o+rx,a-w /docker-entrypoint.sh
#RUN usermod -u 10777 $USER && \
#    groupmod -g 10777 $USER

#USER $USER
CMD /docker-entrypoint.sh
