ARG FROM_BASE=base_container:20180311
FROM $FROM_BASE

# name and version of this docker image
ARG CONTAINER_NAME=nagios
ARG CONTAINER_VERSION=1.0.0

LABEL org_name=$CONTAINER_NAME \
      version=$CONTAINER_VERSION 

# set to non zero for the framework to show verbose action scripts
ARG DEBUG_TRACE=0


ARG DBUSER="${CFG_MYSQL_USER}"
ARG DBPASS="${CFG_MYSQL_PASSWORD}"
ARG DBHOST='mysql'
ARG DBNAME='nconf'

ENV NAGIOS_HOME=/usr/local/nagios

# Add configuration and customizations
COPY build /tmp/

# build content
RUN set -o verbose \
    && chmod u+rwx /tmp/build.sh \
    && /tmp/build.sh "$CONTAINER_NAME"
RUN [[ $DEBUG_TRACE != 0 ]] || rm -rf /tmp/* 


# We expose nagios on ports 80,25
EXPOSE 25

#USER nagios
WORKDIR $NAGIOS_HOME

ENTRYPOINT [ "docker-entrypoint.sh" ]
#CMD ["$CONTAINER_NAME"]
CMD ["nagios"]
