# docker rm -f evmos-node 2>/dev/null || true
# docker volume create evmos-data 2>/dev/null || true
# DOCKER_BUILDKIT=1  docker build -t evmos -f Dockerfile evmos/ --no-cache
# docker run -it --name evmos-node \
#   -e KEY_MNEMONIC="test test test test test test test test test test test junk" \
#   -e MONIKER="my-node" \
#   -e CHAIN_ID="evmos_9001-2" \
#   -e KEY_NAME="my-key" \
#   -e KEYRING_BACKEND="test" \
#   -p 26656:26656 \
#   -p 26657:26657 \
#   -p 1317:1317 \
#   -p 8545:8545 \
#   -p 8546:8546 \
#   -v evmos-data:/home/evmos/.evmosd \
#   evmos


# hadolint global ignore=DL3018
FROM golang:1.23.4-alpine3.20 AS build-env

ARG DB_BACKEND=goleveldb
ARG ROCKSDB_VERSION="9.8.4"

WORKDIR /go/src/github.com/evmos/evmos

COPY go.mod go.sum ./

RUN set -eux; apk add --no-cache \
    ca-certificates \
    build-base \
    git \
    linux-headers \
    bash \
    binutils-gold

# Use secret for private GitHub token if needed
RUN --mount=type=bind,target=. --mount=type=secret,id=GITHUB_TOKEN \
    git config --global url."https://$(cat /run/secrets/GITHUB_TOKEN)@github.com/".insteadOf "https://github.com/"; \
    go mod download

COPY . .

RUN mkdir -p /target/usr/lib /target/usr/local/lib /target/usr/include

RUN if [ "$DB_BACKEND" = "rocksdb" ]; then \
   make build-rocksdb; \
   cp -r /usr/lib/* /target/usr/lib/ && \
   cp -r /usr/local/lib/* /target/usr/local/lib/ && \
   cp -r /usr/include/* /target/usr/include/; \
else \
    COSMOS_BUILD_OPTIONS=$DB_BACKEND make build; \
fi

RUN go install github.com/MinseokOh/toml-cli@latest

FROM alpine:3.21

WORKDIR /home/evmos
RUN mkdir -p /home/evmos/.evmosd && chown -R 1000:1000 /home/evmos/.evmosd
COPY --from=build-env /go/src/github.com/evmos/evmos/build/evmosd /usr/bin/evmosd
COPY --from=build-env /go/bin/toml-cli /usr/bin/toml-cli

# Required for rocksdb build artifacts
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

# Expose necessary ports
EXPOSE 26656 26657 1317 9090 8545 8546

HEALTHCHECK CMD curl --fail http://localhost:26657 || exit 1
# Replace the ENV section with this more flexible approach
ARG MONIKER="my-node"
ARG CHAIN_ID="evmos_9001-2"
ARG KEY_NAME="my-key"
ARG KEY_MNEMONIC="test test test test test test test test test test test junk"
ARG KEYRING_BACKEND="test"
ARG KEY_PASSPHRASE="12345678"

ENV MONIKER=$MONIKER \
    CHAIN_ID=$CHAIN_ID \
    KEY_NAME=$KEY_NAME \
    KEY_MNEMONIC=$KEY_MNEMONIC \
    KEYRING_BACKEND=$KEYRING_BACKEND \
    KEY_PASSPHRASE=$KEY_PASSPHRASE

# Default command: Initialize the chain if needed then start Evmos
CMD ["/bin/sh", "-c", \
"set -e && \
if [ ! -f /home/evmos/.evmosd/config/genesis.json ]; then \
  echo \"Initializing chain...\" && \
  rm -rf /home/evmos/.evmosd/config || true && \
  mkdir -p /home/evmos/.evmosd/config && \
  \
  # Initialize chain with proper chain ID \
  evmosd init \"$MONIKER\" --chain-id=\"$CHAIN_ID\" --overwrite --keyring-backend=$KEYRING_BACKEND && \
  \
  # Add key \
  echo \"$KEY_MNEMONIC\" | evmosd keys add \"$KEY_NAME\" --recover --keyring-backend=$KEYRING_BACKEND --output=json && \
  \
  # Get address \
  EVMOS_ADDRESS=$(evmosd keys show \"$KEY_NAME\" -a --keyring-backend=$KEYRING_BACKEND) && \
  \
  # Add genesis account \
  evmosd add-genesis-account \"$EVMOS_ADDRESS\" 100000000000000000000000000aevmos --keyring-backend=$KEYRING_BACKEND && \
  \
  # Create validator with increased delegation and explicit min-self-delegation \
  evmosd gentx \"$KEY_NAME\" 10000000000000000000000000000aevmos --chain-id=\"$CHAIN_ID\" --commission-rate=0.1 --min-self-delegation=10000000000000000000000000000 --keyring-backend=$KEYRING_BACKEND && \
  evmosd collect-gentxs && \
  \
  # Ensure chain ID is properly set in genesis \
  sed -i 's/\"chain_id\": *\"[^\"]*\"/\"chain_id\": \"'$CHAIN_ID'\"/' /home/evmos/.evmosd/config/genesis.json && \
  \
  # Configure minimum gas prices \
  evmosd config app.toml minimum-gas-prices \"0.0001aevmos\" && \
  \
  echo \"Initialization complete\"; \
fi && \
# Start the node with proper chain ID \
exec evmosd start --json-rpc.enable --json-rpc.address=\"0.0.0.0:8545\" --chain-id=\"$CHAIN_ID\""]