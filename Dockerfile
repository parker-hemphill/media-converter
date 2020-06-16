#Download base image ubuntu
FROM debian:latest

# set version label
LABEL build_version="Media-Converter, Version: 1.3.9, Build-date: 16-Jun-2020"
LABEL maintainer=parker-hemphill

# Copy convert shell scripts to /opt
COPY *.sh /opt/

# Set scripts as executable
RUN \
chmod +rxxx /opt/status.sh; \
chmod +rxxx /opt/convert_media.sh; \
chmod +rxxx /opt/batch_move.sh; \
chmod +rxxx /opt/media-converter.sh; \
apt-get update; \
apt-get upgrade -y; \
apt-get --no-install-recommends -qq -y install mediainfo ffmpeg handbrake-cli sudo procps tzdata gntp-send; \
apt autoremove; \
ln -s /opt/status.sh /usr/local/bin/status; \
echo 'Set disable_coredump false' > /etc/sudo.conf;

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
