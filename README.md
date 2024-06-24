# Docker + Nginx + RTMP

A Dockerfile installing NGINX, nginx-rtmp-module and FFmpeg from source with default settings for HLS live streaming. Built on Alpine Linux.

* Nginx 1.27.0 (Stable version compiled from source)
* nginx-rtmp-module 1.2.2 (compiled from source)
* ffmpeg 7.0 (compiled from source)
* Default HLS settings (See: [nginx.conf](nginx.conf))

Originally forked from https://github.com/codions/docker-stream-server, this version contains newer Nginx and Ffmpeg 🙇 versions.
Under the hood, still has the ability to support S3FS, however, currently is broken, see the Docker file for my struggles of installing the requirements for S3FS support.
If you don't need S3FS support, you are good to go.

## Usage

Run container with local storage:
```
docker compose up --build
```

Stream live content to:
```
rtmp://<server ip>:1935/stream/$STREAM_NAME
```

### OBS Configuration
* Stream Type: `Custom Streaming Server`
* URL: `rtmp://localhost:1935/stream`
* Example Stream Key: `hello`

### Watch Stream using Local Storage
* Load up the example hls.js player in your browser:
```
http://localhost:8080/player.html?url=http://localhost:8080/live/hello.m3u8
```

* Or in Safari, VLC or any HLS player, open:
```
http://localhost:8080/live/$STREAM_NAME.m3u8
```
* Example Playlist: `http://localhost:8080/live/hello.m3u8`
* [HLS.js Player](https://hls-js.netlify.app/demo/?src=http%3A%2F%2Flocalhost%3A8080%2Flive%2Fhello.m3u8)
* FFplay: `ffplay -fflags nobuffer rtmp://localhost:1935/stream/hello`


### SSL 
To enable SSL, see [nginx.conf](nginx.conf) and uncomment the lines:
```
listen 443 ssl;
ssl_certificate     /opt/certs/example.com.crt;
ssl_certificate_key /opt/certs/example.com.key;
```

> This will enable HTTPS using a self-signed certificate supplied in [/certs](/certs). If you wish to use HTTPS, it is highly recommended to obtain your own certificates and update the `ssl_certificate` and `ssl_certificate_key` paths.

## Credits
* https://github.com/codions/docker-stream-server
* https://github.com/alfg/docker-nginx-rtmp
* https://github.com/TareqAlqutami/rtmp-hls-server
* https://github.com/efriandika/streaming-server

## Resources
* https://alpinelinux.org/
* http://nginx.org
* https://github.com/arut/nginx-rtmp-module
* https://www.ffmpeg.org
* https://obsproject.com
* https://github.com/s3fs-fuse/s3fs-fuse
