#Download base image debian
FROM debian:latest

# Set default docker variables
ENV PUID=${PUID:-1000} \
    PGID=${PGID:-1000} \
    TZ=${TZ:-America/New_York} \
    ENCODE=${ENCODE:-x264} \
    MEDIA_SERVER=${MEDIA_SERVER:-yes}

# Set container labels
LABEL build_version="Media-Converter, Version: 2.2.8 Build-date: 2021-Jun-14" maintainer="parker-hemphill"

# Copy Handbrake and media-info compile script to /tmp
COPY compile_binaries /tmp/

# Compile HandBrakeCLI and media-info from latest source
RUN /tmp/compile_binaries

# Copy shell scripts and functions to container
COPY status convert_media /usr/local/bin/
COPY media-converter /usr/local/bin/
COPY functions /opt/

# Copy shell scripts to /usr/local/bin
COPY status convert_media /usr/local/bin/
COPY media-converter /usr/local/bin/

# Copy functions to /opt
COPY functions /opt/

# Run the command on container start
ENTRYPOINT ["/usr/local/bin/media-converter"]
