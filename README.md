```
git clone https://github.com/evmos/evmos.git 

VIA DOCKER
DOCKER_BUILDKIT=1  docker build -t evmos -f Dockerfile evmos/ --no-cache
docker run -it --name evmos-node   -p 26656:26656 -p 26657:26657   -p 1317:1317 -p 8545:8545 -p 8546:8546  -e     CHAIN_ID="evmos_9001-2"  -e MONIKER="my-node"   -e KEY_NAME="my-key"   -e KEY_MNEMONIC="test test test test test test test test test test test junk"   evmos 

VIA DOCKER_COMPOSE
docker-compose build
docker-compose up

```
