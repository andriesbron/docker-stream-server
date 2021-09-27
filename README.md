# Docker + Nginx + RTMP + S3FS (S3-Compatible Object Storage)
A Dockerfile installing NGINX, nginx-rtmp-module and FFmpeg from source with default settings for HLS live streaming. Built on Alpine Linux.

* Nginx 1.16.1 (Stable version compiled from source)
* nginx-rtmp-module 1.2.1 (compiled from source)
* ffmpeg 4.2.1 (compiled from source)
* Default HLS settings (See: [nginx.conf](nginx.conf))
* S3FS Fuse (Amazon S3 Integration)

## Usage

### Server

* Run container from source:
```
docker run --rm --privileged -it -e AWS_ACCESS_KEY_ID=xxxxxxxxxxxxxxxxxxxx -e AWS_SECRET_ACCESS_KEY=xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx -e AWS_S3_BUCKET_NAME=xxxx-yyyy-zzzz -e AWS_S3_REGION=us-east-1 -p 1935:1935 -p 8080:80 ghcr.io/codions/stream-server/stream-server:latest
```

* Stream live content to:
```
rtmp://<server ip>:1935/stream/$STREAM_NAME
```

### OBS Configuration
* Stream Type: `Custom Streaming Server`
* URL: `rtmp://localhost:1935/stream`
* Example Stream Key: `hello`

## Using AWS and CloudFront

### Watch Stream

Access by using your S3 public URL.

For example => `https://your-s3-bucket.s3.us-east-2.amazonaws.com/hls/hello.m3u8`

or you can set your cloudfront (cache disabled) distribution then based on your S3

>  ATTENTION:
>  Don't forget to set public access and enable CORS in your s3 bucket


## Using your Own Server

### SSL (optional)
To enable SSL, see [nginx.conf](nginx.conf) and uncomment the lines:
```
listen 443 ssl;
ssl_certificate     /opt/certs/example.com.crt;
ssl_certificate_key /opt/certs/example.com.key;
```

This will enable HTTPS using a self-signed certificate supplied in [/certs](/certs). If you wish to use HTTPS, it is **highly recommended** to obtain your own certificates and update the `ssl_certificate` and `ssl_certificate_key` paths.

I recommend using [Certbot](https://certbot.eff.org/docs/install.html) from [Let's Encrypt](https://letsencrypt.org).


### Watch Stream
* In Safari, VLC or any HLS player, open:
```
http://<server ip>:8080/live/$STREAM_NAME.m3u8
```
* Example Playlist: `http://localhost:8080/live/hello.m3u8`
* [VideoJS Player](https://video-dev.github.io/hls.js/stable/demo/?src=http%3A%2F%2Flocalhost%3A8080%2Flive%2Fhello.m3u8)
* FFplay: `ffplay -fflags nobuffer rtmp://localhost:1935/stream/hello`


### FFmpeg Build
```
$ ffmpeg -buildconf

ffmpeg version 4.2.1 Copyright (c) 2000-2019 the FFmpeg developers
  built with gcc 6.4.0 (Alpine 6.4.0)
  configuration: --prefix=/usr/local --enable-version3 --enable-gpl --enable-nonfree --enable-small --enable-libmp3lame --enable-libx264 --enable-libx265 --enable-libvpx --enable-libtheora --enable-libvorbis --enable-libopus --enable-libfdk-aac --enable-libass --enable-libwebp --enable-librtmp --enable-postproc --enable-avresample --enable-libfreetype --enable-openssl --disable-debug --disable-doc --disable-ffplay --extra-libs='-lpthread -lm'
  libavutil      56. 31.100 / 56. 31.100
  libavcodec     58. 54.100 / 58. 54.100
  libavformat    58. 29.100 / 58. 29.100
  libavdevice    58.  8.100 / 58.  8.100
  libavfilter     7. 57.100 /  7. 57.100
  libavresample   4.  0.  0 /  4.  0.  0
  libswscale      5.  5.100 /  5.  5.100
  libswresample   3.  5.100 /  3.  5.100
  libpostproc    55.  5.100 / 55.  5.100

  configuration:
    --prefix=/usr/local
    --enable-version3
    --enable-gpl
    --enable-nonfree
    --enable-small
    --enable-libmp3lame
    --enable-libx264
    --enable-libx265
    --enable-libvpx
    --enable-libtheora
    --enable-libvorbis
    --enable-libopus
    --enable-libfdk-aac
    --enable-libass
    --enable-libwebp
    --enable-librtmp
    --enable-postproc
    --enable-avresample
    --enable-libfreetype
    --enable-openssl
    --disable-debug
    --disable-doc
    --disable-ffplay
    --extra-libs='-lpthread -lm'
```

## Resources
* https://alpinelinux.org/
* http://nginx.org
* https://github.com/arut/nginx-rtmp-module
* https://www.ffmpeg.org
* https://obsproject.com
* https://github.com/s3fs-fuse/s3fs-fuse
