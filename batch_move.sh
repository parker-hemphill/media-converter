#!/bin/bash

export PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
pidfile=/var/tmp/batch_move.pid

if [ -f ${pidfile} ]; then
  pid=$(cat ${pidfile})
  if ps -p ${pid} > /dev/null 2>&1; then
    echo "Process already running"
    exit 1
  else
    ## Process not found assume not running
    if ! echo $$ > ${pidfile}; then
      echo "Could not create PID file"
      exit 1
    fi
  fi
else
  if ! echo $$ > ${pidfile}; then
    echo "Could not create PID file"
    exit 1
  fi
fi

# Set variables to point to directories for file lo$CATions
MOVIE_ADD="/torrent/Complete/Movies"
TV_ADD="/torrent/Complete/TVShows"

MOVIE_CONVERT="/torrent/Complete/Convert/Movies"
TV_CONVERT="/torrent/Complete/Convert/TVShows"

# This clears any files that might be sample media files
find "${TV_ADD}" -type f -not -name '*sample*' -size +50M -regex '.*\.\(avi\|mod\|mpg\|mp4\|m4v\|mkv\)' -exec mv {} ${TV_CONVERT}/ \;
find "${MOVIE_ADD}" -type f -not -name '*sample*' -size +500M -regex '.*\.\(avi\|mod\|mpg\|mp4\|m4v\|mkv\)' -exec mv {} ${MOVIE_CONVERT}/ \;

# Remove old downloaded files that are older than a week
find ${TV_ADD}/ -ctime +7 -exec rm -rf {} +
find ${MOVIE_ADD}/ -ctime +7 -exec rm -rf {} +
