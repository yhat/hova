ENV_FILE := ./env_vars
DOCKER_IMAGE := yhat/hova
DOCKER_BUILD := docker build --force-rm=true --rm=true -t $(DOCKER_IMAGE) .
DOCKER_RUN_RELEASE := docker run --rm=true -it --net=host --privileged=true --env-file=$(ENV_FILE) -e=PUB_KEY="$(shell cat ~/.ssh/id_rsa.pub)" -e=PRI_KEY="$(shell cat ~/.ssh/id_rsa)"
BRANCH = "master"

all: build

build:
	$(DOCKER_BUILD)


clean:
	docker stop $(shell docker ps -aq); \
	docker rm $(shell docker ps -aq); \
	docker rmi $(shell docker images --filter=dangling=true -q)


release: build
	 @if [ -z "$(REPO)" ]; then \
        echo "Error: REPO not set"; exit 2; \
    else \
    	$(DOCKER_RUN_RELEASE) $(DOCKER_IMAGE) release/make.sh $(REPO) $(BRANCH); \
    fi


binary-release: build
	 @if [ -z "$(SRC)" ]; then \
        echo "Error: SRC not set"; exit 2; \
    else \
    	$(DOCKER_RUN_RELEASE) $(DOCKER_IMAGE) release/make_binary.sh $(SRC); \
    fi

shell: build
	$(DOCKER_RUN_RELEASE) $(DOCKER_IMAGE) bash


.PHONY: build clean release binary-release shell