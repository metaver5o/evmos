# Makefile for UCHAIN Docker Environments

# Variables
SHELL := /bin/bash
MAIN_COMPOSE_FILE := docker-compose.yml
TEST_COMPOSE_FILE := docker-compose.test.yml

# This should be the name of the image built by your Dockerfile 
# and referenced in your docker-compose.yml and docker-compose.test.yml files.
UCHAIN_IMAGE_NAME := uchain-node

# Path to your Dockerfile for the UCHAIN node
DOCKERFILE_PATH := Dockerfile

# Build context for the Dockerfile.
# Based on your CI script: DOCKER_BUILDKIT=1 docker build -t evmos -f Dockerfile evmos/
# This implies your Dockerfile is at the project root, and its build context 
# (files it COPY/ADDs from) is the 'evmos/' subdirectory.
# Please ensure this path is correct for your project structure.
DOCKER_BUILD_CONTEXT := evmos/

# Default target
.PHONY: all
all: help

# Help target to display available commands
.PHONY: help
help:
	@echo "Usage: make <target>"
	@echo ""
	@echo "Global Build Target:"
	@echo "  build                      Build the ${UCHAIN_IMAGE_NAME} Docker image from ${DOCKERFILE_PATH} with context ${DOCKER_BUILD_CONTEXT}"
	@echo ""
	@echo "Mainnet Targets (using ${MAIN_COMPOSE_FILE}):"
	@echo "  mainnet                    Start mainnet services (alias for mainnet-up)"
	@echo "  mainnet-up                 Start mainnet services in detached mode (assumes image is built)"
	@echo "  mainnet-down               Stop and remove mainnet service containers"
	@echo "  mainnet-logs               Follow logs for mainnet services"
	@echo "  mainnet-rebuild            Force rebuild of ${UCHAIN_IMAGE_NAME} image, then stop and restart mainnet services"
	@echo "  clean-mainnet              Stop/remove mainnet containers and associated named volumes"
	@echo ""
	@echo "Testnet Targets (using ${TEST_COMPOSE_FILE}):"
	@echo "  testnet                    Start testnet services (alias for testnet-up)"
	@echo "  testnet-up                 Start testnet services in detached mode (assumes image is built)"
	@echo "  testnet-down               Stop and remove testnet service containers"
	@echo "  testnet-logs               Follow logs for testnet services"
	@echo "  testnet-rebuild            Force rebuild of ${UCHAIN_IMAGE_NAME} image, then stop and restart testnet services"
	@echo "  clean-testnet              Stop/remove testnet containers and associated named volumes"
	@echo ""
	@echo "Global Clean Target:"
	@echo "  clean-all                  Clean both mainnet and testnet environments (containers and volumes)"

# Build UCHAIN node Docker image
.PHONY: build
build:
	@echo "Building ${UCHAIN_IMAGE_NAME} Docker image..."
	@echo "Using Dockerfile: ${DOCKERFILE_PATH}, Context: ${DOCKER_BUILD_CONTEXT}"
	DOCKER_BUILDKIT=1 docker build -t ${UCHAIN_IMAGE_NAME} -f ${DOCKERFILE_PATH} ${DOCKER_BUILD_CONTEXT} --build-arg DB_BACKEND=goleveldb

# Mainnet targets
.PHONY: mainnet mainnet-up mainnet-down mainnet-logs mainnet-rebuild
mainnet: mainnet-up

mainnet-up:
	@echo "Starting UCHAIN mainnet services (using ${MAIN_COMPOSE_FILE})..."
	@echo "INFO: This assumes the '${UCHAIN_IMAGE_NAME}' image is already built (run 'make build' if not)."
	@echo "INFO: Ensure placeholder secrets in ${MAIN_COMPOSE_FILE} (for Redis, Blockscout, Faucet) are updated."
	docker-compose -f ${MAIN_COMPOSE_FILE} up -d

mainnet-down:
	@echo "Stopping and removing UCHAIN mainnet service containers (using ${MAIN_COMPOSE_FILE})..."
	docker-compose -f ${MAIN_COMPOSE_FILE} down

mainnet-logs:
	@echo "Following UCHAIN mainnet logs (from ${MAIN_COMPOSE_FILE})..."
	docker-compose -f ${MAIN_COMPOSE_FILE} logs -f --tail=100

mainnet-rebuild: build mainnet-down mainnet-up

# Testnet targets
.PHONY: testnet testnet-up testnet-down testnet-logs testnet-rebuild
testnet: testnet-up

testnet-up:
	@echo "Starting UCHAIN testnet services (using ${TEST_COMPOSE_FILE})..."
	@echo "INFO: This assumes the '${UCHAIN_IMAGE_NAME}' image is already built (run 'make build' if not)."
	@echo "INFO: Ensure .env and evmos-local.env (if used by ${TEST_COMPOSE_FILE}) are configured correctly."
	docker-compose -f ${TEST_COMPOSE_FILE} up -d

testnet-down:
	@echo "Stopping and removing UCHAIN testnet service containers (using ${TEST_COMPOSE_FILE})..."
	docker-compose -f ${TEST_COMPOSE_FILE} down

testnet-logs:
	@echo "Following UCHAIN testnet logs (from ${TEST_COMPOSE_FILE})..."
	docker-compose -f ${TEST_COMPOSE_FILE} logs -f --tail=100

testnet-rebuild: build testnet-down testnet-up

# Clean targets
.PHONY: clean-mainnet clean-testnet clean-all
clean-mainnet:
	@echo "Stopping and removing UCHAIN mainnet containers and associated named volumes (from ${MAIN_COMPOSE_FILE})..."
	docker-compose -f ${MAIN_COMPOSE_FILE} down -v

clean-testnet:
	@echo "Stopping and removing UCHAIN testnet containers and associated named volumes (from ${TEST_COMPOSE_FILE})..."
	docker-compose -f ${TEST_COMPOSE_FILE} down -v

clean-all: clean-mainnet clean-testnet
	@echo "All UCHAIN Docker environments (mainnet & testnet containers and volumes) have been cleaned."

