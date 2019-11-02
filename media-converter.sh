#!/bin/bash
# Location to create log file
log=/tmp/media-converter.log

# Clear log file
cat /dev/null > $log

# Add "media" user and group, and map them to provided UID/GID or 1000 if not provided
# User will show as "media" inside container but will map to the correct UID outside container
groupadd -g $PGID media
useradd -u $PUID -g media media
echo "\"media\" user is mapped to external UID $(id -u media)"
echo "\"media\" group is mapped to external GID $(id -g media)"

# Check if /torrent and needed directories exist in mapped volume and create if needed
if [[ ! -d /torrent ]]
then
  mkdir /torrent
  chown media:media /torrent
  echo "Created /torrent" >> $log
else
  echo "/torrent is owned by user/group $(ls -l -d /torrent|awk '{print $3":"$4}')" >> $log
fi

for folder in Logs Unsorted Complete Download
do
  if [[ ! -d /torrent/$folder ]]
  then
    mkdir /torrent/$folder
    chown media:media /torrent/$folder
    echo "Created /torrent/$folder" >> $log
  else
    echo "/torrent/$folder is owned by user/group $(ls -l -d /torrent/$folder|awk '{print $3":"$4}')" >> $log
  fi
done

for folder in Movies TVShows Convert IMPORT
do
  if [[ ! -d /torrent/Complete/$folder ]]
  then
    mkdir /torrent/Complete/$folder
    chown media:media /torrent/Complete/$folder
    echo "Created /torrent/Complete/$folder" >> $log
  else
    echo "/torrent/Complete/$folder is owned by user/group $(ls -l -d /torrent/Complete/$folder|awk '{print $3":"$4}')" >> $log
  fi
done

for folder in Convert IMPORT
do
  for media_folder in TVShows Movies
  do
    if [[ ! -d /torrent/Complete/$folder/$media_folder ]]
    then
      mkdir /torrent/Complete/$folder/$media_folder
      chown media:media /torrent/Complete/$folder/$media_folder
      echo "Created /torrent/Complete/$folder/$media_folder" >> $log
    else
      echo "/torrent/Complete/$folder/$media_folder is owned by user/group $(ls -l -d /torrent/Complete/$folder/$media_folder|awk '{print $3":"$4}')" >> $log
    fi
  done
done

# Install the crontab to look for media files to convert evert 2 minutes
# The tail is needed to keep the docker container running
cron /etc/crontabs/root && tail -f /var/log/cron.log
