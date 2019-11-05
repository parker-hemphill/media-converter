# parkerhemphill/media-converter
## A simple docker image that uses FFMPEG, media-info, and HandBrakeCLI to convert downloaded media into mp4
[![Docker Stars](https://img.shields.io/docker/stars/parkerhemphill/media-converter?maxAge=604800)](https://store.docker.com/community/images/parkerhemphill/media-converter) [![Docker Pulls](https://img.shields.io/docker/pulls/parkerhemphill/media-converter?maxAge=604800)](https://store.docker.com/community/images/parkerhemphill/media-converter)
### Flow of operations:
* 1: Download client places files in `'<volume>/Complete/<TVShows|Movies>'`
  * ~~Crontab runs every five minutes to move completed files from~~ Crontab was unreliable so instead we use an infinite loop to perform the move and convert actions with a wait of 2 minutes between checks.  First action is to move:  `'<volume>/Complete/<TVShows|Movies>'` to `'<volume>/Complete/Convert/<TVShows|Movies>'`
* 2: Files are converted
  * ~~Crontab runs every two minutes to convert media files in~~ Loop checks for media to convert in `'<volume>/Complete/Convert/<TVShows|Movies>'`
  * If file is an 'mkv' file *ffmpeg* converts into an 'mp4' file for conversion and removes 'mkv' file
  * *media-info* checks the height and width, along with other attributes to determine ideal converter settings, including bitrate for video
  * *HandBrakeCLI* uses the determined settings to convert the media into MP4 H264 media named **\<filename\>-converted.mp4**<br>
  NOTE: If container is shutdown in the middle of conversion it will remove existing \*-converted.mp4 files upon restart, since these would be an incomplete converted file 
* 3: Completed file is moved to `'<volume>/Complete/IMPORT/<TVShows|Movies>'`, ready to be ingested by SickChill, etc. into Plex/Jellyfin/Kodi library
  
### Notes:
* All files converted are added to a logfile located at **\<volume\>/Logs/converted.log**
* Upon start-up container will check '\<volume\>' and create the needed directories if they don't exist
* Container defaults to uid/gid 1000 if PUID/PGID aren't specified in the environment settings
* The easiest way to get up and running is to start the image, then go into the setup of your download client (SickChill/Deluge, etc) and set it to place completed media in `'<volume>/Complete/<TVShows|Movies>'`
* Set `'<volume>/Complete/IMPORT/<TVShows|Movies>'` as the *import* directory for your download client (SickChill, etc)
* EXAMPLE: You'd set your download client to place completed files in `'/media/torrent/Complete/<TVShows|Movies>'`, where they'll be grabbed and converted, then moved into `'/media/torrent/Complete/IMPORT/<TVShows|Movies>'` for your media manager to import to the Plex/Jellyfin/Kodi library
* Inside the docker container all paths are under `'/torrent'`, outside the container paths are relative to `'<volume>'`
 * On server: `'/media/torrent'`
 * Inside container: `'/torrent'`

## Docker-compose example
* In this example I use `'/media/torrent'` as the mount point on my server and UID "1000" to map my primary user to the container.  You can get the UID/GID of desired user by running `id <USER_NAME>`.  I.E. `id plex`
```
#docker-compose.yaml
version: '2.0'
services:
  media-converter:
    container_name: media-converter
    restart: unless-stopped
    image: parkerhemphill/media-converter:latest
    volumes:
      # Directory on server:Directory inside container
      - /media/torrent:/torrent
    environment:
      # UID and GID to map container "media" user to
      - PGID=1000
      - PUID=1000
```
## Docker run example
* In this example I use `'/media/torrent'` as the mount point on my server and UID "1000" to map my primary user to the container.  You can get the needed UID/GID by running `id <USER_NAME>`.  I.E. `id plex`
```
docker run -d \
  --name=media-converter \
  -e PUID=1000 \
  -e PGID=1000 \
  -v /media/torrent:/torrent \
  --restart unless-stopped \
  parkerhemphill/media-converter:latest
```
## Support
* Shell access while the container is running:<br>
 `docker exec -it media-converter /bin/bash`
* To check the logs of the container and directory creation:<br>
 `docker exec -it media-converter cat /tmp/media-converter.log`
* To see converted media:<br>
 `docker exec -it media-converter cat /torrent/Logs/converted.log` 
* Container version number:<br>
 `docker inspect -f '{{ index .Config.Labels "build_version" }}' media-converter`
* Image version number<br>
 `docker inspect -f '{{ index .Config.Labels "build_version" }}' parkerhemphill/media-converter`
