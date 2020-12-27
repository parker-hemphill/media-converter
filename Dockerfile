#Download base image debian
FROM debian:latest

# Set default docker variables
ENV PUID=${PUID:-1000} \
    PGID=${PGID:-1000} \
    TZ=${TZ:-America/New_York} \
    ENCODE=${ENCODE:-x264} \
    MEDIA_SERVER=${MEDIA_SERVER:-no} \
    GROWL=${GROWL:-NO} \
    GROWL_IP=${GROWL_IP:-127.0.0.1} \
    GROWL_PORT=${GROWL_PORT:-23053}

# set container labels
LABEL build_version="Media-Converter, Version: 2.0.2, Build-date: 26-Dec-2020" maintainer="parker-hemphill"

# Copy shell scripts to /opt
COPY functions /opt/
COPY media-converter /opt/
COPY compile_binaries /opt/

# Set scripts as executable
RUN /opt/compile_binaries

# Run the command on container start
ENTRYPOINT ["/opt/media-converter"]
