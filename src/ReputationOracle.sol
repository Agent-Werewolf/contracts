// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/// @title ReputationOracle
/// @notice Tracks per-agent game outcomes for Agent Werewolf
/// @dev Only the GameMaster address can write. Owner can rotate GameMaster.
contract ReputationOracle {
    enum Role { NONE, WEREWOLF, VILLAGER, SEER }
    enum Outcome { LOSS, WIN }

    struct AgentStats {
        uint64 gamesPlayed;
        uint64 wins;
        uint64 wolfGames;
        uint64 wolfWins;
        uint64 villagerGames;
        uint64 villagerWins;
        uint64 seerGames;
        uint64 seerWins;
        uint64 timesEliminated;
        uint64 timesKilled;
    }

    event ResultRecorded(
        bytes32 indexed gameId,
        uint256 indexed agentId,
        Role role,
        Outcome outcome,
        bool eliminatedByVote,
        bool killedByWolves
    );
    event GameMasterUpdated(address indexed oldGM, address indexed newGM);
    event OwnerUpdated(address indexed oldOwner, address indexed newOwner);

    error NotGameMaster(address caller);
    error NotOwner(address caller);
    error GameAlreadyRecorded(bytes32 gameId);
    error LengthMismatch();
    error InvalidRole();

    mapping(uint256 => AgentStats) private _stats;
    mapping(bytes32 => bool) private _recordedGames;

    address public gameMaster;
    address public owner;

    constructor(address _gameMaster) {
        owner = msg.sender;
        gameMaster = _gameMaster;
    }

    modifier onlyGameMaster() {
        if (msg.sender != gameMaster) revert NotGameMaster(msg.sender);
        _;
    }

    modifier onlyOwner() {
        if (msg.sender != owner) revert NotOwner(msg.sender);
        _;
    }

    function setGameMaster(address newGM) external onlyOwner {
        emit GameMasterUpdated(gameMaster, newGM);
        gameMaster = newGM;
    }

    function transferOwnership(address newOwner) external onlyOwner {
        emit OwnerUpdated(owner, newOwner);
        owner = newOwner;
    }

    function recordResult(
        bytes32 gameId,
        uint256 agentId,
        Role role,
        Outcome outcome,
        bool eliminatedByVote,
        bool killedByWolves
    ) external onlyGameMaster {
        _recordOne(gameId, agentId, role, outcome, eliminatedByVote, killedByWolves);
    }

    function recordBatch(
        bytes32 gameId,
        uint256[] calldata agentIds,
        Role[] calldata roles,
        Outcome[] calldata outcomes,
        bool[] calldata eliminatedByVote,
        bool[] calldata killedByWolves
    ) external onlyGameMaster {
        if (_recordedGames[gameId]) revert GameAlreadyRecorded(gameId);
        uint256 n = agentIds.length;
        if (
            roles.length != n ||
            outcomes.length != n ||
            eliminatedByVote.length != n ||
            killedByWolves.length != n
        ) revert LengthMismatch();

        _recordedGames[gameId] = true;
        for (uint256 i = 0; i < n; ++i) {
            _recordOneNoDedup(gameId, agentIds[i], roles[i], outcomes[i], eliminatedByVote[i], killedByWolves[i]);
        }
    }

    function _recordOne(
        bytes32 gameId,
        uint256 agentId,
        Role role,
        Outcome outcome,
        bool eliminatedByVote,
        bool killedByWolves
    ) internal {
        if (_recordedGames[gameId]) revert GameAlreadyRecorded(gameId);
        _recordedGames[gameId] = true;
        _recordOneNoDedup(gameId, agentId, role, outcome, eliminatedByVote, killedByWolves);
    }

    function _recordOneNoDedup(
        bytes32 gameId,
        uint256 agentId,
        Role role,
        Outcome outcome,
        bool eliminatedByVote,
        bool killedByWolves
    ) internal {
        if (role == Role.NONE) revert InvalidRole();
        AgentStats storage s = _stats[agentId];
        unchecked {
            s.gamesPlayed += 1;
            if (outcome == Outcome.WIN) s.wins += 1;
            if (role == Role.WEREWOLF) {
                s.wolfGames += 1;
                if (outcome == Outcome.WIN) s.wolfWins += 1;
            } else if (role == Role.VILLAGER) {
                s.villagerGames += 1;
                if (outcome == Outcome.WIN) s.villagerWins += 1;
            } else if (role == Role.SEER) {
                s.seerGames += 1;
                if (outcome == Outcome.WIN) s.seerWins += 1;
            }
            if (eliminatedByVote) s.timesEliminated += 1;
            if (killedByWolves) s.timesKilled += 1;
        }
        emit ResultRecorded(gameId, agentId, role, outcome, eliminatedByVote, killedByWolves);
    }

    function getStats(uint256 agentId) external view returns (AgentStats memory) {
        return _stats[agentId];
    }

    function getWinRate(uint256 agentId) external view returns (uint256 bps) {
        AgentStats memory s = _stats[agentId];
        if (s.gamesPlayed == 0) return 0;
        return (uint256(s.wins) * 10000) / uint256(s.gamesPlayed);
    }

    function gameRecorded(bytes32 gameId) external view returns (bool) {
        return _recordedGames[gameId];
    }
}
