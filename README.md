# parkerhemphill/media-converter
## A simple docker image that uses FFMPEG, media-info, and HandBrakeCLI to convert downloaded media into mp4
## Current Version: 2.1.8 updated 2021-Apr-28
## NEW: Uses GitHub actions to rebuild with latest libraries every Sunday at midnight UTC.
### Update: 2.1.8 adds better support for failed files
### Update: 2.1.7 adds support for case insensitive filename extensions
### Update: 2.1.3 adds ARM support to image
### Update: 2.0.0 compiles the latest HandBrake and FFMPEG from source each time you build the container with the dockerfile.  Regular updates to the container also ensure any images pulled from dockerhub will also have a recent version of HandBrake and FFMPEG
[![Docker Stars](https://img.shields.io/docker/stars/parkerhemphill/media-converter)](https://store.docker.com/community/images/parkerhemphill/media-converter) 
[![Docker Pulls](https://img.shields.io/docker/pulls/parkerhemphill/media-converter)](https://store.docker.com/community/images/parkerhemphill/media-converter)
### Flow of operations:
* 1: Download client places files in `'<volume>/Complete/<TVShows|Movies>'`
  * ~~Crontab runs every five minutes to move completed files from~~ Crontab was unreliable so instead we use an infinite loop to perform the move and convert actions with a wait of 30 seconds between checks.  First action is to move:  `'<volume>/Complete/<TVShows|Movies>'` to `'<volume>/Complete/Convert/<TVShows|Movies>'`
* 2: Files are converted
  * ~~Crontab runs every two minutes to convert media files in~~ Loop checks for media to convert in `'<volume>/Complete/Convert/<TVShows|Movies>'`
  * If file is an 'mkv' file *ffmpeg* converts into an 'mp4' file for conversion and removes 'mkv' file
  * *media-info* checks the height and width, along with other attributes to determine ideal converter settings, including bitrate for video
  * *HandBrakeCLI* uses the determined settings to convert the media into MP4 H264 media named **\<filename\>-converted.mp4**<br>
  NOTE: If container is shutdown in the middle of conversion it will remove existing \*-converted.mp4 files upon restart, since these would be an incomplete converted file 
* 3: Completed file is moved to `'<volume>/Complete/IMPORT/<TVShows|Movies>'`, ready to be ingested by SickChill, etc. into Plex/Jellyfin/Kodi library
  
### Notes:
* ~~Growl Notifications for macOS users.  Simply pass GROWL=YES, GROWL_IP=<mac_ip>, and GROWL_PORT=<growl_port> ENV variables~~
 * Removed Growl since it is no longer actively developed for macOS
* The option to choose h264 or HVEC (h265) has been added to the image, simply pass **"- ENCODE=<x264|x265>"** to environment for container (**Defaults to h264 if variable isn't set**) 
* ~~All files converted are added to a logfile located at **\<volume\>/Logs/converted.log**~~
 * UPDATE 2.1.5: Log files are now created under **\<volume\>/logs** and contain individual logfiles for MKV, MP4, FAILED, and handbrake command used to convert each media file
* Upon start-up container will check if '\<volume\>' is writeable by PUID and create the needed directories if they don't exist
* Container defaults to uid/gid 1000 if PUID/PGID aren't specified in the environment settings
* The easiest way to get up and running is to start the image, then go into the setup of your download client (SickChill/Deluge, etc) and set it to place completed media in `'<volume>/Complete/<TVShows|Movies>'`
* Set `'<volume>/Complete/IMPORT/<TVShows|Movies>'` as the *import* directory for your download client (SickChill, etc)
* EXAMPLE: You'd set your download client to place completed files in `'/media/media/Complete/<TVShows|Movies>'`, where they'll be grabbed and converted, then moved into `'/media/media/Complete/IMPORT/<TVShows|Movies>'` for your media manager to import to the Plex/Jellyfin/Kodi library
* Inside the docker container all paths are under `'/media'`, outside the container paths are relative to `'<volume>'`
 * On host: `'/media/media'`
 * Inside container: `'/media'`
## Docker-compose example
* In this example I use `'/media/media'` as the mount point on my server and UID "1000" to map my primary user to the container.  You can get the UID/GID of desired user by running `id <USER_NAME>`.  I.E. `id plex`
* Change "TZ" to match your desired timezone.  A vaild list can be found at https://www.wikiwand.com/en/List_of_tz_database_time_zones under the "TZ database name" column.  Default is "America/New_York"
* Change "ENCODE" to `'x264'` or `'x265'` to use h264 (default if option isn't set) or h265 (HVEC)
```
#docker-compose.yaml
version: "3"
services:
  media-converter:
    image: parkerhemphill/media-converter:latest
    container_name: media-converter
    network_mode: host
    environment:
      - PUID=1000
      - PGID=1000
      - TZ=America/New_York
      - ENCODE=x264
    volumes:
      - /media/media:/media
    restart: unless-stopped
```
## Docker run example
* In this example I use `'/media/media'` as the mount point on my server and UID "1000" to map my primary user to the container.  You can get the needed UID/GID by running `id <USER_NAME>`.  I.E. `id plex`
* Change "TZ" to match your desired timezone.  A vaild list can be found at https://www.wikiwand.com/en/List_of_tz_database_time_zones under the "TZ database name" column.  Default is "America/New_York"
* Change "ENCODE" to `'x264'` or `'x265'` to use h264 (default if option isn't set) or h265 (HVEC)
```
docker run -d \
  --name=media-converter \
  -e PUID=1000 \
  -e PGID=1000 \
  -e TZ=America/New_York \
  -e ENCODE=x264 \
  -v /media/media:/media \
  --restart unless-stopped \
  parkerhemphill/media-converter:latest
```
## Support
* Shell access while the container is running:<br>
 `docker exec -it media-converter /bin/bash`
* Monitor currently encoding media:<br>
 `docker exec -it media-converter status`
* Container version number:<br>
 `docker inspect -f '{{ index .Config.Labels "build_version" }}' media-converter`
* Image version number:<br>
 `docker inspect -f '{{ index .Config.Labels "build_version" }}' parkerhemphill/media-converter`
