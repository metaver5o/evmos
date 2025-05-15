# Makefile.fixed
# This is a sample Makefile demonstrating how to embed version information.
# It should be placed at the root of your Evmos project source code.

# Application Name
APP_NAME := evmosd
# Binary output directory
BUILDDIR := build
# Main package
MAIN_PKG := ./cmd/evmosd

# Versioning
# Attempt to get version from git tags. Fallback if not a git repo or no tags.
# Ensure .git directory is included in the Docker build context if using this in Docker.
VERSION := $(shell git describe --tags 2>/dev/null || echo "v0.0.0-unknown")
COMMIT := $(shell git log -1 --format='%H' 2>/dev/null || echo "unknown")
SDK_VERSION := $(shell go list -m -f '{{.Version}}' github.com/cosmos/cosmos-sdk)

# Build flags
# These flags will be embedded into the binary. Adjust paths and variables as needed for your specific application structure.
# The paths like github.com/cosmos/cosmos-sdk/version.X might need to be specific to Evmos's own version package if it forks this.
# Consult Evmos source or existing Makefiles for the exact variable paths.
LD_FLAGS := "-X github.com/cosmos/cosmos-sdk/version.Name=evmos \
             -X github.com/cosmos/cosmos-sdk/version.AppName=$(APP_NAME) \
             -X github.com/cosmos/cosmos-sdk/version.Version=$(VERSION) \
             -X github.com/cosmos/cosmos-sdk/version.Commit=$(COMMIT) \
             -X github.com/cosmos/cosmos-sdk/version.BuildTags=netgo,ledger,rocksdb $(COSMOS_BUILD_OPTIONS)"

# Go command
GO := go

# Default target
all: build

# Build the application binary
build: | $(BUILDDIR)
	@echo "Building $(APP_NAME) $(VERSION) ($(COMMIT))..."
	@$(GO) build -o $(BUILDDIR)/$(APP_NAME) -ldflags=$(LD_FLAGS) $(MAIN_PKG)
	@echo "Build complete: $(BUILDDIR)/$(APP_NAME)"

# Create build directory if it doesn't exist
$(BUILDDIR):
	@mkdir -p $(BUILDDIR)

# Build with RocksDB support (example, adapt as per Evmos project specifics)
# This target might involve more complex steps like building RocksDB C libraries first.
build-rocksdb:
	@echo "Building with RocksDB support..."
	# Add commands here to build RocksDB and then build evmosd with RocksDB tags/options.
	# This is a placeholder. The actual Evmos Makefile will have the correct procedure.
	$(MAKE) build COSMOS_BUILD_OPTIONS="rocksdb"

# Clean build artifacts
clean:
	@echo "Cleaning build artifacts..."
	@rm -rf $(BUILDDIR)

# Print version information (for verification)
print-version:
	@echo "App Name: $(APP_NAME)"
	@echo "Version: $(VERSION)"
	@echo "Commit: $(COMMIT)"
	@echo "SDK Version: $(SDK_VERSION)"
	@echo "LD_FLAGS: $(LD_FLAGS)"

.PHONY: all build build-rocksdb clean print-version

