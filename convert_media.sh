#!/bin/bash

ENCODE=${1}
GROWL=${2}
GROWL_IP=${3}
GROWL_PORT=${4}
MEDIA=${5}

export PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
pidfile=/var/tmp/encode_media.pid

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

# Variables
handbrake_options=" --markers --encoder ${ENCODE} --encopts vbv-maxrate=25000:vbv-bufsize=31250:ratetol=inf --crop 0:0:0:0"

# Remove stale conversion files
rm /torrent/Complete/Convert/${MEDIA}/*-converted.mp4 > /dev/null 2>&1

#Set location for log file
log='/torrent/Logs/converted.log'

#Set colors for status message
red='\e[1;31m'
yellow='\e[1;33m'
blue='\e[1;34m'
green='\e[1;32m'
white='\e[1;97m'
clear='\e[0m'

#Functions
print_error(){ echo -e "$red[ERROR]: $1$clear"; }
print_warning(){ echo -e "$yellow[WARNING]: $1$clear"; }
print_ok(){  echo -e "$green[OK]: $1$clear"; }

#Script actions
if [[ ! $(ls /torrent/Complete/Convert/${MEDIA}) ]]; then
  exit 0
fi

CHECK_MKV(){
if [[ -f "${input%.*}.mkv" ]] && [[ -f "${input%.*}.mp4" ]]; then
  rm "${input%.*}.mp4"
  exit 0
fi
if [ "${input: -4}" == ".mkv" ]; then
   if ffmpeg -threads 4 -i "${input}" -codec copy "${input%.*}.mp4"; then
     rm "${input}"
     exit 0
   else
     print_error "FFMPEG convert of ${input} FAILED"
     [[ ${GROWL} != NO ]] && gntp-send -a Media-Converter -n ERROR -s ${GROWL_IP}:${GROWL_PORT} Media-Converter "FFMPEG convert of \"${input}\" FAILED"
     exit 1
   fi
fi
}

CONVERT_FILE(){
[[ ${GROWL} != NO ]] && gntp-send -a Media-Converter -n CONVERSION-START -s ${GROWL_IP}:${GROWL_PORT} Media-Converter "\"${log_input}\" conversion started"
start_time=$(date +%s)
handbrake_options="${handbrake_options} --aencoder faac --normalize-mix 1 --mixdown stereo --gain 10.0 --drc 2.5"

width="$(mediainfo --Inform='Video;%Width%' "${input}")"
height="$(mediainfo --Inform='Video;%Height%' "${input}")"

if ((${width} > 1280)) || ((${height} > 720)); then
  max_bitrate="4000"
elif ((${width} > 720)) || ((${height} > 576)); then
  max_bitrate="3500"
else
  max_bitrate="3000"
fi

min_bitrate="$((max_bitrate / 2))"
bitrate="$(mediainfo --Inform='Video;%BitRate%' "${input}")"

if [ ! "${bitrate}" ]; then
  bitrate="$(mediainfo --Inform='General;%OverallBitRate%' "${input}")"
  bitrate="$(((bitrate / 10) * 9))"
fi

if [ "${bitrate}" ]; then
  bitrate="$(((bitrate / 5) * 4))"
  bitrate="$((bitrate / 1000))"
  bitrate="$(((bitrate / 100) * 100))"
  if ((${bitrate} > ${max_bitrate})); then
    bitrate="${max_bitrate}"
  elif ((${bitrate} < $min_bitrate)); then
    bitrate="${min_bitrate}"
  fi
else
  bitrate="${min_bitrate}"
fi

handbrake_options="${handbrake_options} --vb ${bitrate}"
frame_rate="$(mediainfo --Inform='Video;%FrameRate_Original%' "${input}")"

if [ ! "${frame_rate}" ]; then
  frame_rate="$(mediainfo --Inform='Video;%FrameRate%' "${input}")"
fi

if [ "${frame_rate}" == '29.970' ]; then
  handbrake_options="${handbrake_options} --rate 23.976"
else
  handbrake_options="${handbrake_options} --rate 30 --pfr"
fi

channels="$(mediainfo --Inform='Audio;%Channels%' "${input}" | sed 's/[^0-9].*$//')"

if ((${channels} > 2)); then
  handbrake_options="${handbrake_options} --aencoder ca_aac,copy:ac3"
elif [ "$(mediainfo --Inform='General;%Audio_Format_List%' "${input}" | sed 's| /.*||')" == 'AAC' ]; then
  handbrake_options="${handbrake_options} --aencoder copy:aac"
fi

if [ "${frame_rate}" == '29.970' ]; then
  handbrake_options="${handbrake_options} --detelecine"
fi

HandBrakeCLI ${handbrake_options} --input "${input}" --output "${output}" 2>&1 | tee -a "/tmp/converted_media"

if [[ ${PIPESTATUS[0]} -eq 0 ]]; then
  stop_time=$(date +%s)
  total_time=$(( stop_time - start_time ))
  input_size=$(ls -lh "${input}"|awk '{print $5}')
  output_size=$(ls -lh "${output}"|awk '{print $5}')
  mv "${output}" "/torrent/Complete/IMPORT/${MEDIA}/"
  rm "${input}"
  if [[ ! -f ${log} ]]; then
    [[ ${GROWL} != NO ]] && gntp-send -a Media-Converter -n CONVERSION-COMPLETE -s ${GROWL_IP}:${GROWL_PORT} Media-Converter "\"${log_input}\" converted"
    echo "[Type ] [  Date  ] [  Convert Time  ] [  Original Filesize|Converted Filesize  ] Filename" >> $log
    echo "[TV   ] [$(date "+%D %H:%M")] [$(date -d@$TOTAL_TIME -u +%H:%M:%S)] [${input_size}|${output_size}] $log_input" >> $log
  else
    [[ ${GROWL} != NO ]] && gntp-send -a Media-Converter -n CONVERSION-COMPLETE -s ${GROWL_IP}:${GROWL_PORT} Media-Converter "\"${log_input}\" converted"
    echo "[TV   ] [$(date "+%D %H:%M")] [$(date -d@$TOTAL_TIME -u +%H:%M:%S)] [${input_size}|${output_size}] $log_input" >> $log
  fi
else
  [[ ${GROWL} != NO ]] && gntp-send -a Media-Converter -n ERROR -s ${GROWL_IP}:${GROWL_PORT} Media-Converter "\"${log_input}\" conversion FAILED"
  rm "${output}" > /dev/null 2>&1
fi
}

count=0
for filename in "`ls -t1 /torrent/Complete/Convert/${MEDIA}/|head -n 1`"
do
filename="/torrent/Complete/Convert/${MEDIA}/$filename"
  if [[ ${count} -lt 1 ]]; then
    input="${filename}"
    output="${input%\.*}-converted.mp4"
    log_input=$(echo "${input}"|sed 's/\/torrent\/Complete\/Convert\///')
    print_ok "Converting: ${input}\nFile"
    CHECK_MKV
    CONVERT_FILE
  else
    exit 0
  fi
count=1
done
