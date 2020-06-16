#!/bin/bash

export PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

# Location to create log file
log=/tmp/media-converter.log

# Clear log file and inject start-up time
echo -e "Media-converter container started $(date "+%D %H:%M")\n" > ${log}
[[ ${GROWL} != NO ]] && gntp-send -a Media-Converter -n NOTIFY -s ${GROWL_IP}:${GROWL_PORT} Media-Converter "Media-Converter container started $(date "+%D %H:%M")"

# Add "media" user and group, and map them to provided UID/GID or 1000 if not provided
# User will show as "media" inside container but will map to the correct UID outside container
groupadd -g ${PGID} media
useradd -s /bin/bash -m -u ${PUID} -g media media
echo "\"media\" user is mapped to external UID $(id -u media)"
echo "\"media\" group is mapped to external GID $(id -g media)"

# Set timezone
echo ${TZ}|sudo tee /etc/timezone
dpkg-reconfigure -f noninteractive tzdata

# Create dummyfile so we can get creation date for container
[[ ! -f /var/tmp/.media-converter.create ]] && touch /var/tmp/.media-converter.create

# Set mod time of dummyfile so we can generate uptime for container
touch /var/tmp/.media-converter.uptime

# Check if /torrent is mounted to an external volume
if [[ ! $(mountpoint /torrent) ]]; then
  echo "external media directory NOT mounted"
  [[ ${GROWL} != NO ]] && gntp-send -a Media-Converter -n NOTIFY -s ${GROWL_IP}:${GROWL_PORT} Media-Converter "media directory NOT mounted to external volume"
  exit 1
fi

# Check if /torrent is writeable by media user
sudo -u media bash -c 'if [[ -w /torrent ]]; then echo "media directory writeable by UID ${PUID}" >> ${log}; else echo "media directory NOT writeable by UID ${PUID}" >> ${log}; [[ ${GROWL} != NO ]] && gntp-send -a Media-Converter -n ERROR -s ${GROWL_IP}:${GROWL_PORT} Media-Converter "Torrent directory NOT writeable by UID ${PUID}"; exit 1; fi'

# Check if /torrent and needed directories exist in mapped volume and create if needed
for folder in Logs Unsorted Complete Download
do
  if [[ ! -d /torrent/${folder} ]]; then
    sudo -u media bash -c "mkdir /torrent/${folder}"
    echo "Created /torrent/${folder}" >> ${log}
    [[ ${GROWL} != NO ]] && gntp-send -a Media-Converter -n NOTIFY -s ${GROWL_IP}:${GROWL_PORT} Media-Converter "Created /torrent/${folder} inside container"
  fi
done

for folder in Movies TVShows Convert IMPORT
do
  if [[ ! -d /torrent/Complete/${folder} ]]; then
    sudo -u media bash -c "mkdir /torrent/Complete/${folder}"
    echo "Created /torrent/Complete/${folder}" >> ${log}
    [[ ${GROWL} != NO ]] && gntp-send -a Media-Converter -n NOTIFY -s ${GROWL_IP}:${GROWL_PORT} Media-Converter "Created /torrent/Complete/${folder}"
  fi
done

for folder in Convert IMPORT
do
  for media_folder in TVShows Movies
  do
    if [[ ! -d /torrent/Complete/${folder}/${media_folder} ]]; then
      sudo -u media bash -c "mkdir /torrent/Complete/${folder}/${media_folder}"
      echo "Created /torrent/Complete/${folder}/${media_folder}" >> ${log}
      [[ ${GROWL} != NO ]] && gntp-send -a Media-Converter -n NOTIFY -s ${GROWL_IP}:${GROWL_PORT} Media-Converter "Created /torrent/Complete/${folder}/${media_folder}"
    fi
  done
done

# Run infinite loop to move media to convert directory and then run media conversion before sleeping for 2 minutes before checking for media again
if [[ ${ENCODE} == "x264" ]]; then
  echo -e "\nUsing h264 codec for HandbrakeCLI" >> ${log}
  sudo -u media bash -c "while :; do /opt/batch_move.sh; sleep 5; /opt/convert_media.sh x264 $GROWL $GROWL_IP $GROWL_PORT TVShows; /opt/convert_media.sh x264 $GROWL $GROWL_IP $GROWL_PORT Movies; sleep 25; done"
elif [[ ${ENCODE} == "x265" ]]; then
  echo -e "\nUsing h265 codec for HandbrakeCLI" >> ${log}
  sudo -u media bash -c "while :; do /opt/batch_move.sh; sleep 5; /opt/convert_media.sh x265 $GROWL $GROWL_IP $GROWL_PORT Movies; /opt/convert_media.sh x265 $GROWL $GROWL_IP $GROWL_PORT Movies; sleep 25; done"
else
  echo "Invalid encoder, choose either \"x264\" or \"x265\" in docker variables" >> ${log}
  [[ ${GROWL} != NO ]] && gntp-send -a Media-Converter -n ERROR -s ${GROWL_IP}:${GROWL_PORT} Media-Converter "Invalid encoder, choose either \"x264\" or \"x265\" in docker variables"
fi
