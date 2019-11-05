#Download base image ubuntu
FROM ubuntu:latest

# set version label
LABEL build_version="Parker Media-Convertor version:- 1.2 Build-date:- 5-Nov-2019"
LABEL maintainer=parker-hemphill

RUN echo "**** install build packages ****"; \
apt-get update; \
apt-get --no-install-recommends -qq -y install mediainfo ffmpeg handbrake-cli sudo cron procps; \
apt autoremove

# Copy convert shell scripts to /opt
RUN echo "**** copy shell scripts to /opt ****"
COPY convert_movie.sh /opt
COPY convert_tv.sh /opt
COPY batch_move.sh /opt
COPY media-converter.sh /opt
COPY cronjob /etc/crontabs/media

# Set scripts as executable
RUN echo "**** set shell scripts as executable ****"; \
chmod +rxxx /opt/convert_movie.sh; \
chmod +rxxx /opt/convert_tv.sh; \
chmod +rxxx /opt/batch_move.sh; \
chmod +rxxx /opt/media-converter.sh

# Create the log file to be able to run tail
RUN touch /var/log/cron.log

RUN echo "**** setup torrent directories and cron tab****"
ENV PUID=${PUID:-1000}
ENV PGID=${PGID:-1000}

# Run the command on container startup
ENTRYPOINT ["/opt/media-converter.sh"]
