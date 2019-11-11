#Download base image ubuntu
FROM ubuntu:latest

# set version label
LABEL build_version="Media-Converter, Version: 1.2.4, Build-date: 11-Nov-2019"
LABEL maintainer=parker-hemphill

RUN echo "**** install build packages ****"; \
apt-get update; \
apt-get --no-install-recommends -qq -y install mediainfo ffmpeg handbrake-cli sudo procps tzdata; \
apt autoremove

# Copy convert shell scripts to /opt
RUN echo "**** copy shell scripts to /opt ****"
COPY convert_movie.sh /opt
COPY convert_tv.sh /opt
COPY batch_move.sh /opt
COPY media-converter.sh /opt
COPY status.sh /opt

# Set scripts as executable
RUN echo "**** set shell scripts as executable ****"; \
chmod +rxxx /opt/convert_movie.sh; \
chmod +rxxx /opt/convert_tv.sh; \
chmod +rxxx /opt/batch_move.sh; \
chmod +rxxx /opt/media-converter.sh; \
chmod +rxxx /opt/status.sh

# Set default docker variables
RUN echo "**** setup default variables****"
ENV PUID=${PUID:-1000}
ENV PGID=${PGID:-1000}
ENV TZ=${TZ:-America/New_York}
ENV ENCODE=${ENCODE:-x264}

# Run the command on container startup
ENTRYPOINT ["/opt/media-converter.sh"]
