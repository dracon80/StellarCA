DOCKER_USERNAME ?= liquiddragon
APPLICATION_NAME ?= stellarca
GIT_HASH ?= $(shell git log --format="%h" -n 1)
ROOT_DIR := $(dir $(realpath $(lastword $(MAKEFILE_LIST))))

_BUILD_ARGS_TAG ?= ${GIT_HASH}
_BUILD_ARGS_RELEASE_TAG ?= latest
_BUILD_ARGS_DOCKERFILE ?= Dockerfile
_BUILD_ENVIRONMENT ?= production

_builder:
	docker build --tag ${DOCKER_USERNAME}/${APPLICATION_NAME}:${_BUILD_ARGS_TAG} --build-arg ENVIRONMENT=${_BUILD_ENVIRONMENT} -f ../docker/${_BUILD_ARGS_DOCKERFILE} ..

_pusher:
	docker push ${DOCKER_USERNAME}/${APPLICATION_NAME}:${_BUILD_ARGS_TAG}

_releaser:
	docker pull ${DOCKER_USERNAME}/${APPLICATION_NAME}:${_BUILD_ARGS_TAG}
	docker tag  ${DOCKER_USERNAME}/${APPLICATION_NAME}:${_BUILD_ARGS_TAG} ${DOCKER_USERNAME}/${APPLICATION_NAME}:latest
	docker push ${DOCKER_USERNAME}/${APPLICATION_NAME}:${_BUILD_ARGS_RELEASE_TAG}

_debuger:
	docker run -it --rm \
		--mount type=bind,source=${LOCAL_WORKSPACE_FOLDER}/stellarca/entrypoint.sh,target=/app/entrypoint.sh,readonly \
		--mount type=bind,source=${LOCAL_WORKSPACE_FOLDER}/stellarca/stellar.sh,target=/app/stellar.sh,readonly \
		--mount type=bind,source=${LOCAL_WORKSPACE_FOLDER}/stellarca/init.sh,target=/app/init.sh,readonly \
		--mount type=bind,source=${LOCAL_WORKSPACE_FOLDER}/stellarca/openssl.conf,target=/app/openssl.conf,readonly \
		--mount type=bind,source=${LOCAL_WORKSPACE_FOLDER}/stellarca/config.yaml,target=/app/config.yaml,readonly \
		${DOCKER_USERNAME}/${APPLICATION_NAME}:development \
		sh

build:
	$(MAKE) _builder \
		-e _BUILD_ENVIRONMENT="production"

build_dev:
	$(MAKE) _builder \
		-e _BUILD_ENVIRONMENT="development"\
		-e _BUILD_ARGS_TAG="development"
debug:
	$(MAKE) build_dev
	$(MAKE) _debuger

push:
	$(MAKE) _pusher

release:
	$(MAKE) _releaser

build_%:
	$(MAKE) _builder \
		-e _BUILD_ARGS_TAG="$*-${GIT_HASH}" \
		-e _BUILD_ARGS_DOCKERFILE="Dockerfile.$*" \
		-e _DOCKER_BUILD_ARGS="production"

build_dev_%:
	$(MAKE) _builder \
		-e _BUILD_ARGS_TAG="$*-${GIT_HASH}" \
		-e _BUILD_ARGS_DOCKERFILE="Dockerfile.$*" \
		-e _DOCKER_BUILD_ARGS="development"

push_%:
	$(MAKE) _pusher \
		-e _BUILD_ARGS_TAG="$*-${GIT_HASH}"

release_%:
	$(MAKE) _releaser \
		-e _BUILD_ARGS_TAG="$*-${GIT_HASH}" \
		-e _BUILD_ARGS_RELEASE_TAG="$*-latest"