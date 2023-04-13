ARG ARCH=amd64
ARG JDK=adoptopenjdk:11-jre-openj9-bionic
ARG BUILD_DATE
ARG BUILD_VERSION
ARG BUILD_REF
ARG ALLURE_RELEASE=NONE
ARG ALLURE_REPO=https://repo.maven.apache.org/maven2/io/qameta/allure/allure-commandline
ARG QEMU_ARCH
ARG UID=1000
ARG GID=1000

######

FROM python:3.6-alpine AS dev_stage
RUN apk update
RUN apk add build-base
RUN pip install -U pylint
RUN pip install -Iv setuptools==47.1.1 wheel==0.34.2 waitress==1.4.4 && \
    pip install -Iv Flask==1.1.2 Flask-JWT-Extended==3.24.1 flask-swagger-ui==3.36.0 requests==2.23.0

ENV ROOT_DIR=/code
RUN mkdir -p $ROOT_DIR
WORKDIR $ROOT_DIR
COPY allure-docker-api $ROOT_DIR/allure-docker-api
RUN pylint --rcfile=allure-docker-api/.pylintrc allure-docker-api

######
FROM $ARCH/$JDK
ARG ARCH
ARG JDK
ARG BUILD_DATE
ARG BUILD_VERSION
ARG BUILD_REF
ARG ALLURE_RELEASE
ARG ALLURE_REPO
ARG QEMU_ARCH
ARG UID
ARG GID

LABEL org.label-schema.build-date=${BUILD_DATE} \
    org.label-schema.docker.dockerfile="docker/Dockerfile.bionic" \
    org.label-schema.license="MIT" \
    org.label-schema.name="Allure Framework" \
    org.label-schema.version=${BUILD_VERSION} \
    org.label-schema.description="Allure Framework is a flexible lightweight multi-language test report tool." \
    org.label-schema.url="https://docs.qameta.io/allure/" \
    org.label-schema.vcs-ref=${BUILD_REF} \
    org.label-schema.vcs-type="Git" \
    org.label-schema.vcs-url="https://github.com/fescobar/allure-docker-service" \
    org.label-schema.arch=${ARCH} \
    authors="Frank Escobar <fescobar.systems@gmail.com>, Raymond Mouthaan <raymondmmouthaan@gmail.com>"

# QEMU - Quick Emulation
COPY tmp/qemu-$QEMU_ARCH-static /usr/bin/qemu-$QEMU_ARCH-static

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
      tzdata \
      nano \
      python3 \
      python3-pip \
      python3-dev \
      unzip && \
    ln -s `which python3` /usr/bin/python && \
    pip3 install --upgrade pip && \
    pip install -Iv setuptools==47.1.1 wheel==0.34.2 waitress==1.4.4 && \
    pip install -Iv Flask==1.1.2 Flask-JWT-Extended==3.25.0 flask-swagger-ui==3.36.0 requests==2.23.0 && \
    curl ${ALLURE_REPO}/${ALLURE_RELEASE}/allure-commandline-${ALLURE_RELEASE}.zip -L -o /tmp/allure-commandline.zip && \
        unzip -q /tmp/allure-commandline.zip -d / && \
        apt-get remove -y unzip && \
        rm -rf /tmp/* && \
        rm -rf /var/lib/apt/lists/* && \
        chmod -R +x /allure-$ALLURE_RELEASE/bin && \
        mkdir -p /app

RUN groupadd --gid ${GID} allure \
    && useradd --uid ${UID} --gid allure --shell /bin/bash --create-home allure

ENV ROOT=/app
ENV ALLURE_HOME=/allure-$ALLURE_RELEASE
ENV ALLURE_HOME_SL=/allure
ENV PATH=$PATH:$ALLURE_HOME/bin
ENV ALLURE_RESOURCES=$ROOT/resources
ENV RESULTS_DIRECTORY=$ROOT/allure-results
ENV REPORT_DIRECTORY=$ROOT/allure-report
ENV RESULTS_HISTORY=$RESULTS_DIRECTORY/history
ENV REPORT_HISTORY=$REPORT_DIRECTORY/history
ENV ALLURE_VERSION=$ROOT/version
ENV EMAILABLE_REPORT_FILE_NAME='emailable-report-allure-docker-service.html'
ENV STATIC_CONTENT=$ROOT/allure-docker-api/static
ENV STATIC_CONTENT_PROJECTS=$STATIC_CONTENT/projects
ENV DEFAULT_PROJECT=default
ENV DEFAULT_PROJECT_ROOT=$STATIC_CONTENT_PROJECTS/$DEFAULT_PROJECT
ENV DEFAULT_PROJECT_RESULTS=$DEFAULT_PROJECT_ROOT/results
ENV DEFAULT_PROJECT_REPORTS=$DEFAULT_PROJECT_ROOT/reports
ENV EXECUTOR_FILENAME=executor.json

RUN echo -n $(allure --version) > ${ALLURE_VERSION} && \
    echo "ALLURE_VERSION: "$(cat ${ALLURE_VERSION}) && \
    mkdir $ALLURE_HOME_SL && \
    ln -s $ALLURE_HOME/* $ALLURE_HOME_SL && \
    ln -s $STATIC_CONTENT_PROJECTS $ROOT/projects && \
    ln -s $DEFAULT_PROJECT_REPORTS $ROOT/default-reports

WORKDIR $ROOT
COPY --chown=allure:allure allure-docker-api $ROOT/allure-docker-api
COPY --chown=allure:allure allure-docker-scripts $ROOT/
RUN chmod +x $ROOT/*.sh && \
    mkdir $RESULTS_DIRECTORY && \
    mkdir -p $DEFAULT_PROJECT_REPORTS/latest && \
    ln -sf $RESULTS_DIRECTORY $DEFAULT_PROJECT_RESULTS && \
    ln -sf $DEFAULT_PROJECT_REPORTS/latest $REPORT_DIRECTORY && \
    allure generate -c -o /tmp/resources && \
    mkdir $ALLURE_RESOURCES && \
    cp /tmp/resources/app.js $ALLURE_RESOURCES && \
    cp /tmp/resources/styles.css $ALLURE_RESOURCES

RUN chown -R allure:allure $ROOT

VOLUME [ "$RESULTS_DIRECTORY" ]

ENV DEPRECATED_PORT=4040
ENV PORT=5050

EXPOSE $DEPRECATED_PORT
EXPOSE $PORT

HEALTHCHECK --interval=10s --timeout=60s --retries=3 \
      CMD curl -f http://localhost:$PORT || exit 1

USER allure

CMD $ROOT/runAllureDeprecated.sh & $ROOT/runAllureApp.sh & $ROOT/checkAllureResultsFiles.sh