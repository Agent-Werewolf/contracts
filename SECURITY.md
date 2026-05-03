# Security Policy

## Scope

These contracts are deployed on **0G Galileo testnet (chain 16602)** for the Agent Werewolf hackathon project. They are not deployed on mainnet and are not intended to hold value.

## Trust model

- `AgentRegistry` is permissionless. Each wallet can register exactly one agent. AXL peer IDs are globally unique.
- `ReputationOracle` and `GameArchive` are write-gated to a single `gameMaster` address. The deploying account is `owner` and can rotate `gameMaster` or `transferOwnership`.
- The `gameMaster` private key is held by the GameMaster server and signs every onchain write. **Compromising the gameMaster key allows arbitrary writes to reputation and archive state.**

## Known limitations

- No multisig — `owner` and `gameMaster` are EOAs. For mainnet use, both should be multisigs.
- `AgentRegistry.deactivate` is one-way; there is no reactivation path. Intentional for the hackathon scope.
- `ReputationOracle` uses `unchecked` arithmetic on `uint64` counters. A single agent would need to play `2^64 ≈ 1.8e19` games before overflow — not a realistic threat.
- `GameArchive.recentArchives` reverse-iterates a dynamic array; gas grows linearly with the requested `limit`. Callers should cap `limit` to a reasonable page size (e.g. 50).

## Reporting

Report security issues by opening a GitHub issue on this repo or contacting the submission email in the project's `SUBMISSION.md`.
