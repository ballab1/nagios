FROM alpine:3.6

ARG TZ=UTC

ENV NCONF_VERSION=1.3.0-0
ENV CORE_PKGS="bash curl findutils libxml2 nginx openssh-client perl shadow ttf-dejavu tzdata unzip" \
    NAGIOS_PKGS="freetype gd jpeg libpng mysql perl-plack rsync supervisor zlib " \
    NAGIOS_HOME=/usr/local/nagios \
    WWW=/usr/local/nagios/share

# Calculate download URL
LABEL version=$VERSION

ARG user=nagios
ARG group=nagios
ARG uid=1001
ARG gid=1001

# Add configuration, main script, tarfiles for core & plugs, and NCONF
COPY nagios.tgz /tmp/
COPY run.sh /

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
    && cd / \
    && tar xzvf /tmp/nagios.tgz \
    && ln -s /usr/local/nagios/etc /etc/nagios \
    && mkdir -p /var/log/nagios \
    && chmod a+rwx /var/log/nagios \
    && chmod u+rwx /run.sh \
    && rm -rf /tmp/*

# Add directory for sessions to allow session persistence
RUN mkdir /sessions

# We expose nagios on port 80
#EXPOSE 80

ENTRYPOINT [ "/run.sh" ]
#CMD ["/usr/local/nagios/bin/nagios", "/usr/local/nagios/etc/nagios.cfg" ]
CMD ["nagios"]
