FROM ghcr.io/linuxserver/baseimage-mono:LTS

# set version label
ARG BUILD_DATE
ARG VERSION
ARG SONARR_VERSION
LABEL build_version="Linuxserver.io version:- ${VERSION} Build-date:- ${BUILD_DATE}"
LABEL maintainer="aptalca"

# set environment variables
ARG DEBIAN_FRONTEND="noninteractive"
ENV XDG_CONFIG_HOME="/config/xdg"
ENV SONARR_BRANCH="main"
ENV SMA_PATH /usr/local/sma
ENV UPDATE_SMA FALSE
ENV SMA_APP Sonarr

RUN \
  echo "**** install packages ****" && \
  apt-get update && \
  apt-get install -y \
    jq && \
  echo "**** install sonarr ****" && \
  mkdir -p /app/sonarr/bin && \
  if [ -z ${SONARR_VERSION+x} ]; then \
    SONARR_VERSION=$(curl -sX GET http://services.sonarr.tv/v1/releases \
    | jq -r ".[] | select(.branch==\"$SONARR_BRANCH\") | .version"); \
  fi && \
  curl -o \
    /tmp/sonarr.tar.gz -L \
    "https://download.sonarr.tv/v3/${SONARR_BRANCH}/${SONARR_VERSION}/Sonarr.${SONARR_BRANCH}.${SONARR_VERSION}.linux.tar.gz" && \
  tar xf \
    /tmp/sonarr.tar.gz -C \
    /app/sonarr/bin --strip-components=1 && \
  echo "UpdateMethod=docker\nBranch=${SONARR_BRANCH}\nPackageVersion=${VERSION}\nPackageAuthor=[linuxserver.io](https://linuxserver.io)" > /app/sonarr/package_info && \
  rm -rf /app/sonarr/bin/Sonarr.Update && \
  echo "**** cleanup ****" && \
  apt-get clean && \
  rm -rf \
    /tmp/* \
    /var/tmp/*
    
RUN \
	echo "************ install packages ************" && \
	apt-get update && \
	apt-get install -y \
		git \
		wget \
		python3 \
		python3-pip \
		ffmpeg \
		mkvtoolnix \
		tidy \
		cron && \
	apt-get purge --auto-remove -y && \
	apt-get clean && \
	echo "************ setup SMA ************" && \
	echo "************ setup directory ************" && \
	mkdir -p ${SMA_PATH} && \
	echo "************ download repo ************" && \
	git clone https://github.com/mdhiggins/sickbeard_mp4_automator.git ${SMA_PATH} && \
	mkdir -p ${SMA_PATH}/config && \
	echo "************ create logging file ************" && \
	mkdir -p ${SMA_PATH}/config && \
	touch ${SMA_PATH}/config/sma.log && \
	chgrp users ${SMA_PATH}/config/sma.log && \
	chmod g+w ${SMA_PATH}/config/sma.log && \
	echo "************ install pip dependencies ************" && \
	python3 -m pip install --user --upgrade pip && \	
	pip3 install -r ${SMA_PATH}/setup/requirements.txt && \
	echo "************ install python packages ************" && \
	python3 -m pip install --no-cache-dir -U \
		yq && \
	echo "************ setup cron ************" && \
	service cron start && \
	echo "* * * * *   root   bash /scripts/update.bash" >> "/etc/crontab"

WORKDIR /

# add local files
COPY root/ /

# ports and volumes
EXPOSE 8989
VOLUME /config
