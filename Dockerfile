FROM alpine:3.6

ARG TZ=UTC

ENV NCONF_VERSION=1.3.0-0
ENV CORE_PKGS="bash curl findutils git nginx openssh-client perl shadow ttf-dejavu tzdata unzip" \
    NAGIOS_PKGS="alpine-sdk freetype gd jpeg libpng linux-headers mysql perl-plack rsync supervisor zlib " \
    NCONF_URL="https://sourceforge.net/projects/nconf/files/nconf/${NCONF_VERSION}/nconf-${NCONF_VERSION}.tgz/download" \
    NCONF_SHA="https://sourceforge.net/projects/nconf/files/nconf/${NCONF_VERSION}/nconf-${NCONF_VERSION}.tgz.sha256/download" \
    NAGIOS_HOME=/usr/local/nagios \
    WWW=/usr/local/nagios/share

# Calculate download URL
LABEL version=$VERSION

ARG user=nagios
ARG group=nagios
ARG uid=1001
ARG gid=1001

# Add configuration, main script, tarfiles for core & plugs, and NCONF
COPY etc /etc/
COPY run.sh /
COPY nagios.tgz /tmp/
COPY nagios-plugins.tgz /tmp/
COPY nagios-custom.tgz /tmp/
COPY php.tgz /tmp/
ADD "$NCONF_URL" "/tmp/nconf-${NCONF_VERSION}.tgz"
ADD "$NCONF_SHA" /tmp/nconf.tgz.sha

# Download tarball, verify it using gpg and extract
# Install dependencies
# Nagios is run with user `nagios`, uid = 1001
# If you bind mount a volume from the host or a data container, 
# ensure you use the same uid
RUN set -x \
    && cd / \
    && apk update \
    && apk add --no-cache $CORE_PKGS $NAGIOS_PKGS \
    && echo "$TZ" > /etc/TZ \
    && cp /usr/share/zoneinfo/$TZ /etc/timezone \
    && cp /usr/share/zoneinfo/$TZ /etc/localtime \
    && apk add --no-cache $CORE_PKGS $NAGIOS_PKGS \
    && /usr/sbin/groupadd -g ${gid} ${group} \
    && /usr/sbin/useradd -d "$NAGIOS_HOME" -u ${uid} -g ${gid} -m -s /bin/bash ${user} \
    && cd /tmp \
    && sha256sum -c nconf.tgz.sha \
    && mkdir php \
    && cd php \
    && tar xzvf ../php.tgz \
    && make install \
    && mkdir ../nagios \
    && cd ../nagios \
    && tar xzvf "../nagios.tgz" \
    && tar xzvf "../nagios-custom.tgz" \
    && cat custom/Makefile.custom >> Makefile \
    && make install \
    && make install-init \
    && make install-commandmode \
    && make install-classicui \
    && make install-customcontent \
    && mkdir ../nagios-plugins \
    && cd ../nagios-plugins \
    && tar xzvf "../nagios-plugins.tgz" \
    && make install \
    && mv /usr/local/nagios/etc /usr/local/nagios/etc.bak \
    && cd .. \
    && tar xzvf "nconf-${NCONF_VERSION}.tgz" \
    && mkdir /usr/local/nagios/nconf \
    && mv nconf/ADD-ONS /usr/local/nagios/nconf/ \
    && mv nconf/config.orig /usr/local/nagios/nconf/ \
    && mv nconf/INSTALL* /usr/local/nagios/nconf/ \
    && mv nconf/UPDATE* /usr/local/nagios/nconf/ \
    && mv nconf/SUMS* /usr/local/nagios/nconf/ \
    && mv nconf "$WWW/nconf" \
    && chown -R root:nobody "$WWW" \
    && find "$WWW" -type d -exec chmod 750 {} \; \
    && find "$WWW" -type f -exec chmod 640 {} \; \
    && find "$WWW/nconf/config" -type d -exec chmod 777 {} \; \
    && find "$WWW/nconf/config" -type f -exec chmod 666 {} \; \
    && find "$WWW/nconf/output" -type d -exec chmod 777 {} \; \
    && find "$WWW/nconf/output" -type f -exec chmod 666 {} \; \
    && find "$WWW/nconf/static_cfg" -type d -exec chmod 777 {} \; \
    && find "$WWW/nconf/static_cfg" -type f -exec chmod 666 {} \; \
    && find "$WWW/nconf/temp" -type d -exec chmod 777 {} \; \
    && chmod u+rwx /run.sh \
    && rm -rf /tmp/*

# Add directory for sessions to allow session persistence
RUN mkdir /sessions

# We expose nagios on port 80
EXPOSE 80

ENTRYPOINT [ "/run.sh" ]
CMD ["nagios"]
