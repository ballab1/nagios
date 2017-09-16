FROM alpine:3.6

ARG TZ=UTC

ENV VERSION 1.3.0-0
ENV CORE_PKGS="coreutils git openssh-client curl unzip bash ttf-dejavu alpine-sdk shadow" \
    NAGIOS_PKGS="busybox linux-headers rsync perl gd zlib libpng jpeg freetype mysql perl-plack findutils supervisor" \
    PHP_PKGS="php7-session php7-mysqli php7-mbstring php7-xml php7-gd php7-zlib php7-bz2 php7-zip php7-openssl php7-curl php7-opcache php7-json nginx php7-fpm" \
    NCONF_URL="https://sourceforge.net/projects/nconf/files/nconf/${VERSION}/nconf-${VERSION}.tgz/download" \
    NCONF_SHA="https://sourceforge.net/projects/nconf/files/nconf/${VERSION}/nconf-${VERSION}.tgz.sha256/download" \
    NAGIOS_HOME=/usr/local/nagios \
    WWW=/usr/local/nagios/share

# Install dependencies
RUN apk add --no-cache $PHP_PKGS $NAGIOS_PKGS $CORE_PKGS

# Calculate download URL
LABEL version=$VERSION

ARG user=nagios
ARG group=nagios
ARG uid=1001
ARG gid=1001

# Nagios is run with user `nagios`, uid = 1001
# If you bind mount a volume from the host or a data container, 
# ensure you use the same uid
RUN /usr/sbin/groupadd -g ${gid} ${group} \
    && /usr/sbin/useradd -d "$NAGIOS_HOME" -u ${uid} -g ${gid} -m -s /bin/bash ${user}


# Copy configuration
COPY etc /etc/
COPY nagioscore.tar.gz /

# Copy main script
COPY run.sh /run.sh

# Download tarball, verify it using gpg and extract
RUN set -x \
    && cd / \
    && apk update \
    && apk add tzdata \
    && echo "$TZ" > /etc/TZ \
    && cp /usr/share/zoneinfo/$TZ /etc/timezone \
    && cp /usr/share/zoneinfo/$TZ /etc/localtime \
    && apk add --no-cache $CORE_PKGS $PHP_PKGS $NAGIOS_PKGS \
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
