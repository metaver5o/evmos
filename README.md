# Evmos Multi-Chain Deployment System

## Overview

This project provides a flexible Docker-based setup for running multiple Evmos blockchain nodes (mainnet, testnet, local) with isolated configurations. The system allows you to easily deploy and manage different Evmos chains with customized parameters.

## Features

- 🚀 Deploy multiple Evmos chains simultaneously
- 🐣 Customizable configurations per chain
- 💓 Isolated data volumes for each chain
- 💨 Monitoring and management tools
- 💈 Easy chain switching and configuration

## Quick Start

### Prerequisites

- Docker installed
- Docker Compose (optional for advanced setup)
- Basic understanding of Evmos blockchain

### Installation

1. Clone this repository:
    ```bash
    git clone https://github.com/metaver5o/evmos.git
    cd evmos
    git clone https://github.com/evmos/evmos.git
    ```

2. Build the Docker image:
    ```bash
        DOCKER_BUILDKIT=1  docker build -t evmos -f Dockerfile evmos/ --no-cache
    ```

### Basic Usage

Deploy a local development chain:
```bash
    $ source .env
    $ evmos local
```

Deploy a mainnet node:
```bash
    $ source .env
    $ evmos mainnet
```

Deploy a testnet node:
```bash
    $ source .env
    $ evmos testnet
```

## Configuration

### Environment Files

Create `.env` files for each chain configuration:

- `evmos-mainnet.env` - Mainnet configuration
- `evmos-testnet.env` - Testnet configuration
- `evmos-local.env` - Local development chain

Example configuration:
```bash
# evmos-mainnet.env
MONIKER="mainnet-validator"
CHAIN_ID="evmos_9001-2"
KEY_NAME="mainnet-key"
MINIMUM_GAS_PRICES="0.0025aevmos"
```

### Port Mapping

Default ports:

- Mainnet: 26656, 26657, 1317, 8545
- Testnet: 26658, 26659, 1318, 8547
- Local: 26660, 26661, 1319, 8549

## Management Commands

| Command | Description |
--------|-----------------|
| `evmos-list` | List all running Evmos nodes |
| `evmos-stop [chain]` | Stop a specific chain |
| `evmos-logs [chain]` | View logs for a chain |
| `evmos-reset [chain]` | Delete chain data and reset |

## Advanced Setup

### Docker Compose - still under development

For running multiple chains simultaneously:

```bash
docker-compose up -d evmos-mainnet evmos-testnet
```

### Custom Chains

To deploy a custom chain configuration:

1. Create a new env file (e.g., `evmos-custom.env`)
2. Run with:
    ```bash
    evmos custom
    ```

## Monitoring

Access the following endpoints for each chain:

- RPC: `http://localhost:[PORT]/`
- REST: `http://localhost:[API_PORT]/`
- JSON-RPC: `http://localhost:[JSON-RPC_PORT]/`

## Troubleshooting

Common issues:
1. **Port conflicts**: Ensure ports are available or modify the port mappings
2. **Volume permissions**: Run `docker volume prune` if having permission issues
3. **Chain synchronization**: Check logs with `evmos-logs [chain]`

## License

This project is licensed under the MIT License.

## Support

For support, please open an issue in the GitHub repository.

---

**Note**: Always ensure you have proper backups of your validator keys and configuration before making changes to your nodes.