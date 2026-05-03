// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";
import {AgentRegistry} from "../src/AgentRegistry.sol";

contract AgentRegistryTest is Test {
    AgentRegistry registry;

    address alice = address(0xA11CE);
    address bob = address(0xB0B);

    bytes32 peerA = bytes32(uint256(0xAAAA));
    bytes32 peerB = bytes32(uint256(0xBBBB));

    function setUp() public {
        registry = new AgentRegistry();
    }

    function test_register_assignsMonotonicId() public {
        vm.prank(alice);
        uint256 id1 = registry.register(peerA, "alice", "ipfs://meta-a");

        vm.prank(bob);
        uint256 id2 = registry.register(peerB, "bob", "ipfs://meta-b");

        assertEq(id1, 1);
        assertEq(id2, 2);
        assertEq(registry.totalAgents(), 2);
    }

    function test_register_emitsEvent() public {
        vm.expectEmit(true, true, true, true);
        emit AgentRegistry.AgentRegistered(1, alice, peerA, "alice");
        vm.prank(alice);
        registry.register(peerA, "alice", "");
    }

    function test_register_lookupsWork() public {
        vm.prank(alice);
        uint256 id = registry.register(peerA, "alice", "");

        assertEq(registry.agentByOwner(alice), id);
        assertEq(registry.agentByPeerId(peerA), id);

        AgentRegistry.Agent memory a = registry.getAgent(id);
        assertEq(a.owner, alice);
        assertEq(a.axlPeerId, peerA);
        assertEq(a.displayName, "alice");
        assertTrue(a.active);
    }

    function test_register_walletAlreadyRegistered_reverts() public {
        vm.prank(alice);
        registry.register(peerA, "alice", "");

        vm.expectRevert(abi.encodeWithSelector(AgentRegistry.WalletAlreadyRegistered.selector, alice));
        vm.prank(alice);
        registry.register(peerB, "alice2", "");
    }

    function test_register_peerIdAlreadyRegistered_reverts() public {
        vm.prank(alice);
        registry.register(peerA, "alice", "");

        vm.expectRevert(abi.encodeWithSelector(AgentRegistry.PeerIdAlreadyRegistered.selector, peerA));
        vm.prank(bob);
        registry.register(peerA, "bob", "");
    }

    function test_register_emptyDisplayName_reverts() public {
        vm.expectRevert(AgentRegistry.InvalidDisplayName.selector);
        vm.prank(alice);
        registry.register(peerA, "", "");
    }

    function test_register_displayNameTooLong_reverts() public {
        bytes memory n = new bytes(65);
        for (uint256 i; i < 65; ++i) n[i] = bytes1("x");
        vm.expectRevert(AgentRegistry.InvalidDisplayName.selector);
        vm.prank(alice);
        registry.register(peerA, string(n), "");
    }

    function test_updatePeerId_swapsLookup() public {
        vm.prank(alice);
        uint256 id = registry.register(peerA, "alice", "");

        vm.prank(alice);
        registry.updatePeerId(id, peerB);

        assertEq(registry.agentByPeerId(peerA), 0);
        assertEq(registry.agentByPeerId(peerB), id);
    }

    function test_updatePeerId_notOwner_reverts() public {
        vm.prank(alice);
        uint256 id = registry.register(peerA, "alice", "");

        vm.expectRevert(abi.encodeWithSelector(AgentRegistry.NotAgentOwner.selector, id, bob));
        vm.prank(bob);
        registry.updatePeerId(id, peerB);
    }

    function test_deactivate_setsInactive() public {
        vm.prank(alice);
        uint256 id = registry.register(peerA, "alice", "");

        vm.prank(alice);
        registry.deactivate(id);

        assertFalse(registry.getAgent(id).active);
    }

    function test_getAgent_notFound_reverts() public {
        vm.expectRevert(abi.encodeWithSelector(AgentRegistry.AgentNotFound.selector, 999));
        registry.getAgent(999);
    }

    function test_updateMetadata_persists() public {
        vm.prank(alice);
        uint256 id = registry.register(peerA, "alice", "ipfs://old");

        vm.prank(alice);
        registry.updateMetadata(id, "ipfs://new");

        assertEq(registry.getAgent(id).metadataURI, "ipfs://new");
    }
}
