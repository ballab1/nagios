ARG FROM_BASE=${DOCKER_REGISTRY:-}${OS:-}php/5.6.37-r0:${BASE_TAG:-latest}
FROM $FROM_BASE

# name and version of this docker image
ARG CONTAINER_NAME=nagios
# Specify CBF version to use with our configuration and customizations
ARG CBF_VERSION

# include our project files
COPY build Dockerfile /tmp/

# set to non zero for the framework to show verbose action scripts
#    (0:default, 1:trace & do not cleanup; 2:continue after errors)
ENV DEBUG_TRACE=0


ARG NCONF_DBHOST='mysql'
ARG NCONF_DBNAME='nconf'
ARG NAGIOS_HOME=/usr/local/nagios

# nagios.core version being bundled in this docker image
ARG NCORE_VERSION=4.4.2
LABEL nagios.core.version=$NCORE_VERSION  

# nagios.object (cpan) version being bundled in this docker image
ARG NOBJECT_VERSION=0.21.20
LABEL nagios.object.version=$NOBJECT_VERSION  

# nconf version being bundled in this docker image
ARG NCONF_VERSION=1.3.0-0
LABEL nconf.version=$NCONF_VERSION  

# nagiosgraph being bundled in this docker image
ARG NGRAPH_VERSION=1.5.2
LABEL nagiosgraph.version=$NGRAPH_VERSION  


# build content
RUN set -o verbose \
    && chmod u+rwx /tmp/build.sh \
    && /tmp/build.sh "$CONTAINER_NAME" "$DEBUG_TRACE"
RUN [ $DEBUG_TRACE != 0 ] || rm -rf /tmp/* 


# We expose nagios on ports 80,25
EXPOSE 25

#USER nagios
WORKDIR $NAGIOS_HOME

ENTRYPOINT [ "docker-entrypoint.sh" ]
#CMD ["$CONTAINER_NAME"]
CMD ["nagios"]
