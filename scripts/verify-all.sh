#!/usr/bin/env bash
# Re-verify all 3 Agent Werewolf contracts on 0G ChainScan.
# Idempotent — safe to re-run; ChainScan will report "already verified" for any
# contract that's already source-verified.

set -euo pipefail

cd "$(dirname "$0")/.."

FORGE="${FORGE_BIN:-$HOME/.foundry/bin/forge}"
CAST="${CAST_BIN:-$HOME/.foundry/bin/cast}"

CHAIN_ID=16602
COMPILER="0.8.24"
EVM="cancun"
RUNS=200
VERIFIER_URL="https://chainscan-galileo.0g.ai/open/api"

# Load deployment addresses from deployments/galileo.json
DEPLOY_FILE="deployments/galileo.json"
if [ ! -f "$DEPLOY_FILE" ]; then
  echo "ERROR: $DEPLOY_FILE not found. Run ./deploy.sh first."
  exit 1
fi

REGISTRY=$(grep -oP '"AgentRegistry":\s*"\K[^"]+' "$DEPLOY_FILE")
ORACLE=$(grep -oP '"ReputationOracle":\s*"\K[^"]+' "$DEPLOY_FILE")
ARCHIVE=$(grep -oP '"GameArchive":\s*"\K[^"]+' "$DEPLOY_FILE")
GM=$(grep -oP '"GameMaster":\s*"\K[^"]+' "$DEPLOY_FILE")

CTOR_ARGS=$("$CAST" abi-encode "constructor(address)" "$GM")

verify() {
  local addr="$1"
  local path="$2"
  local extra="${3:-}"
  echo "==> Verifying $path @ $addr"
  # shellcheck disable=SC2086
  "$FORGE" verify-contract \
    --chain-id "$CHAIN_ID" \
    --num-of-optimizations "$RUNS" \
    --compiler-version "$COMPILER" \
    --evm-version "$EVM" \
    --verifier custom \
    --verifier-api-key "PLACEHOLDER" \
    --verifier-url "$VERIFIER_URL" \
    $extra \
    "$addr" \
    "$path"
  echo
}

verify "$REGISTRY" "src/AgentRegistry.sol:AgentRegistry"
verify "$ORACLE"   "src/ReputationOracle.sol:ReputationOracle" "--constructor-args $CTOR_ARGS"
verify "$ARCHIVE"  "src/GameArchive.sol:GameArchive"           "--constructor-args $CTOR_ARGS"

echo "All 3 contracts submitted for verification."
echo "Confirm at:"
echo "  https://chainscan-galileo.0g.ai/address/$REGISTRY"
echo "  https://chainscan-galileo.0g.ai/address/$ORACLE"
echo "  https://chainscan-galileo.0g.ai/address/$ARCHIVE"
