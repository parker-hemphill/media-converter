#!/bin/bash
PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
FIND=/usr/bin/find
CAT=/bin/cat
RM=/bin/rm
MV=/bin/mv
ECHO=/bin/echo
PS=/bin/ps

#Check if script is running already.  This prevents multiple encode jobs from running since this script is designed to run manually or invoked from crontab.
PIDFILE=/var/tmp/encode_move.pid
if [ -f $PIDFILE ]
then
  PID=$($CAT $PIDFILE)
  $PS -p $PID > /dev/null 2>&1
  if [ $? -eq 0 ]
  then
    $ECHO "Process already running"
    exit 1
  else
    ## Process not found assume not running
    $ECHO $$ > $PIDFILE
    if [ $? -ne 0 ]
    then
      $ECHO "Could not create PID file"
      exit 1
    fi
  fi
else
  $ECHO $$ > $PIDFILE
  if [ $? -ne 0 ]
  then
    $ECHO "Could not create PID file"
    exit 1
  fi
fi

#Set variables to point to directories for file lo$CATions
MOVIE_ADD="/torrent/Complete/Movies"
TV_ADD="/torrent/Complete/TVShows"

MOVIE_CONVERT="/torrent/Complete/Convert/Movies"
TV_CONVERT="/torrent/Complete/Convert/TVShows"

#This clears any files that might be sample media files
$FIND "$TV_ADD" -type f -not -name '*sample*' -size +50M -regex '.*\.\(avi\|mod\|mpg\|mp4\|m4v\|mkv\)' -exec $MV {} $TV_CONVERT/ \;
$FIND "$MOVIE_ADD" -type f -not -name '*sample*' -size +500M -regex '.*\.\(avi\|mod\|mpg\|mp4\|m4v\|mkv\)' -exec $MV {} $MOVIE_CONVERT/ \;

$FIND $TV_ADD/ -ctime +7 -exec $RM -rf {} +
$FIND $MOVIE_ADD/ -ctime +7 -exec $RM -rf {} +
