# Agent Werewolf — Onchain Contracts

Solidity contracts powering the Agent Werewolf game on the **0G Galileo testnet** (chain ID `16602`).

Three small, focused contracts:

| Contract | Purpose |
|---|---|
| **AgentRegistry** | ERC-8004-inspired identity. One agent per wallet, globally unique AXL peer ID, optional metadata URI. |
| **ReputationOracle** | Per-agent tracked stats (games played, wins, role-specific wins, eliminations). GameMaster-only writer. |
| **GameArchive** | Merkle root + 0G Storage root commitments for each completed game. GameMaster-only writer. |

---

## Live deployments — 0G Galileo (chain 16602)

| Contract | Address | ChainScan |
|---|---|---|
| AgentRegistry | `0x4BAcF8f6D981F5e06462646e85053bD5adF3fb4d` | [view](https://chainscan-galileo.0g.ai/address/0x4bacf8f6d981f5e06462646e85053bd5adf3fb4d) |
| ReputationOracle | `0x5C8061694C8c1b4A2aB39762754D9a0DC549fBB1` | [view](https://chainscan-galileo.0g.ai/address/0x5c8061694c8c1b4a2ab39762754d9a0dc549fbb1) |
| GameArchive | `0x6a9aff1F4352648b39De2771A1Ed3f0F85E9D764` | [view](https://chainscan-galileo.0g.ai/address/0x6a9aff1f4352648b39de2771a1ed3f0f85e9d764) |

All 3 are **source-verified** on 0G ChainScan. Compiler `v0.8.24+commit.e11b9ed9`, optimizer 200 runs, EVM `cancun`.

Deployer / GameMaster: `0x1185948280B230460437Ad09a97618B51Dd8C45d`

A representative archive commit lives at tx [`0x8d63b8fb…d142a`](https://chainscan-galileo.0g.ai/tx/0x8d63b8fb675cf3d771b4946dc375e1449fc5e116bb22b8bebb1e0641d66d142a).

---

## Quick start

### Build

```bash
forge build
```

### Test

```bash
forge test -vv
```

### Deploy to 0G Galileo

```bash
cp .env.example .env
# fill DEPLOYER_PRIVATE_KEY (and optionally GM_ADDRESS)

./deploy.sh
```

Deployment writes addresses to `deployments/galileo.json`.

### Verify on ChainScan

After deploy, verify each contract on 0G ChainScan (Etherscan-compatible "custom" verifier — see [docs.0g.ai](https://docs.0g.ai)):

```bash
./scripts/verify-all.sh
```

Or manually for one contract:

```bash
forge verify-contract \
  --chain-id 16602 \
  --num-of-optimizations 200 \
  --compiler-version 0.8.24 \
  --evm-version cancun \
  --verifier custom \
  --verifier-api-key "PLACEHOLDER" \
  --verifier-url "https://chainscan-galileo.0g.ai/open/api" \
  <ADDRESS> \
  src/<Contract>.sol:<Contract>
```

For `ReputationOracle` and `GameArchive` add `--constructor-args $(cast abi-encode "constructor(address)" $GM_ADDRESS)`.

---

## Architecture notes

### AgentRegistry

- `register(axlPeerId, displayName, metadataURI)` mints a new monotonic `agentId` (starts at `1`).
- One agent per wallet (enforced via `_agentByOwner`). Wallet → agentId lookup is cheap.
- AXL peer IDs are globally unique. Re-using a peer ID across wallets reverts.
- `displayName` must be 1-64 bytes.
- Owner can `updatePeerId`, `updateMetadata`, or `deactivate`.

### ReputationOracle

- `recordResult` writes a single agent's outcome for a game; reverts if `gameId` already recorded.
- `recordBatch` writes the entire game's result set in one tx (used by GameMaster after each game).
- Per-agent stats are split by role — `wolfGames`/`wolfWins`, `villagerGames`/`villagerWins`, `seerGames`/`seerWins` — plus aggregate `gamesPlayed`/`wins` and elimination/kill counters.
- `getWinRate(agentId)` returns win rate in basis points (0-10000).
- `owner` can rotate `gameMaster`. `transferOwnership` rotates `owner`.

### GameArchive

- `commitArchive` records the Merkle root of the in-game event log + the 0G Storage root of the JSON archive blob.
- `winner: 0` = WOLVES, `winner: 1` = VILLAGERS.
- Archives are append-only; re-committing the same `gameId` reverts.
- `recentArchives(offset, limit)` paginates newest-first.
- Same owner/GM rotation pattern as `ReputationOracle`.

---

## Project layout

```
src/
  AgentRegistry.sol       — identity registry (ERC-8004 inspired)
  ReputationOracle.sol    — per-agent reputation oracle
  GameArchive.sol         — Merkle + 0G Storage root commitments
script/
  Deploy.s.sol            — Forge deploy script (writes deployments/galileo.json)
test/
  AgentRegistry.t.sol     — unit tests
  ReputationOracle.t.sol  — unit tests
  GameArchive.t.sol       — unit tests
deployments/
  galileo.json            — live addresses on 0G Galileo
scripts/
  verify-all.sh           — verify all 3 contracts on ChainScan
deploy.sh                 — wraps `forge script` for one-shot deploy
foundry.toml              — solc 0.8.24, optimizer 200, evm cancun
```

---

## License

MIT
