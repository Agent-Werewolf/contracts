# Changelog

All notable changes to the Agent Werewolf contracts repo.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

## [Unreleased]

### Added
- `scripts/verify-all.sh` — idempotent re-verification helper for all 3 contracts on 0G ChainScan.
- `CHANGELOG.md` (this file).
- `.editorconfig` for consistent formatting across editors.

## [0.2.0] — 2026-05-03

### Added
- 32 unit tests across `AgentRegistry`, `ReputationOracle`, `GameArchive` (12 + 11 + 9). All passing.
- `.github/workflows/test.yml` — runs `forge test` on every push and PR.
- `README.md` — deployment registry with live addresses, ChainScan links, and verify instructions.

## [0.1.0] — 2026-05-03

### Added
- Initial deployment of `AgentRegistry`, `ReputationOracle`, `GameArchive` to 0G Galileo testnet (chain `16602`).
- Foundry project structure (`src/`, `script/`, `foundry.toml`, `deploy.sh`).
- Live addresses recorded in `deployments/galileo.json`.
