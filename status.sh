#!/bin/bash

#Set colors for status message below
red='\e[1;31m'
yellow='\e[1;33m'
blue='\e[1;34m'
green='\e[1;32m'
white='\e[1;97m'
clear='\e[0m'

#Print status messages
print_error(){ echo -e "$red[ERROR]: $1$clear"; }
print_warning(){ echo -e "$yellow[WARNING]: $1$clear"; }
print_ok(){ echo -e "$green[OK]: $1$clear"; }
print_notice(){ echo -e "$white[NOTICE]: $1$clear"; }

cat /dev/null > /tmp/converted_media
sleep 2

#Check a process to see if it is running and provide the PID of process
CHECK_PROCESS(){
PID_PROCESS=$(pgrep -u ${3} -f "${1}")
[ -z "${PID_PROCESS}" ] && print_error "${2} is NOT running" || print_ok "${2} is running PID:[${PID_PROCESS}]"
}

#Set "Movie" or "Movies" in convert count
MOVIE_GRAMMAR(){
if [[ $MOVIE_COUNT == 1 ]] 
then
  echo "There is $MOVIE_COUNT Movie"
else
  echo "There are $MOVIE_COUNT Movies"
fi
}

#Set "show" or "shows" in convert count
TV_GRAMMAR(){
if [[ $TV_COUNT == 1 ]]
then
  echo "There is $TV_COUNT TV episode"
else
  echo "There are $TV_COUNT TV episodes"
fi
}

#Check free space for a device and provide mount point
CHECK_SPACE(){
declare -i FULL=$(df -h "$1"|tail -1|awk '{print $5}'|tr -d %)
(( $FULL < 60 )) && print_ok "${1} is ${FULL}% full"
(( $FULL > 60 )) && (( $FULL < 75 )) && print_warning "${1} is ${FULL}% full"
(( $FULL > 75 )) && print_error "${1} is ${FULL}% full"
}

clear
LOAD=$(cat /proc/loadavg | awk '{print $1, $2, $3}')
print_notice "Performing health checks [`date +%H:%M`]"
echo -e "         \e[1;97m $(perl -e 'print ucfirst(`uptime -p`);')"
echo -e "          SYS Load: \e[1;34m${LOAD}\e[0m"

CHECK_SPACE "/torrent"

declare -i TV_COUNT=`ls /torrent/Complete/Convert/TVShows/ | egrep -v "-converted.mp4|.srt"`
declare -i MOVIE_COUNT=`ls /torrent/Complete/Convert/Movies/ | egrep -v "-converted.mp4|.srt"`

print_notice "`TV_GRAMMAR` waiting to be encoded"
print_notice "`MOVIE_GRAMMAR` waiting to be encoded"
[[ `pgrep ffmpeg` ]] && print_notice "FFMPEG is creating:\n$(ps -ef|grep ffmpeg|grep -o "copy .*"|sed 's@copy /torrent/Complete/Convert/@@')"
if [[ `pgrep HandBrakeCLI` ]]; then
  STATUS=$(tail -1 /tmp/converted_media)
  ETA=$(echo $STATUS|awk -F"," '{print $NF}'| sed 's/)//')
  PERCENT=$(echo $STATUS|awk '{print $6}')
  print_notice "HandBrake is converting:\n$(ps -ef|grep -o "\-\-output.*"|cut -c 36-|sed 's/-converted.mp4//')\n$PERCENT %,$ETA"
fi
