#!/bin/bash

export PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

# Location to create log file
log=/tmp/media-converter.log

# Clear log file and inject start-up time
echo -e "Media-converter container started $(date "+%D %H:%M")\n" > $log
[[ ${GROWL} != NO ]] && gntp-send -a Media-Converter -n 'Start-up' -s ${GROWL_IP}:${GROWL_PORT} Media-Converter "Media-Converter container started $(date "+%D %H:%M")"

# Add "media" user and group, and map them to provided UID/GID or 1000 if not provided
# User will show as "media" inside container but will map to the correct UID outside container
groupadd -g $PGID media
useradd -s /bin/bash -m -u $PUID -g media media
echo "\"media\" user is mapped to external UID $(id -u media)"
echo "\"media\" group is mapped to external GID $(id -g media)"

# Set timezone
echo "$TZ" > /etc/timezone
dpkg-reconfigure -f noninteractive tzdata

# Create dummyfile so we can get creation date for container
[[ ! -f /var/tmp/.media-converter.create ]] && touch /var/tmp/.media-converter.create

# Set mod time of dummyfile so we can generate uptime for container
touch /var/tmp/.media-converter.uptime

# Check if /torrent and needed directories exist in mapped volume and create if needed
if [[ ! -d /torrent ]]; then
  mkdir /torrent
  chown media:media /torrent
  echo "Created /torrent" >> $log
  [[ ${GROWL} != NO ]] && gntp-send -a Media-Converter -n 'NOTIFY' -s ${GROWL_IP}:${GROWL_PORT} Media-Converter "Created Torrent directory inside container"
else
  echo "/torrent is owned by user/group $(ls -l -d /torrent|awk '{print $3":"$4}')" >> $log
fi

for folder in Logs Unsorted Complete Download
do
  if [[ ! -d /torrent/$folder ]]; then
    mkdir /torrent/$folder
    chown media:media /torrent/$folder
    echo "Created /torrent/$folder" >> $log
    [[ ${GROWL} != NO ]] && gntp-send -a Media-Converter -n 'NOTIFY' -s ${GROWL_IP}:${GROWL_PORT} Media-Converter "Created /torrent/$folder inside container"
  else
    echo "/torrent/$folder is owned by user/group $(ls -l -d /torrent/$folder|awk '{print $3":"$4}')" >> $log
  fi
done

for folder in Movies TVShows Convert IMPORT
do
  if [[ ! -d /torrent/Complete/$folder ]]; then
    mkdir /torrent/Complete/$folder
    chown media:media /torrent/Complete/$folder
    echo "Created /torrent/Complete/$folder" >> $log
    [[ ${GROWL} != NO ]] && gntp-send -a Media-Converter -n 'NOTIFY' -s ${GROWL_IP}:${GROWL_PORT} Media-Converter "Created /torrent/Complete/$folder"
  else
    echo "/torrent/Complete/$folder is owned by user/group $(ls -l -d /torrent/Complete/$folder|awk '{print $3":"$4}')" >> $log
  fi
done

for folder in Convert IMPORT
do
  for media_folder in TVShows Movies
  do
    if [[ ! -d /torrent/Complete/$folder/$media_folder ]]; then
      mkdir /torrent/Complete/$folder/$media_folder
      chown media:media /torrent/Complete/$folder/$media_folder
      echo "Created /torrent/Complete/$folder/$media_folder" >> $log
      [[ ${GROWL} != NO ]] && gntp-send -a Media-Converter -n 'NOTIFY' -s ${GROWL_IP}:${GROWL_PORT} Media-Converter "Created /torrent/Complete/$folder/$media_folder"
    else
      echo "/torrent/Complete/$folder/$media_folder is owned by user/group $(ls -l -d /torrent/Complete/$folder/$media_folder|awk '{print $3":"$4}')" >> $log
    fi
  done
done

# Run infinite loop to move media to convert directory and then run media conversion before sleeping for 2 minutes before checking for media again
if [[ $ENCODE == "x264" ]]; then
  echo -e "\nUsing h264 codec for HandbrakeCLI" >> $log
  sudo -u media bash -c "while :; do /opt/batch_move.sh; sleep 5; /opt/convert_tv.sh x264 $GROWL $GROWL_IP $GROWL_PORT; /opt/convert_movie.sh x264 $GROWL $GROWL_IP $GROWL_PORT; sleep 25; done"
elif [[ $ENCODE == "x265" ]]; then
  echo -e "\nUsing h265 codec for HandbrakeCLI" >> $log
  sudo -u media bash -c "while :; do /opt/batch_move.sh; sleep 5; /opt/convert_tv.sh x265 $GROWL $GROWL_IP $GROWL_PORT; /opt/convert_movie.sh x265 $GROWL $GROWL_IP $GROWL_PORT; sleep 25; done"
else
  echo "Invalid encoder, choose either \"x264\" or \"x265\" in docker variables" >> $log
  [[ ${GROWL} != NO ]] && gntp-send -a Media-Converter -n 'Error' -s ${GROWL_IP}:${GROWL_PORT} Media-Converter "Invalid encoder, choose either \"x264\" or \"x265\" in docker variables"
fi
