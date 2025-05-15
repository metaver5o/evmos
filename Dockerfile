# Dockerfile.fixed
# This Dockerfile assumes it is located at the root of the Evmos source code directory (e.g., ./evmos/Dockerfile.fixed)
# and the build context for docker-compose is set to that directory.

# hadolint global ignore=DL3018
FROM golang:1.23.4-alpine3.20 AS build-env

ARG DB_BACKEND=goleveldb
ARG ROCKSDB_VERSION="9.8.4"

# Set the working directory to where the Evmos source code will be copied.
# Since the Dockerfile is assumed to be at the root of the source, and context is that root,
# WORKDIR /app or similar, then COPY . . makes sense.
WORKDIR /evmos_src

# Copy go.mod and go.sum first to leverage Docker layer caching for dependencies.
COPY go.mod go.sum ./

RUN set -eux; apk add --no-cache \
    ca-certificates \
    build-base \
    git \
    linux-headers \
    bash \
    binutils-gold

# Download Go modules.
# Ensure your Git setup (e.g., for private repos) is handled if necessary.
# The original Dockerfile had a GITHUB_TOKEN mount, which you can retain if needed.
# RUN --mount=type=bind,target=. --mount=type=secret,id=GITHUB_TOKEN \
#    git config --global url.\"https://$(cat /run/secrets/GITHUB_TOKEN)@github.com/\".insteadOf \"https://github.com/\"; \
RUN go mod download

# Copy the rest of the Evmos source code into the build stage.
# This includes the Makefile and .git directory (if present in the build context),
# which are crucial for version embedding if the Makefile uses git describe.
COPY . .

RUN mkdir -p /target/usr/lib /target/usr/local/lib /target/usr/include

# Build evmosd. The Makefile within the Evmos source code (copied above)
# is responsible for correctly embedding version information using ldflags.
# Ensure your project's Makefile handles this (see provided sample Makefile.fixed for an example).
RUN if [ "$DB_BACKEND" = "rocksdb" ]; then \
   make build-rocksdb; \
   # Ensure build artifacts are correctly placed for copying if rocksdb is used.
   # The original paths assumed source was in /go/src/github.com/evmos/evmos.
   # Adjust if your Makefile places them differently relative to /evmos_src.
   cp -r /usr/lib/* /target/usr/lib/ && \
   cp -r /usr/local/lib/* /target/usr/local/lib/ && \
   cp -r /usr/include/* /target/usr/include/; \
else \
    COSMOS_BUILD_OPTIONS=$DB_BACKEND make build; \
fi

# Install toml-cli (if still needed by your setup)
RUN go install github.com/MinseokOh/toml-cli@latest

# --- Final Image Stage ---
FROM alpine:3.21

WORKDIR /home/evmos
RUN mkdir -p /home/evmos/.evmosd && chown -R 1000:1000 /home/evmos/.evmosd

# Copy the built evmosd binary from the build-env stage.
# Adjust the source path if your Makefile in evmos_src places the binary elsewhere.
COPY --from=build-env /evmos_src/build/evmosd /usr/bin/evmosd
COPY --from=build-env /go/bin/toml-cli /usr/bin/toml-cli

# Required for rocksdb build artifacts (if used)
COPY --from=build-env /target/usr/lib /usr/lib
COPY --from=build-env /target/usr/local/lib /usr/local/lib
COPY --from=build-env /target/usr/include /usr/include

RUN apk add --no-cache \
    ca-certificates \
    jq \
    curl \
    bash \
    lz4 \
    rclone \
    && addgroup -g 1000 evmos \
    && adduser -S -h /home/evmos -D evmos -u 1000 -G evmos

USER 1000

EXPOSE 26656 26657 1317 9090 8545 8546

HEALTHCHECK CMD curl --fail http://localhost:26657/status || exit 1

# Environment variables for the default CMD. 
# These are often overridden by docker-compose.
ARG MONIKER="my-node"
ARG CHAIN_ID="evmos_9001-2"
ARG KEY_NAME="my-key"
# IMPORTANT: Default to a placeholder for a 24-WORD MNEMONIC.
# The user MUST provide a valid 24-word mnemonic for actual use.
ARG KEY_MNEMONIC="abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon art"
ARG KEYRING_BACKEND="test"
ARG KEY_PASSPHRASE="12345678" # Default passphrase, consider security implications.

ENV MONIKER=$MONIKER \
    CHAIN_ID=$CHAIN_ID \
    KEY_NAME=$KEY_NAME \
    KEY_MNEMONIC=$KEY_MNEMONIC \
    KEYRING_BACKEND=$KEYRING_BACKEND \
    KEY_PASSPHRASE=$KEY_PASSPHRASE

# Default command: Initialize the chain if needed then start Evmos.
# This CMD is typically overridden by docker-compose for multi-node setups.
# The key import method here is updated for better practice, but ensure KEY_MNEMONIC is a 24-word phrase.
CMD ["/bin/sh", "-c", \
"set -e && \
if [ ! -f /home/evmos/.evmosd/config/genesis.json ]; then \
  echo \"Initializing chain (default Docker CMD)...\" && \
  rm -rf /home/evmos/.evmosd/config || true && \
  \
  evmosd init \"$MONIKER\" --chain-id=\"$CHAIN_ID\" --overwrite && \
  \
  echo \"Adding key (default Docker CMD)... Ensure KEY_MNEMONIC is a valid 24-word phrase.\" && \
  echo -n \"$KEY_MNEMONIC\" > /tmp/mnemonic_cmd.txt && \
  evmosd keys add \"$KEY_NAME\" --recover --keyring-backend=$KEYRING_BACKEND --source /tmp/mnemonic_cmd.txt && \
  rm -f /tmp/mnemonic_cmd.txt && \
  \
  EVMOS_ADDRESS=$(evmosd keys show \"$KEY_NAME\" -a --keyring-backend=$KEYRING_BACKEND) && \
  echo \"Genesis account address (default Docker CMD): $EVMOS_ADDRESS\" && \
  \
  evmosd add-genesis-account \"$EVMOS_ADDRESS\" 2000000000000ucash --keyring-backend=$KEYRING_BACKEND && \
  \
  evmosd gentx \"$KEY_NAME\" 1000000000000ucash --chain-id=\"$CHAIN_ID\" \
    --commission-rate=0.1 --commission-max-rate=0.2 \
    --commission-max-change-rate=0.01 --min-self-delegation=1000000 \
    --keyring-backend=$KEYRING_BACKEND && \
  \
  evmosd collect-gentxs && \
  \
  echo \"Initialization complete (default Docker CMD).\"; \
fi && \
exec evmosd start --json-rpc.enable --json-rpc.address=0.0.0.0:8545 --api.enable"]

