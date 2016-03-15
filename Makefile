GO ?= go
GOFMT ?= gofmt -s
GOLINT ?= golint
GODEP ?= godep
DOCKER ?= docker

GOFILES := find . -name '*.go' -not -path "./vendor/*"

GOBUILD_LDFLAGS ?=
GOBUILD_FLAGS ?=

EXEC_PKG ?= rsprd.com/localkube/cmd/localkube

DOCKER_OPTS ?=
DOCKER_RUN_OPTS ?= -v "/var/run/docker.sock:/var/run/docker.sock"

ORG ?= ethernetdan
NAME ?= localkube
TAG ?= latest

DOCKER_IMAGE_NAME = "$(ORG)/$(NAME):$(TAG)"

.PHONY: all
all: deps clean validate build build-image

.PHONY: validate
validate: checkgofmt

.PHONY: build
build: build/localkube

.PHONY: clean
clean:
	rm -rf ./build

build/localkube:
	$(GO) build -o $@ $(GOBUILD_FLAGS) $(GOBUILD_LDFLAGS) $(EXEC_PKG)

PHONY: build-image
build-image: build/context
	$(DOCKER) build $(DOCKER_OPTS) -t $(DOCKER_IMAGE_NAME) ./build/context

PHONY: run-image
run-image: build-image
	docker run -it $(DOCKER_OPTS) $(DOCKER_RUN_OPTS) $(DOCKER_IMAGE_NAME)

build/context: build/localkube
	cp -r ./image $@
	cp ./build/localkube ./build/context
	chmod +x ./build/context/localkube


.PHONY: checkgofmt
checkgofmt:
	# get all go files and run go fmt on them
	files=$$($(GOFILES) | xargs $(GOFMT) -l); echo "test $$files"; if [[ -n "$$files" ]]; then \
		  echo "Error: '$(GOFMT)' needs to be run on:"; \
		  echo "$${files}"; \
		  exit 1; \
		  fi;

.PHONY: deps
deps:
	$(GODEP) restore -v