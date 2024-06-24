ARG ALPINE_VERSION=3.14
ARG NGINX_VERSION=1.27.0
ARG NGINX_RTMP_VERSION=1.2.2
ARG FFMPEG_VERSION=7.0
ARG S3FS_VERSION=v1.85

# Build the NGINX-build image.
FROM alpine:${ALPINE_VERSION} as build-nginx
ARG NGINX_VERSION
ARG NGINX_RTMP_VERSION

# Build dependencies.
RUN apk add --update \
  build-base \
  ca-certificates \
  curl \
  gcc \
  libc-dev \
  libgcc \
  linux-headers \
  make \
  musl-dev \
  openssl \
  openssl-dev \
  pcre \
  pcre-dev \
  pkgconf \
  pkgconfig \
  zlib-dev

# Get nginx source.
RUN cd /tmp && \
  wget https://nginx.org/download/nginx-${NGINX_VERSION}.tar.gz && \
  tar zxf nginx-${NGINX_VERSION}.tar.gz && \
  rm nginx-${NGINX_VERSION}.tar.gz

# Get nginx-rtmp module.
RUN cd /tmp && \
  wget https://github.com/arut/nginx-rtmp-module/archive/v${NGINX_RTMP_VERSION}.tar.gz && \
  tar zxf v${NGINX_RTMP_VERSION}.tar.gz && rm v${NGINX_RTMP_VERSION}.tar.gz

# Compile nginx with nginx-rtmp module.
RUN cd /tmp/nginx-${NGINX_VERSION} && \
  ./configure \
  --prefix=/usr/local/nginx \
  --add-module=/tmp/nginx-rtmp-module-${NGINX_RTMP_VERSION} \
  --conf-path=/etc/nginx/nginx.conf \
  --with-threads \
  --with-file-aio \
  --with-http_ssl_module \
  --with-debug \
  --with-cc-opt="-Wimplicit-fallthrough=0" && \
  cd /tmp/nginx-${NGINX_VERSION} && make && make install

# Build the FFmpeg-build image.
FROM alpine:${ALPINE_VERSION} as build-ffmpeg
ARG FFMPEG_VERSION
ARG PREFIX=/usr/local
ARG MAKEFLAGS="-j4"

# FFmpeg build dependencies.
RUN apk update && \
    apk add --no-cache \
        autoconf \
        automake \
        build-base \
        cmake \
        coreutils \
        git \
        libass-dev \
        freetype-dev \
        libtool \
        pkgconfig \
        wget \
        yasm \
        zlib-dev \
        fdk-aac-dev \
        lame-dev \
        opus-dev \
        libass \
        libogg-dev \
        libtheora-dev \
        libvorbis-dev \
        libvpx-dev \
        libwebp-dev \
        openssl-dev \
        pkgconf \
        rtmpdump-dev \
        x264-dev \
        x265-dev \
        nasm \
        yasm \
        libunistring

RUN echo http://dl-cdn.alpinelinux.org/alpine/edge/community >> /etc/apk/repositories
RUN apk add --update fdk-aac-dev

# Get FFmpeg source.
RUN cd /tmp/ && \
  wget http://ffmpeg.org/releases/ffmpeg-${FFMPEG_VERSION}.tar.gz && \
  tar zxf ffmpeg-${FFMPEG_VERSION}.tar.gz && rm ffmpeg-${FFMPEG_VERSION}.tar.gz

# Compile ffmpeg.
RUN cd /tmp/ffmpeg-${FFMPEG_VERSION} && \
  ./configure \
  --prefix=${PREFIX} \
  --enable-version3 \
  --enable-gpl \
  --enable-nonfree \
  --enable-small \
  --enable-libmp3lame \
  --enable-libx264 \
  --enable-libx265 \
  --enable-libvpx \
  --enable-libtheora \
  --enable-libvorbis \
  --enable-libopus \
  --enable-libfdk-aac \
  --enable-libass \
  --enable-libwebp \
  --enable-librtmp \
  --enable-postproc \
  #--enable-avresample \
  --enable-libfreetype \
  --enable-openssl \
  --disable-debug \
  --disable-doc \
  --disable-ffplay \
  --extra-libs="-lpthread -lm" && \
  make && make install && make distclean

# Cleanup.
RUN rm -rf /var/cache/* /tmp/*

# Build the release image.
FROM alpine:${ALPINE_VERSION}

ENV FILESYSTEM 'local'
ENV STORAGE_PATH '/opt/data'
ENV HTTP_PORT 80
ENV HTTPS_PORT 443
ENV RTMP_PORT 1935

RUN apk add --update \
  bash \
  ca-certificates \
  gettext \
  openssl \
  pcre \
  lame \
  libogg \
  curl \
  libass \
  libvpx \
  libvorbis \
  libwebp \
  libtheora \
  opus \
  rtmpdump \
  x264-dev \
  x265-dev

COPY --from=build-nginx /usr/local/nginx /usr/local/nginx
COPY --from=build-nginx /etc/nginx /etc/nginx
COPY --from=build-ffmpeg /usr/local /usr/local
COPY --from=build-ffmpeg /usr/lib/libfdk-aac.so.2 /usr/lib/libfdk-aac.so.2
COPY --from=build-ffmpeg /usr/lib/libwebpmux.so.3 /usr/lib/libwebpmux.so.3
COPY --from=build-ffmpeg /usr/lib/libmp3lame.so.0 /usr/lib/libmp3lame.so.0

ENV PATH "${PATH}:/usr/local/nginx/sbin"
ADD nginx.conf /etc/nginx/nginx.conf.template
RUN mkdir -p /opt/data && mkdir /www
ADD static /www/static

# Add S3FS Method 1
# RUN echo http://dl-cdn.alpinelinux.org/alpine/edge/testing >> /etc/apk/repositories
# RUN apk --update add s3fs-fuse

# S3FS Method 2
# try to add it my way from  https://hub.docker.com/r/appsoa/docker-alpine-s3fs/dockerfile
# Does not work either, I guess, due to using alpine and build scripts.
# ARG S3FS_VERSION=v1.82
# RUN git clone https://github.com/s3fs-fuse/s3fs-fuse.git && \
#     cd s3fs-fuse \
#     git checkout tags/${S3FS_VERSION} && \
#     ./autogen.sh && \
#     ./configure --prefix=/usr && \
#     make && \
#     make install


ADD entrypoint.sh /
RUN chmod +x /entrypoint.sh

EXPOSE 80
EXPOSE 443
EXPOSE 1935

CMD ["/entrypoint.sh"]
