FROM alpine:3.6

ARG TZ=UTC

ENV VERSION 1.3.0-0
ENV PHP_PKGS="php7-session php7-mysqli php7-mbstring php7-xml php7-gd php7-zlib php7-bz2 php7-zip php7-openssl php7-curl php7-opcache php7-json nginx php7-fpm" \
    NAGIOS_PKGS="alpine-sdk curl busybox bash rsync perl gd zlib libpng jpeg freetype mysql perl-plack findutils bash supervisor" \
    NCONF_URL="https://sourceforge.net/projects/nconf/files/nconf/${VERSION}/nconf-${VERSION}.tgz/download" \
    NCONF_SHA="https://sourceforge.net/projects/nconf/files/nconf/${VERSION}/nconf-${VERSION}.tgz.sha256/download" \
    WWW=/usr/local/nagios/share \
    USER=nagios

# Install dependencies
RUN apk add --no-cache $PHP_PKGS $NAGIOS_PKGS

# Copy configuration
COPY etc /etc/
COPY nagioscore.tar.gz /

# Copy main script
COPY run.sh /run.sh

# Calculate download URL
LABEL version=$VERSION

# Download tarball, verify it using gpg and extract
RUN set -x \
    && cd / \
    && apk update \
    && apk add tzdata \
    && echo "$TZ" > /etc/TZ \
    && cp /usr/share/zoneinfo/$TZ /etc/timezone \
    && cp /usr/share/zoneinfo/$TZ /etc/localtime \
    && apk add --no-cache $PHP_PKGS $NAGIOS_PKGS \
    && tar xzvf /nagioscore.tar.gz \
    && rm /nagioscore.tar.gz \
    && curl --output "nconf-${VERSION}.tgz" --location $NCONF_URL \
    && curl --output nconf.tgz.sha --location $NCONF_SHA \
    && sha256sum -c nconf.tgz.sha \
    && tar xzvf "nconf-${VERSION}.tgz" \
    && rm -f "nconf-${VERSION}.tgz" nconf.tgz.sha \
    && mv nconf "$WWW" \
    && chown -R root:nobody "$WWW" \
    && find "$WWW" -type d -exec chmod 750 {} \; \
    && find "$WWW" -type f -exec chmod 640 {} \; \
    && chmod u+rwx /run.sh

#    && rm -rf /www/setup/ /www/examples/ /www/test/ /www/po/ /www/composer.json /www/RELEASE-DATE-$VERSION \
#    && sed -i "s@define('CONFIG_DIR'.*@define('CONFIG_DIR', '/etc/phpmyadmin/');@" /www/libraries/vendor_config.php \

# Add directory for sessions to allow session persistence
RUN mkdir /sessions

# We expose nagios on port 80
EXPOSE 80

ENTRYPOINT [ "/run.sh" ]
CMD ["nagios"]
