# This file describes the standard way to release a go or node app, using docker
#
# Note: Apparmor used to mess with privileged mode, but this is no longer
# the case. Therefore, you don't have to disable it anymore.
#
FROM    ubuntu:trusty
MAINTAINER  Jessica Frazelle <github.com/jfrazelle>

# Packaged dependencies
RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -yq \
    apt-utils \
    automake \
    btrfs-tools \
    build-essential \
    bzr \
    cmake \
    curl \
    git \
    jq \
    libapparmor-dev \
    libhttp-parser-dev \
    libssl-dev \
    libssh2-1-dev \
    libzip-dev \
    make \
    mercurial \
    openssl \
    python-pip \
    python-software-properties \
    tree \
    software-properties-common \
    ssh \
    rng-tools \
    wget \
    --no-install-recommends

# add sources
RUN curl -sL https://deb.nodesource.com/setup | bash -
RUN wget -O- -q http://s3tools.org/repo/deb-all/stable/s3tools.key | apt-key add -
RUN wget -O/etc/apt/sources.list.d/s3tools.list http://s3tools.org/repo/deb-all/stable/s3tools.list

# install source'd packages
RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -yq \
    nodejs \
    s3cmd \
    --no-install-recommends

# Install Go
RUN curl -s https://storage.googleapis.com/golang/go1.3.linux-amd64.tar.gz | tar -C /usr/local -xvz
RUN mkdir -p /go
ENV PATH    /usr/local/go/bin:/go/bin:$PATH
ENV GOPATH  /go

# Use Gox for cross compiling
RUN go get github.com/mitchellh/gox
# build the toolchain
RUN gox -build-toolchain

# install python magic for mime-typing the uploads to s3
RUN pip install python-magic

RUN npm install -g grunt-cli
RUN npm install -g bower

# Setup s3cmd config
RUN /bin/echo -e '[default]\naccess_key=$AWS_ACCESS_KEY\nsecret_key=$AWS_SECRET_KEY' > /.s3cfg

WORKDIR /

ENV DOCKER_BUILDTAGS apparmor selinux

# copy the release script to our filesystem
COPY    ./release   /release