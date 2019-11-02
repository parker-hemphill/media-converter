# parker-media_converter
## A simple docker image that uses FFMPEG, media-info, and HandBrakeCLI to convert downloaded media into mp4
[![Docker Stars](https://img.shields.io/docker/stars/parkerhemphill/media-converter.svg?maxAge=604800)](https://store.docker.com/community/images/parkerhemphill/media-converter) [![Docker Pulls](https://img.shields.io/docker/pulls/parkerhemphill/media-converter.svg?maxAge=604800)](https://store.docker.com/community/images/parkerhemphill/media-converter)
### Flow of operations (For TVShows but is identical for Movies, minus the different directory):
* 1: Download client places files in `'\<volume\>/Complete/TVShows'`
  * Crontab runs every five minutes to move completed files from `'\<volume\>/Complete/TVShows'` to `'\<volume\>/Complete/Convert/TVShows'`
* 2: Files are converted
  * Crontab runs every two minutes to convert media files in `'\<volume\>/Complete/Convert/TVShows'`
  * If file is an 'mkv' file *ffmpeg* converts into an 'mp4' file for conversion and removes 'mkv' file
  * *media-info* checks the height and width, along with other attributes to determine ideal converter settings, including bitrate for video
  * *HandBrakeCLI* uses the determined settings to convert the media into **\<filename\>-converted.mp4**
  NOTE: If container is shutdown in the middle of conversion it will remove existing \*-converted.mp4 files upon restart, since these would be an incomplete converted file 
* 3: Completed file is moved to `'\<volume\>/Complete/IMPORT/TVShows'`, ready to be ingested by SickChill, etc. into Plex library
  
### Notes:
* Upon start-up container will check \'<volume'\> and create the needed directories if they don't exist
* Container defaults to uid/gid 1000 if PUID/PGID aren't specified in the environment settings
* The easiest way to get up and running is to start the image, then go into the setup of your download client (SickChill, etc) and set it to place completed media in '\<volume\>/Complete/TVShows'
* Set `'\<volume\>/Complete/IMPORT/TVShows'` as the *import* directory for your download client (SickChill, etc)
* EXAMPLE: You'd set your download client to place completed files in `/media/torrent/Complete/TVShows`, where they'll be grabbed and converted, then moved into `/media/torrent/Complete/IMPORT/TVShows` for your media manager to import to the Plex library
  * NOTE: In this example I've used '/media/torrent' as the directory to map to my docker container

## Docker-compose example
* In this example I use `/media/torrent` as the mount point on my server and UID "1000" to map my primary user to the container.  You can get the UID/GID of desired user by running `id <USER_NAME>`.  I.E. `id plex`
```
#docker-compose.yaml
version: '2.0'
services:
  parker-media_converter:
    container_name: media_converter
    restart: unless-stopped
    image: parker-media_converter:latest
    volumes:
      # Directory on server:Directory inside container.  You shouldn't change the right side of the semi-colon
      - /media/torrent:/torrent
    environment:
      # UID and GID to map container "media" user to
      - PGID=1000
      - PUID=1000
```
## Docker run example
* In this example I use `/media/torrent` as the mount point on my server and UID "1000" to map my primary user to the container.  You can get the needed UID/GID by running `id <USER_NAME>`.  I.E. `id plex`
```
docker run -d \
  --name=media_converter \
  -e PUID=1000 \
  -e PGID=1000 \
  -v /media/torrent:/torrent \
  --restart unless-stopped \
  parker-media_converter:latest
```
## Support
* Shell access while the container is running:
 `docker exec -it media_converter /bin/bash`
* To check the logs of the container and directory creation:
 `docker exec -it media_converter cat /tmp/media-converter.log`
* Container version number:
 `docker inspect -f '{{ index .Config.Labels "build_version" }}' media_converter`
* Image version number
 `docker inspect -f '{{ index .Config.Labels "build_version" }}' parker-media_converter`
