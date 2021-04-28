#Download base image debian
FROM debian:latest

# Set default docker variables
ENV PUID=${PUID:-1000} \
    PGID=${PGID:-1000} \
    TZ=${TZ:-America/New_York} \
    ENCODE=${ENCODE:-x264} \
    MEDIA_SERVER=${MEDIA_SERVER:-no}

# set container labels
LABEL build_version="Media-Converter, Version: 2.1.8 Build-date: 2021-Apr-28" maintainer="parker-hemphill"

# Copy Handbrake and media-info compile script to /tmp
COPY compile_binaries /tmp/

# Copy shell script and functions to /opt
COPY convert_media /opt/
COPY functions /opt/
COPY media-converter /opt/

# Copy status script to /usr/local/bin
COPY status /usr/local/bin/

# Compile HandBrakeCLI and media-info from latest source
RUN /tmp/compile_binaries

# Run the command on container start
ENTRYPOINT ["/opt/media-converter"]
