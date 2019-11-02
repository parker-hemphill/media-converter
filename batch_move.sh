#!/bin/bash

pidfile=/var/tmp/batch_move.pid
if [ -f $pidfile ]
then
  PID=$(cat $pidfile)
  ps -p $PID > /dev/null 2>&1
  if [ $? -eq 0 ]
  then
    echo "Process already running"
    exit 1
  else
    ## Process not found assume not running
    echo $$ > $pidfile
    if [ $? -ne 0 ]
    then
      echo "Could not create PID file"
      exit 1
    fi
  fi
else
  echo $$ > $pidfile
  if [ $? -ne 0 ]
  then
    echo "Could not create PID file"
    exit 1
  fi
fi

# Variables
TV_ADD=/torrent/Complete/TVShows
MOVIE_ADD=/torrent/Complete/Movies
TV_CONVERT=/torrent/Complete/Convert/TVShows
MOVIE_CONVERT=/torrent/Complete/Convert/Movies

#This ignores files that might be sample media files and small files which are probably also sample files
find "$TV_ADD" -type f -not -name '*sample*' -size +50M -regex '.*\.\(avi\|mod\|mpg\|mp4\|m4v\|mkv\)' -exec mv "{}" "$TV_CONVERT" \;
find "$MOVIE_ADD" -type f -not -name '*sample*' -size +500M -regex '.*\.\(avi\|mod\|mpg\|mp4\|m4v\|mkv\)' -exec mv "{}" "$MOVIE_CONVERT" \;

find $TV_ADD -type f -exec rm {} \;
find $TV_ADD -type d -exec rm {} \;
find $MOVIE_ADD -type f -exec rm {} \;
find $MOVIE_ADD -type d -exec rm {} \;
