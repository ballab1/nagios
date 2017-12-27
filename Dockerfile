FROM alpine:3.6


ARG TZ="America/New_York"
ARG DBUSER="${CFG_MYSQL_USER}"
ARG DBPASS="${CFG_MYSQL_PASSWORD}"
ARG DBHOST='mysql'
ARG DBNAME='nconf'

ENV VERSION=1.0.0 \
    NAGIOS_HOME=/usr/local/nagios \
    DBUSER="${CFG_MYSQL_USER}" \
    DBPASS="${CFG_MYSQL_PASSWORD}" \
    DBHOST='mysql' \
    DBNAME='nconf'
    
LABEL version=$VERSION

# Add configuration and customizations
COPY build /tmp/

# build content
RUN set -o verbose \
    && apk update \
    && apk add --no-cache bash \
    && chmod u+rwx /tmp/build_container.sh \
    && /tmp/build_container.sh \
    && rm -rf /tmp/*

# We expose nagios on ports 80,25
EXPOSE 25

USER $nagios_user
WORKDIR $NAGIOS_HOME

ENTRYPOINT [ "docker-entrypoint.sh" ]
CMD ["nagios"]
