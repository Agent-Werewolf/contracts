#!/usr/bin/env bash
# Deploy all 3 contracts to 0G Galileo testnet
set -euo pipefail

cd "$(dirname "$0")"
mkdir -p deployments

# Source .env (contains DEPLOYER_PRIVATE_KEY, OG_RPC_URL, GM_ADDRESS)
if [ -f .env ]; then
  # Strip CRLF and source
  set -a
  source <(tr -d '\r' < .env)
  set +a
else
  echo "ERROR: contracts/.env not found. Copy .env.example and fill in values."
  exit 1
fi

: "${DEPLOYER_PRIVATE_KEY:?must be set in .env}"
: "${OG_RPC_URL:=https://evmrpc-testnet.0g.ai}"

# Normalize: ensure 0x prefix on private key
if [[ ! "$DEPLOYER_PRIVATE_KEY" =~ ^0x ]]; then
  export DEPLOYER_PRIVATE_KEY="0x$DEPLOYER_PRIVATE_KEY"
fi

FORGE="${FORGE_BIN:-$HOME/.foundry/bin/forge}"

echo "Deploying to $OG_RPC_URL"
"$FORGE" script script/Deploy.s.sol \
  --rpc-url "$OG_RPC_URL" \
  --broadcast \
  --legacy \
  --skip-simulation \
  --chain-id 16602 \
  --slow \
  -vvv
