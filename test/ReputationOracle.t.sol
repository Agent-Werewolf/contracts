// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";
import {ReputationOracle} from "../src/ReputationOracle.sol";

contract ReputationOracleTest is Test {
    ReputationOracle oracle;

    address owner = address(this);
    address gm = address(0xCAFE);
    address attacker = address(0xBAD);

    bytes32 gameId = bytes32(uint256(0xDEAD));

    function setUp() public {
        oracle = new ReputationOracle(gm);
    }

    function test_constructor_setsRoles() public view {
        assertEq(oracle.owner(), owner);
        assertEq(oracle.gameMaster(), gm);
    }

    function test_recordResult_updatesStats() public {
        vm.prank(gm);
        oracle.recordResult(gameId, 1, ReputationOracle.Role.WEREWOLF, ReputationOracle.Outcome.WIN, false, false);

        ReputationOracle.AgentStats memory s = oracle.getStats(1);
        assertEq(s.gamesPlayed, 1);
        assertEq(s.wins, 1);
        assertEq(s.wolfGames, 1);
        assertEq(s.wolfWins, 1);
        assertEq(s.villagerGames, 0);
    }

    function test_recordResult_notGameMaster_reverts() public {
        vm.expectRevert(abi.encodeWithSelector(ReputationOracle.NotGameMaster.selector, attacker));
        vm.prank(attacker);
        oracle.recordResult(gameId, 1, ReputationOracle.Role.WEREWOLF, ReputationOracle.Outcome.WIN, false, false);
    }

    function test_recordResult_dedupesByGameId() public {
        vm.prank(gm);
        oracle.recordResult(gameId, 1, ReputationOracle.Role.VILLAGER, ReputationOracle.Outcome.LOSS, false, false);

        vm.expectRevert(abi.encodeWithSelector(ReputationOracle.GameAlreadyRecorded.selector, gameId));
        vm.prank(gm);
        oracle.recordResult(gameId, 2, ReputationOracle.Role.VILLAGER, ReputationOracle.Outcome.WIN, false, false);
    }

    function test_recordResult_invalidRole_reverts() public {
        vm.expectRevert(ReputationOracle.InvalidRole.selector);
        vm.prank(gm);
        oracle.recordResult(gameId, 1, ReputationOracle.Role.NONE, ReputationOracle.Outcome.LOSS, false, false);
    }

    function test_recordBatch_writesAllAgents() public {
        uint256[] memory agents = new uint256[](3);
        agents[0] = 1; agents[1] = 2; agents[2] = 3;

        ReputationOracle.Role[] memory roles = new ReputationOracle.Role[](3);
        roles[0] = ReputationOracle.Role.WEREWOLF;
        roles[1] = ReputationOracle.Role.VILLAGER;
        roles[2] = ReputationOracle.Role.SEER;

        ReputationOracle.Outcome[] memory outs = new ReputationOracle.Outcome[](3);
        outs[0] = ReputationOracle.Outcome.WIN;
        outs[1] = ReputationOracle.Outcome.LOSS;
        outs[2] = ReputationOracle.Outcome.LOSS;

        bool[] memory elims = new bool[](3);
        elims[1] = true;

        bool[] memory kills = new bool[](3);
        kills[2] = true;

        vm.prank(gm);
        oracle.recordBatch(gameId, agents, roles, outs, elims, kills);

        assertEq(oracle.getStats(1).wolfWins, 1);
        assertEq(oracle.getStats(2).timesEliminated, 1);
        assertEq(oracle.getStats(3).timesKilled, 1);
        assertTrue(oracle.gameRecorded(gameId));
    }

    function test_recordBatch_lengthMismatch_reverts() public {
        uint256[] memory agents = new uint256[](2);
        ReputationOracle.Role[] memory roles = new ReputationOracle.Role[](1);
        ReputationOracle.Outcome[] memory outs = new ReputationOracle.Outcome[](2);
        bool[] memory elims = new bool[](2);
        bool[] memory kills = new bool[](2);

        vm.expectRevert(ReputationOracle.LengthMismatch.selector);
        vm.prank(gm);
        oracle.recordBatch(gameId, agents, roles, outs, elims, kills);
    }

    function test_getWinRate_zeroGames_returnsZero() public view {
        assertEq(oracle.getWinRate(42), 0);
    }

    function test_getWinRate_threeOfSixIs5000Bps() public {
        // Record 6 separate games, agent wins 3 of them
        for (uint256 i = 0; i < 6; ++i) {
            bytes32 gid = bytes32(i + 1);
            ReputationOracle.Outcome o = i < 3 ? ReputationOracle.Outcome.WIN : ReputationOracle.Outcome.LOSS;
            vm.prank(gm);
            oracle.recordResult(gid, 1, ReputationOracle.Role.WEREWOLF, o, false, false);
        }
        assertEq(oracle.getWinRate(1), 5000);
    }

    function test_setGameMaster_onlyOwner() public {
        vm.expectRevert(abi.encodeWithSelector(ReputationOracle.NotOwner.selector, attacker));
        vm.prank(attacker);
        oracle.setGameMaster(attacker);

        oracle.setGameMaster(attacker);
        assertEq(oracle.gameMaster(), attacker);
    }

    function test_transferOwnership_onlyOwner() public {
        vm.expectRevert(abi.encodeWithSelector(ReputationOracle.NotOwner.selector, attacker));
        vm.prank(attacker);
        oracle.transferOwnership(attacker);

        oracle.transferOwnership(attacker);
        assertEq(oracle.owner(), attacker);
    }
}
