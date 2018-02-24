ARG FROM_BASE=base_container:20180217
FROM $FROM_BASE

ARG DBUSER="${CFG_MYSQL_USER}"
ARG DBPASS="${CFG_MYSQL_PASSWORD}"
ARG DBHOST='mysql'
ARG DBNAME='nconf'

# version of this docker image
ARG CONTAINER_VERSION=1.0.2
LABEL version=$CONTAINER_VERSION  

ENV NAGIOS_HOME=/usr/local/nagios

# Add configuration and customizations
COPY build /tmp/

# build content
RUN set -o verbose \
    && chmod u+rwx /tmp/build.sh \
    && /tmp/build.sh 'NAGIOS'
RUN rm -rf /tmp/* 

# We expose nagios on ports 80,25
EXPOSE 25

#USER nagios
WORKDIR $NAGIOS_HOME

ENTRYPOINT [ "docker-entrypoint.sh" ]
CMD ["nagios"]
