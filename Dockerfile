FROM postgres:alpine
MAINTAINER Valeriy Maslov <valeriy.maslov@akvelon.com>

### This Docker image provides both running Plan webapp build process
### with Plan API integration testing environment.
### Based on postgres:9.6. Node installation was got from node:6.10 dockerfile
### and modified for plan.

### Environment Variables
#Postgres
ENV POSTGRES_DB=plan
ENV POSTGRES_USER=julia
ENV POSTGRES_PASSWORD=julia
#node
ENV NPM_CONFIG_LOGLEVEL info
ENV NODE_VERSION 6.10.2
ENV YARN_VERSION 0.21.3


### Installation of dependencies

RUN apk add --no-cache \
        ca-certificates \
        curl \
        wget \
        bzr \
        git \
        openssh-client \
        procps \
        autoconf \
        automake \
        bzip2 \
        bzip2-dev \
        curl-dev \
        db-dev \
        file \
        g++ \
        gcc \
        gdbm-dev \
        geoip-dev \
        glib-dev \
        imagemagick-dev \
        jpeg-dev \
        krb5-dev \
        libc-dev \
        libevent-dev \
        libffi-dev \
        libpng-dev \
        libressl-dev \
        libtool \
        libwebp-dev \
        libxml2-dev \
        libxslt-dev \
        linux-headers \
        make \
        ncurses-dev \
        patch \
        readline-dev \
        sqlite-dev \
        xz \
        xz-dev \
        yaml-dev \
        zlib-dev \
        fontconfig

### Node.js Installation

RUN addgroup -g 1000 node \
        && adduser -u 1000 -G node -s /bin/sh -D node \
        && apk add --no-cache \
            libstdc++ \
        && apk add --no-cache --virtual .build-deps \
            binutils-gold \
            curl \
            g++ \
            gcc \
            gnupg \
            libgcc \
            linux-headers \
            make \
            python \
# gpg keys listed at https://github.com/nodejs/node#release-team
  && for key in \
    9554F04D7259F04124DE6B476D5A82AC7E37093B \
    94AE36675C464D64BAFA68DD7434390BDBE9B9C5 \
    FD3A5288F042B6850C66B31F09FE44734EB7990E \
    71DCFD284A79C3B38668286BC97EC7A07EDE3FC1 \
    DD8F2338BAE7501E3DD5AC78C273792F7D83545D \
    B9AE9905FFD7803F25714661B63B535A4C206CA9 \
    C4F0DFFF4E8C1A8236409D08E73BC641CC11F4C8 \
    56730D5401028683275BD23C23EFEFE93C4CFFFE \
  ; do \
    gpg --keyserver ha.pool.sks-keyservers.net --recv-keys "$key"; \
  done \
    && curl -SLO "https://nodejs.org/dist/v$NODE_VERSION/node-v$NODE_VERSION.tar.xz" \
    && curl -SLO "https://nodejs.org/dist/v$NODE_VERSION/SHASUMS256.txt.asc" \
    && gpg --batch --decrypt --output SHASUMS256.txt SHASUMS256.txt.asc \
    && grep " node-v$NODE_VERSION.tar.xz\$" SHASUMS256.txt | sha256sum -c - \
    && tar -xf "node-v$NODE_VERSION.tar.xz" \
    && cd "node-v$NODE_VERSION" \
    && ./configure \
    && make -j$(getconf _NPROCESSORS_ONLN) \
    && make install \
    && apk del .build-deps \
    && cd .. \
    && rm -Rf "node-v$NODE_VERSION" \
    && rm "node-v$NODE_VERSION.tar.xz" SHASUMS256.txt.asc SHASUMS256.txt

RUN apk add --no-cache --virtual .build-deps-yarn curl gnupg \
  && for key in \
    6A010C5166006599AA17F08146C2130DFD2497F5 \
  ; do \
    gpg --keyserver ha.pool.sks-keyservers.net --recv-keys "$key"; \
  done \
  && curl -fSL -o yarn.js "https://yarnpkg.com/downloads/$YARN_VERSION/yarn-legacy-$YARN_VERSION.js" \
  && curl -fSL -o yarn.js.asc "https://yarnpkg.com/downloads/$YARN_VERSION/yarn-legacy-$YARN_VERSION.js.asc" \
  && gpg --batch --verify yarn.js.asc yarn.js \
  && rm yarn.js.asc \
  && mv yarn.js /usr/local/bin/yarn \
  && chmod +x /usr/local/bin/yarn \
  && apk del .build-deps-yarn


### Getting webapp into container
RUN mkdir /tmp/plan-client
WORKDIR /tmp/plan-client
ADD src/main/webapp /tmp/plan-client

### Building Plan client
RUN npm install
RUN npm run test
RUN npm run build

### Exposing Postgres to World
EXPOSE 5432