VERSION ?= 0.0.1
BUILD_TIME = $(shell date -u +"%Y-%m-%dT%H:%M:%SZ")
GIT_COMMIT = $(shell git rev-parse --short=8 HEAD)
ARCH=arm64

.PHONY: build

BIN_DIR = server/bin

$(BIN_DIR):
	mkdir -p $(BIN_DIR)

build: $(BIN_DIR)
	@echo "Building binary for Linux ($(ARCH))..."
	@GOOS=linux GOARCH=$(ARCH) go build -ldflags "\
		-X main.Version=${VERSION} \
		-X main.BuiltAt=${BUILD_TIME} \
		-X main.BuildCommit=${GIT_COMMIT}" \
		-o $(BIN_DIR)/quran_app ./server
	cd server && docker build --platform linux/$(ARCH) -t ghcr.io/boolow5/quran_app:${VERSION} .

push: build
	@echo "Pushing Docker image ghcr.io/boolow5/quran_app:${VERSION}..."
	@docker push ghcr.io/boolow5/quran_app:${VERSION}
	@echo "Tagging Docker image ghcr.io/boolow5/quran_app:latest..."
	@docker tag ghcr.io/boolow5/quran_app:${VERSION} ghcr.io/boolow5/quran_app:latest
	@docker push ghcr.io/boolow5/quran_app:latest

clean:
	@echo "Cleaning build artifacts..."
	@rm -rf $(BIN_DIR)

help:
	@echo "Usage: make [target]"
	@echo ""
	@echo "Targets:"
	@echo "  build      Build binary for Linux ($(ARCH))"
	@echo "  push       Push binary and Docker image ghcr.io/boolow5/quran_app:${VERSION}"
