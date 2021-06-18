ARG FROM_BASE=${DOCKER_REGISTRY:-s2.ubuntu.home:5000/}${CONTAINER_OS:-alpine}/php/${PHP7_VERSION:-7.4.20-r0}:${BASE_TAG:-latest}
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
ARG PNP4NAGIOS_HOME=/usr/local/pnp4nagios
ARG WWW_HOME=/var/www

# nagios.core version being bundled in this docker image
ARG NAGIOS_VERSION=4.4.6
LABEL version.nagios.core=$NAGIOS_VERSION  

# nagios.object (cpan) version being bundled in this docker image
ARG NOBJECT_VERSION=0.21.20
LABEL version.nagios.object=$NOBJECT_VERSION  

# nconf version being bundled in this docker image
ARG NCONF_VERSION=1.4.0-final2
LABEL version.nconf=$NCONF_VERSION  

# nagiosgraph being bundled in this docker image
ARG PNP4NAGIOS_VERSION=0.6.26
LABEL version.pnp4nagios=$PNP4NAGIOS_VERSION

# npugins being bundled in this docker image
#ARG NPLUGINS_VERSION=2.2.3
#LABEL version.nplugin=$NPLUGINS_VERSION

# build content
RUN set -o verbose \
    && chmod u+rwx /tmp/build.sh \
    && /tmp/build.sh "$CONTAINER_NAME" "$DEBUG_TRACE" "$TZ" \
    && ([ "$DEBUG_TRACE" != 0 ] || rm -rf /tmp/*) 


# We expose nagios on ports 80,25
EXPOSE 25

#USER nagios
WORKDIR $WWW_HOME

ENTRYPOINT [ "docker-entrypoint.sh" ]
#CMD ["$CONTAINER_NAME"]
CMD ["nagios"]
