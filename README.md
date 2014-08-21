# HOVA

> [From the school of hard knocks.](https://www.youtube.com/watch?v=8u8f55WWxPk)

Release go applications as binaries & node apps as tar's bundled with all their requirements to a specified S3 bucket with Docker.

## Setup

#### Install Docker

First things first, you need to install Docker on your local machine.

If you are on a Mac, you can refer to this guide for [installing Docker & boot2docker](https://github.com/jfrazelle/mac-dev-setup#docker).

If you are on any other OS, you should checkout the [Docker Installation Docs](http://docs.docker.com/installation/) for installing on your system.

#### `env_vars`

You must create an enviornment variables file named `env_vars`. This allows us to give the docker container your AWS credentials, etc.

Here is a sample `env_vars` file:

```
AWS_S3_BUCKET=jesss/dist
AWS_ACCESS_KEY=YOUR_ACCESS_KEY
AWS_SECRET_KEY=YOUR_SECRET_KEY
GPG_PASSPHRASE=somepasswordforgpg
```

You must have all the variables above defined.

**If your id_rsa file has a passphrase you also need to set the `KEY_PASSPHRASE` enviornment variable in the `env_vars` file.**

#### Build the `yhat/hova` image

There is a Dockerfile & a Makefile in this directory. Before releasing any apps you need to build the `yhat/hova` docker image. You can see what images you have by running `docker images`.

To build the `yhat/hova` image, run:

```bash
$ make
```

**Note:** You only need to run this once, ***unless you make changes to release/make.sh***. It will take a few minutes the first time, but any changes after that will be built from cache. The base image has s3cmd, go, node, npm, grunt, bower, etc. Everything you need to compile a go app or a node app.


## Release a Node app or Go app

**Note:** If you are using the `release` command for a go app, it will not be cross compiled and expects you to have a `Makefile` in the repo for building the app. You can also include an optional `Goopfile` with line delimited requirements. If you want cross compilation of binaries see the [cross compiling binaries section](#release-cross-compiled-go-binaries).

Running `make release` will release an app. You **MUST** pass a variable `REPO` to the command. For example,

```bash
# release the master branch of a repo
$ make release REPO=git@bitbucket.org:jfrazelle/gifs.jessfraz.com.git
# the end result will be uploaded to your bucket at
# s3://${AWS_S3_BUCKET}/jfrazelle/gifs.jessfraz.com/master/latest.tar.gz and
# s3://${AWS_S3_BUCKET}/jfrazelle/gifs.jessfraz.com/master/${TIMESTAMP}.tar.gz

# release a different branch of a repo
$ make release REPO=git@bitbucket.org:jfrazelle/gifs.jessfraz.com.git BRANCH=dev
# the end result will be uploaded to your bucket at
# s3://${AWS_S3_BUCKET}/jfrazelle/gifs.jessfraz.com/dev/latest.tar.gz and
# s3://${AWS_S3_BUCKET}/jfrazelle/gifs.jessfraz.com/dev/${TIMESTAMP}.tar.gz
```

The end result from the release, is uploaded to your S3 bucket that you gave in the `env_vars` file in the following directory formats:

```
s3://${AWS_S3_BUCKET}/${REPO_OWNER}/${REPO_NAME}/${BRANCH}/latest.tar.gz
s3://${AWS_S3_BUCKET}/${REPO_OWNER}/${REPO_NAME}/${BRANCH}/${TIMESTAMP}.tar.gz
```

### Okay so now I have a tar...

You can run it in a Docker container! What? Yessss!

Below is a sample Docker file to use with your tarred node app.

```
FROM node:latest

COPY latest.tar.gz /

RUN mkdir -p /src; tar -C /src -zxf latest.tar.gz
RUN mv /src/* /src/app


WORKDIR /src/app

# set the vars
ENV PORT 8888
ENV NODE_ENV production
EXPOSE 8888

# replace this with your main "server" script file
CMD [ "node", "app.js" ]
```

In a directory with the above Dockerfile & your tar you can run `docker build --rm -t your/image_name .` to build the Docker image.

Then to run your app it's as simple as `docker run -d --name your_app_name -p 8888 -e=ANY_ENV_VAR="val" your/image_name`.

Happy deploying!!


## Release Cross Compiled Go Binaries

Running `make binary-release` will release go binaries. You **MUST** pass a variable `SRC` to the command. For example,

```bash
# release the master branch of a repo
$ make binary-release SRC=github.com/jfrazelle/weather
# the end result will be uploaded to your bucket at
# s3://${AWS_S3_BUCKET}/jfrazelle/weather/Linux/386/weather
# ...
# and so and so forth for the rest of the OS & ARCH options
```

The end result from the release, is uploaded to your S3 bucket that you gave in the `env_vars` file in the following directory formats:

```
s3://${AWS_S3_BUCKET}/${NAME}/${OS}/${ARCH}/${binary_name}
s3://${AWS_S3_BUCKET}/${NAME}/${OS}/${ARCH}/latest.tar.gz
s3://${AWS_S3_BUCKET}/${NAME}/${OS}/${ARCH}/${TIMESTAMP}.tar.gz
```

<br/>


> Special thanks to [Docker's own build scripts](https://github.com/docker/docker/blob/master/Makefile) for giving me this idea.
