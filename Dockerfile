# This Dockerfile is for development purposes only.
# Please do not use it in production.
#
# This file is heavily inspired by: 
#   https://github.com/denvazh/gatling/blob/master/3.2.1/Dockerfile

FROM amazoncorretto:17-alpine-jdk AS base

ENV GATLING_VERSION 3.10.3 
ENV SCALA_VERSION 2.12.4 
ENV SCALA_HOME /usr/share/scala

WORKDIR /opt

RUN apk update \ 
    && apk upgrade \
    && apk add --update wget \
        bash \
        coreutils \
        jq \
        shadow \
        libc6-compat \
        bash-doc \
        bash-completion \
    && mkdir -p /tmp/downloads \ 
    && wget -q -O /tmp/downloads/gatling-${GATLING_VERSION}.zip \
        https://repo1.maven.org/maven2/io/gatling/highcharts/gatling-charts-highcharts-bundle/${GATLING_VERSION}/gatling-charts-highcharts-bundle-${GATLING_VERSION}-bundle.zip \
    && mkdir -p /tmp/archive /opt/gatling \
    && chown 1000 /opt/gatling \
    && cd /tmp/archive \
    && unzip /tmp/downloads/gatling-${GATLING_VERSION}.zip \
    && mv /tmp/archive/gatling-charts-highcharts-bundle-${GATLING_VERSION}/* /opt/gatling/ \
    && chown 1000 /opt/gatling/bin/gatling.sh \
    && rm -rf /tmp/* \
    && rm -f /opt/gatling/bin/*.bat /opt/gatling/bin/recorder.sh \
    && mv -f /opt/gatling/bin/gatling.sh /opt/gatling/bin/gatling \
    && apk add --no-cache --virtual=.build-dependencies wget ca-certificates \
    && apk add --no-cache bash curl jq \
    && cd "/tmp" \
    && wget --no-verbose "https://downloads.typesafe.com/scala/${SCALA_VERSION}/scala-${SCALA_VERSION}.tgz" \
    && tar xzf "scala-${SCALA_VERSION}.tgz" \
    && mkdir "${SCALA_HOME}" \
    && rm "/tmp/scala-${SCALA_VERSION}/bin/"*.bat \
    && mv "/tmp/scala-${SCALA_VERSION}/bin" "/tmp/scala-${SCALA_VERSION}/lib" "${SCALA_HOME}" \
    && ln -s "${SCALA_HOME}/bin/"* "/usr/bin/" \
    && apk del .build-dependencies \
    && rm -rf "/tmp/"*

WORKDIR /opt/gatling

COPY ./tools/gatling/conf/gatling.conf ./conf

VOLUME [ "/opt/gatling/conf", "/opt/gatling/results", "/opt/gatling/user-files" ]

ENV PATH /usr/local/sbt/bin:/opt/gatling/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
ENV GATLING_HOME /opt/gatling

RUN useradd --shell /bin/bash -m application --uid 1000

##
FROM base AS dockershell

USER 1000