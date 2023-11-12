DOCKER_USERNAME ?= liquiddragon
APPLICATION_NAME ?= stellarca
GIT_HASH ?= $(shell git log --format="%h" -n 1)

_BUILD_ARGS_TAG ?= ${GIT_HASH}
_BUILD_ARGS_RELEASE_TAG ?= latest
_BUILD_ARGS_DOCKERFILE ?= Dockerfile
_DOCKER_BUILD_ARGS ?= production

_builder:
	docker build --tag ${DOCKER_USERNAME}/${APPLICATION_NAME}:${_BUILD_ARGS_TAG} --build-arg ${_BUILD_ARGS_DOCKERFILE} -f ../docker/${_BUILD_ARGS_DOCKERFILE} ..

_pusher:
	docker push ${DOCKER_USERNAME}/${APPLICATION_NAME}:${_BUILD_ARGS_TAG}

_releaser:
	docker pull ${DOCKER_USERNAME}/${APPLICATION_NAME}:${_BUILD_ARGS_TAG}
	docker tag  ${DOCKER_USERNAME}/${APPLICATION_NAME}:${_BUILD_ARGS_TAG} ${DOCKER_USERNAME}/${APPLICATION_NAME}:latest
	docker push ${DOCKER_USERNAME}/${APPLICATION_NAME}:${_BUILD_ARGS_RELEASE_TAG}

build:
	$(MAKE) _builder \
		-e _DOCKER_BUILD_ARGS="production"

build_dev:
	$(MAKE) _builder \
		-e _DOCKER_BUILD_ARGS="development"\
		-e _BUILD_ARGS_TAG="development"

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
		-e _BUILD_ARGS_TAG="development" \
		-e _BUILD_ARGS_DOCKERFILE="Dockerfile.$*" \
		-e _DOCKER_BUILD_ARGS="development"

push_%:
	$(MAKE) _pusher \
		-e _BUILD_ARGS_TAG="$*-${GIT_HASH}"

release_%:
	$(MAKE) _releaser \
		-e _BUILD_ARGS_TAG="$*-${GIT_HASH}" \
		-e _BUILD_ARGS_RELEASE_TAG="$*-latest"