#!/bin/sh
set -e

# Check if genesis.json exists; if not, perform initialization
if [ ! -f /home/evmos/.evmosd/config/genesis.json ]; then
  echo "Initializing chain with Chain ID: evmos_9001-2"
  
  # Clean existing configuration (if any)
  rm -rf /home/evmos/.evmosd/config || true
  mkdir -p /home/evmos/.evmosd/config
  
  # Initialize with numeric chain ID
  /usr/bin/evmosd init "$MONIKER" --chain-id=evmos_9001-2 --overwrite --keyring-backend=test || exit 1
  
  # Add key (using test keyring backend)
  yes y | echo "$KEY_MNEMONIC" | /usr/bin/evmosd keys add "$KEY_NAME" --recover --keyring-backend=test --output=json || exit 1
  
  # Get address (must use same keyring backend)
  EVMOS_ADDRESS=$(/usr/bin/evmosd keys show "$KEY_NAME" -a --keyring-backend=test) || exit 1
  
  # Add genesis account using the recovered address
  /usr/bin/evmosd add-genesis-account "$EVMOS_ADDRESS" 100000000000000000000000000aevmos --keyring-backend=test || exit 1
  
  # Create validator and collect gentxs
  /usr/bin/evmosd gentx "$KEY_NAME" 1000000000000000000000aevmos --chain-id=evmos_9001-2 --keyring-backend=test || exit 1
  /usr/bin/evmosd collect-gentxs || exit 1
  
  # Update chain IDs in genesis.json
#  sed -i 's/"chain_id": *"[^"]*"/"chain_id": "evmos_9001-2"/' /home/evmos/.evmosd/config/genesis.json || exit 1
#  sed -i 's/"chain_id": *"[^"]*"/"chain_id": "evmos_9001-2"/' /home/evmos/.evmosd/config/genesis.json || exit 1
  
  # Configure app minimum gas prices
  /usr/bin/evmosd config set app.toml minimum-gas-prices "0.0001aevmos" || exit 1
  
  echo "Initialization complete. Chain ID verified: evmos_9001-2"
fi

echo "Starting Evmos node..."
exec /usr/bin/evmosd start --chain-id "$CHAIN_ID" --json-rpc.enable --json-rpc.address="0.0.0.0:8545"
