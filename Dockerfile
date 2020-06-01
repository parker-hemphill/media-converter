#Download base image ubuntu
FROM ubuntu:latest

# set version label
LABEL build_version="Media-Converter, Version: 1.3.5, Build-date: 31-Mar-2020"
LABEL maintainer=parker-hemphill

RUN echo "**** install build packages ****"; \
apt-get update; \
apt-get upgrade -y; \
apt-get --no-install-recommends -qq -y install mediainfo ffmpeg handbrake-cli sudo procps tzdata gntp-send; \
apt autoremove

# Copy convert shell scripts to /opt
COPY *.sh /opt/

# Set scripts as executable
RUN echo "**** set shell scripts as executable ****"; \
chmod +rxxx /opt/status.sh; \
chmod +rxxx /opt/convert_movie.sh; \
chmod +rxxx /opt/convert_tv.sh; \
chmod +rxxx /opt/batch_move.sh; \
chmod +rxxx /opt/media-converter.sh;

# Set default docker variables
ENV PUID=${PUID:-1000}
ENV PGID=${PGID:-1000}
ENV TZ=${TZ:-America/New_York}
ENV ENCODE=${ENCODE:-x264}
ENV GROWL=${GROWL:-NO}
ENV GROWL_IP=${GROWL_IP:-127.0.0.1}
ENV GROWL_PORT=${GROWL_PORT:-23053}

# Run the command on container startup
ENTRYPOINT ["/opt/media-converter.sh"]
