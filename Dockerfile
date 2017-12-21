FROM alpine:3.6

ARG TZ=America/New_York
ARG nagios_user=nagios
ARG nagios_group=nagios
ARG nagios_uid=1002
ARG nagios_gid=1002
ARG www_user=www-data
ARG www_group=www-data
ARG www_uid=82
ARG www_gid=82


ENV VERSION=1.0.0 \
    NCORE_VERSION=4.3.4 \ 
    NCONF_VERSION=1.3.0-0 \
    NGRAPH_VERSION=1.5.2 \
    NAGIOS_HOME=/usr/local/nagios \
    NGRAPH_HOME=/usr/local/nagiosgraph \
    NCONF_HOME=/usr/local/nagios/share/nconf \
    WWW=/usr/local/nagios/share

ENV BUILDTIME_PKGS="alpine-sdk bash-completion busybox file gd-dev git gnutls-utils jpeg-dev libpng-dev libxml2-dev linux-headers musl-utils rrdtool-dev" \
    CORE_PKGS="bash curl findutils libxml2 mysql-client nginx openssh-client shadow sudo supervisor ttf-dejavu tzdata unzip util-linux zlib" \
    PERL_PKGS="perl perl-cgi perl-cgi-session perl-plack perl-dbi perl-dbd-mysql perl-gd perl-rrd" \
    PHP_PKGS="php5-fpm php5-ctype php5-cgi php5-common php5-dom php5-iconv php5-json php5-mysql php5-pgsql php5-posix php5-sockets php5-xml php5-xmlreader php5-xmlrpc php5-zip" \
    NAGIOS_PKGS="fcgiwrap freetype gd jpeg libpng mrtg mysql nagios-plugins-all rrdtool rrdtool-cgi rrdtool-utils rsync"

LABEL version=$VERSION

# Add configuration and customizations
COPY build /tmp/


# Install dependencies
# Nagios is run with user `nagios`, uid = 1001
# Add directory for sessions to allow session persistence
# If you bind mount a volume from the host or a data container, 
# ensure you use the same uid
RUN set -o errexit \
    \
    && apk update \
    && apk add --no-cache $CORE_PKGS $PERL_PKGS $PHP_PKGS $NAGIOS_PKGS \
    && apk add --no-cache --virtual .buildDepedencies $BUILDTIME_PKGS \
    \
    && echo "$TZ" > /etc/TZ \
    && cp /usr/share/zoneinfo/$TZ /etc/timezone \
    && cp /usr/share/zoneinfo/$TZ /etc/localtime \
    \
    && chmod u+rwx /tmp/build_container.sh \
    && /tmp/build_container.sh \
    && rm -rf /tmp/* \
    \
    && apk del .buildDepedencies 


# We expose nagios on ports 80,25
EXPOSE 25

#USER $nagios_user
#WORKDIR $NAGIOS_HOME\

ENTRYPOINT [ "/docker-entrypoint.sh" ]
CMD ["nagios"]
