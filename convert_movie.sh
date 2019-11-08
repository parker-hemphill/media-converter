#!/bin/bash
ENCODE=$1
PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
pidfile=/var/tmp/encode_movie.pid

if [ -f $pidfile ]; then
  PID=$(cat $pidfile)
  ps -p $PID > /dev/null 2>&1
  if [ $? -eq 0 ]; then
    echo "Process already running"
    exit 1
  else
    ## Process not found assume not running
    echo $$ > $pidfile
    if [ $? -ne 0 ]; then
      echo "Could not create PID file"
      exit 1
    fi
  fi
else
  echo $$ > $pidfile
  if [ $? -ne 0 ]; then
    echo "Could not create PID file"
    exit 1
  fi
fi

#Variables
handbrake="/usr/bin/HandBrakeCLI" #Location of HandBrakeCLI
mediainfo="/usr/bin/mediainfo" #Location of mediainfo
ffmpeg="/usr/bin/ffmpeg" #Location of ffmpeg
handbrake_options=" --markers --encoder $ENCODE --encopts vbv-maxrate=25000:vbv-bufsize=31250:ratetol=inf --crop 0:0:0:0"
media_add="/torrent/Complete/Movies" #This is where your download client should place COMPLETED downloads of movies
media_convert="/torrent/Complete/Convert/Movies" #This is where completed downloads are moved to be processed 
media_import="/torrent/Complete/IMPORT/Movies" #This is the directory to point Sonarr, Sickrage, etc to as the post-processing directory or "completed downloads"

#Remove stale conversion files
rm $media_convert/*-converted.mp4 > /dev/null 2>&1

#Set location for log file
log="/torrent/Logs/converted.log"

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
if [[ ! $(ls "$media_convert") ]]; then
  print_ok "No files to encode, exiting"
  exit 0
fi

check_mkv(){
if [[ -f "${input%.*}.mkv" ]] && [[ -f "${input%.*}.mp4" ]]; then
  rm "${input%.*}.mp4"
  exit 0
fi

if [ "${input: -4}" == ".mkv" ]; then
   $ffmpeg -threads 4 -i "$input" -codec copy "${input%.*}.mp4"
   if [[ $? -eq 0 ]]; then
     rm "$input"
     exit 0
   else
     print_error "FFMPEG convert of $input FAILED"
     exit 1
   fi
fi
}

convert_file(){
START_TIME=$(date +%s)
handbrake_options="$handbrake_options --aencoder faac --normalize-mix 1 --mixdown stereo --gain 10.0 --drc 2.5"

width="$(mediainfo --Inform='Video;%Width%' "$input")"
height="$(mediainfo --Inform='Video;%Height%' "$input")"

if (($width > 1280)) || (($height > 720)); then
  max_bitrate="4000"
elif (($width > 720)) || (($height > 576)); then
  max_bitrate="3500"
else
  max_bitrate="3000"
fi

min_bitrate="$((max_bitrate / 2))"
bitrate="$(mediainfo --Inform='Video;%BitRate%' "$input")"

if [ ! "$bitrate" ]; then
  bitrate="$(mediainfo --Inform='General;%OverallBitRate%' "$input")"
  bitrate="$(((bitrate / 10) * 9))"
fi

if [ "$bitrate" ]; then
  bitrate="$(((bitrate / 5) * 4))"
  bitrate="$((bitrate / 1000))"
  bitrate="$(((bitrate / 100) * 100))"
  if (($bitrate > $max_bitrate)); then
    bitrate="$max_bitrate"
  elif (($bitrate < $min_bitrate)); then
    bitrate="$min_bitrate"
  fi
else
  bitrate="$min_bitrate"
fi

handbrake_options="$handbrake_options --vb $bitrate"
frame_rate="$(mediainfo --Inform='Video;%FrameRate_Original%' "$input")"

if [ ! "$frame_rate" ]; then
  frame_rate="$(mediainfo --Inform='Video;%FrameRate%' "$input")"
fi

if [ "$frame_rate" == '29.970' ]; then
  handbrake_options="$handbrake_options --rate 23.976"
else
  handbrake_options="$handbrake_options --rate 30 --pfr"
fi

channels="$(mediainfo --Inform='Audio;%Channels%' "$input" | sed 's/[^0-9].*$//')"

if (($channels > 2)); then
  handbrake_options="$handbrake_options --aencoder ca_aac,copy:ac3"
elif [ "$(mediainfo --Inform='General;%Audio_Format_List%' "$input" | sed 's| /.*||')" == 'AAC' ]; then
  handbrake_options="$handbrake_options --aencoder copy:aac"
fi

if [ "$frame_rate" == '29.970' ]; then
  handbrake_options="$handbrake_options --detelecine"
fi

$handbrake $handbrake_options --input "$input" --output "$output" 2>&1 | tee -a "/tmp/converted_movie"

if [[ ${PIPESTATUS[0]} -eq 0 ]]; then
  STOP_TIME=$(date +%s)
  TOTAL_TIME=$(( $STOP_TIME - $START_TIME ))
  input_size=$(ls -lh "${input}"|awk '{print $5}')
  output_size=$(ls -lh "${output}"|awk '{print $5}')
  mv "$output" "$media_import"
  rm "$input"
  log_input=$(echo "$input"|sed 's/\/torrent\/Complete\/Convert\///')
  if [[ ! -f $log ]]; then
    echo "[Type ] [  Date  ] [  Convert Time  ] [  Original Filesize|Converted Filesize  ] Filename" >> $log
    echo "[Movie] [$(date "+%D %H:%M")] [$(date -d@$TOTAL_TIME -u +%H:%M:%S)] [${input_size}|${output_size}] $log_input" >> $log
  else
    echo "[Movie] [$(date "+%D %H:%M")] [$(date -d@$TOTAL_TIME -u +%H:%M:%S)] [${input_size}|${output_size}] $log_input" >> $log
  fi
else
  rm "$output" > /dev/null 2>&1
fi
}

count=0
for filename in "`ls -t1 $media_convert/|head -n 1`"
do
filename="$media_convert/$filename"
  if [[ $count -lt 1 ]]; then
    input="$filename"
    output="${input%\.*}-converted.mp4"
    print_ok "Converting: $input\nFile"
    check_mkv
    convert_file
  else
    exit 0
  fi
count=1
done
