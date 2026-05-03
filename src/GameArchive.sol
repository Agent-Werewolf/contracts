// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/// @title GameArchive
/// @notice Stores Merkle root + 0G Storage root commitments for each Werewolf game
contract GameArchive {
    struct ArchiveRecord {
        bytes32 gameId;
        bytes32 merkleRoot;
        bytes32 storageRoot;
        uint256[] participants;
        uint64 startedAt;
        uint64 endedAt;
        uint8 winner; // 0 = WOLVES, 1 = VILLAGERS
    }

    event ArchiveCommitted(
        bytes32 indexed gameId,
        bytes32 merkleRoot,
        bytes32 storageRoot,
        uint8 winner
    );
    event GameMasterUpdated(address indexed oldGM, address indexed newGM);
    event OwnerUpdated(address indexed oldOwner, address indexed newOwner);

    error NotGameMaster(address caller);
    error NotOwner(address caller);
    error ArchiveAlreadyCommitted(bytes32 gameId);
    error ArchiveNotFound(bytes32 gameId);

    mapping(bytes32 => ArchiveRecord) private _archives;
    bytes32[] private _gameIds;

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

    function commitArchive(
        bytes32 gameId,
        bytes32 merkleRoot,
        bytes32 storageRoot,
        uint256[] calldata participants,
        uint64 startedAt,
        uint64 endedAt,
        uint8 winner
    ) external onlyGameMaster {
        if (_archives[gameId].gameId != bytes32(0)) revert ArchiveAlreadyCommitted(gameId);

        _archives[gameId] = ArchiveRecord({
            gameId: gameId,
            merkleRoot: merkleRoot,
            storageRoot: storageRoot,
            participants: participants,
            startedAt: startedAt,
            endedAt: endedAt,
            winner: winner
        });
        _gameIds.push(gameId);

        emit ArchiveCommitted(gameId, merkleRoot, storageRoot, winner);
    }

    function getArchive(bytes32 gameId) external view returns (ArchiveRecord memory) {
        ArchiveRecord memory r = _archives[gameId];
        if (r.gameId == bytes32(0)) revert ArchiveNotFound(gameId);
        return r;
    }

    function totalArchives() external view returns (uint256) {
        return _gameIds.length;
    }

    function recentArchives(uint256 offset, uint256 limit)
        external
        view
        returns (bytes32[] memory gameIds)
    {
        uint256 total = _gameIds.length;
        if (offset >= total) return new bytes32[](0);
        uint256 end = offset + limit;
        if (end > total) end = total;
        uint256 size = end - offset;
        gameIds = new bytes32[](size);
        for (uint256 i = 0; i < size; ++i) {
            // Return newest first: reverse iteration
            gameIds[i] = _gameIds[total - 1 - offset - i];
        }
    }
}
