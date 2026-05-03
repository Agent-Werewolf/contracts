// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/// @title AgentRegistry
/// @notice ERC-8004 inspired agent identity registry for Agent Werewolf
/// @dev Each wallet can register exactly one agent. Each axlPeerId is globally unique.
contract AgentRegistry {
    struct Agent {
        uint256 agentId;
        address owner;
        bytes32 axlPeerId;
        string displayName;
        string metadataURI;
        uint64 registeredAt;
        bool active;
    }

    event AgentRegistered(
        uint256 indexed agentId,
        address indexed owner,
        bytes32 indexed axlPeerId,
        string displayName
    );
    event PeerIdUpdated(uint256 indexed agentId, bytes32 oldPeerId, bytes32 newPeerId);
    event AgentDeactivated(uint256 indexed agentId);
    event MetadataUpdated(uint256 indexed agentId, string metadataURI);

    error AgentNotFound(uint256 agentId);
    error NotAgentOwner(uint256 agentId, address caller);
    error PeerIdAlreadyRegistered(bytes32 peerId);
    error InvalidDisplayName();
    error AgentInactive(uint256 agentId);
    error WalletAlreadyRegistered(address wallet);

    mapping(uint256 => Agent) private _agents;
    mapping(address => uint256) private _agentByOwner;
    mapping(bytes32 => uint256) private _agentByPeerId;
    uint256 private _nextAgentId = 1;

    function register(
        bytes32 axlPeerId,
        string calldata displayName,
        string calldata metadataURI
    ) external returns (uint256 agentId) {
        if (_agentByOwner[msg.sender] != 0) revert WalletAlreadyRegistered(msg.sender);
        if (_agentByPeerId[axlPeerId] != 0) revert PeerIdAlreadyRegistered(axlPeerId);
        bytes memory nameBytes = bytes(displayName);
        if (nameBytes.length == 0 || nameBytes.length > 64) revert InvalidDisplayName();

        agentId = _nextAgentId++;
        _agents[agentId] = Agent({
            agentId: agentId,
            owner: msg.sender,
            axlPeerId: axlPeerId,
            displayName: displayName,
            metadataURI: metadataURI,
            registeredAt: uint64(block.timestamp),
            active: true
        });
        _agentByOwner[msg.sender] = agentId;
        _agentByPeerId[axlPeerId] = agentId;

        emit AgentRegistered(agentId, msg.sender, axlPeerId, displayName);
    }

    function updatePeerId(uint256 agentId, bytes32 newPeerId) external {
        Agent storage a = _agents[agentId];
        if (a.agentId == 0) revert AgentNotFound(agentId);
        if (a.owner != msg.sender) revert NotAgentOwner(agentId, msg.sender);
        if (_agentByPeerId[newPeerId] != 0) revert PeerIdAlreadyRegistered(newPeerId);

        bytes32 oldPeerId = a.axlPeerId;
        delete _agentByPeerId[oldPeerId];
        a.axlPeerId = newPeerId;
        _agentByPeerId[newPeerId] = agentId;

        emit PeerIdUpdated(agentId, oldPeerId, newPeerId);
    }

    function updateMetadata(uint256 agentId, string calldata metadataURI) external {
        Agent storage a = _agents[agentId];
        if (a.agentId == 0) revert AgentNotFound(agentId);
        if (a.owner != msg.sender) revert NotAgentOwner(agentId, msg.sender);
        a.metadataURI = metadataURI;
        emit MetadataUpdated(agentId, metadataURI);
    }

    function deactivate(uint256 agentId) external {
        Agent storage a = _agents[agentId];
        if (a.agentId == 0) revert AgentNotFound(agentId);
        if (a.owner != msg.sender) revert NotAgentOwner(agentId, msg.sender);
        a.active = false;
        emit AgentDeactivated(agentId);
    }

    function getAgent(uint256 agentId) external view returns (Agent memory) {
        Agent memory a = _agents[agentId];
        if (a.agentId == 0) revert AgentNotFound(agentId);
        return a;
    }

    function agentByOwner(address owner) external view returns (uint256) {
        return _agentByOwner[owner];
    }

    function agentByPeerId(bytes32 axlPeerId) external view returns (uint256) {
        return _agentByPeerId[axlPeerId];
    }

    function totalAgents() external view returns (uint256) {
        return _nextAgentId - 1;
    }
}
