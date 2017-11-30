FROM alpine:3.6

ARG TZ=UTC
ARG user=nagios
ARG group=nagios
ARG uid=1002
ARG gid=1002


ENV NCORE_VERSION=4.3.4 \
    NCONF_VERSION=1.3.0-0 \ 
    NPLUGIN_VERSION=2.2.1 \
    PHP_VERSION=5.6.31 \
    NAGIOS_HOME=/usr/local/nagios \
    NCONF=/usr/local/nagios/share/nconf \
    WWW=/usr/local/nagios/share

ENV BUILDTIME_PKGS="alpine-sdk bash-completion busybox gd-dev git jpeg-dev libpng-dev libxml2-dev linux-headers" \
    CORE_PKGS="bash curl findutils libxml2 nginx openssh-client perl perl-cgi perl-cgi-session shadow sudo supervisor ttf-dejavu tzdata unzip zlib" \
    NAGIOS_PKGS="fcgiwrap freetype gd jpeg libpng mysql perl-plack perl-dbi perl-dbd-mysql perl-gd rrdtool rsync"

# Calculate download URL
LABEL version=$VERSION

# Add configuration and customizations
COPY docker-entrypoint.sh /usr/local/bin/
COPY build /tmp/


# Download tarball, verify it using gpg and extract
# Install dependencies
# Nagios is run with user `nagios`, uid = 1001
# Add directory for sessions to allow session persistence
# If you bind mount a volume from the host or a data container, 
# ensure you use the same uid
RUN set -o xtrace \
    && chmod u+rwx /usr/local/bin/docker-entrypoint.sh \
    && ln -s /usr/local/bin/docker-entrypoint.sh /docker-entrypoint.sh \
    && apk update \
    && apk add --no-cache $CORE_PKGS $NAGIOS_PKGS \
    && apk add --no-cache --virtual .buildDepedencies $BUILDTIME_PKGS \
    && echo "$TZ" > /etc/TZ \
    && cp /usr/share/zoneinfo/$TZ /etc/timezone \
    && cp /usr/share/zoneinfo/$TZ /etc/localtime \
    && chmod u+rwx /tmp/build_nagios.sh \
    && /tmp/build_nagios.sh \
    && ln -s /usr/local/nagios/etc /etc/nagios \
    && ln -s /usr/local/nagios/bin/nagios /usr/bin/nagios \
    && mkdir /sessions \
    && find /usr/local/nagios/share -type d -exec chmod a+rx '{}' \; \
    && find /usr/local/nagios/share -type f -exec chmod a+r '{}' \;  \
    && rm -rf /usr/include \
    && apk del .buildDepedencies 


# We expose nagios on ports 80,25
EXPOSE 25
    
ENTRYPOINT [ "/docker-entrypoint.sh" ]
CMD ["nagios"]
