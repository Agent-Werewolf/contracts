// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";
import {GameArchive} from "../src/GameArchive.sol";

contract GameArchiveTest is Test {
    GameArchive archive;

    address owner = address(this);
    address gm = address(0xCAFE);
    address attacker = address(0xBAD);

    bytes32 gid1 = bytes32(uint256(0xAA01));
    bytes32 gid2 = bytes32(uint256(0xAA02));
    bytes32 merkle = keccak256("merkle-root");
    bytes32 storageRoot = keccak256("0g-storage-root");

    function setUp() public {
        archive = new GameArchive(gm);
    }

    function _participants(uint256 n) internal pure returns (uint256[] memory ps) {
        ps = new uint256[](n);
        for (uint256 i; i < n; ++i) ps[i] = i + 1;
    }

    function test_constructor_setsRoles() public view {
        assertEq(archive.owner(), owner);
        assertEq(archive.gameMaster(), gm);
    }

    function test_commitArchive_storesAndEmits() public {
        vm.expectEmit(true, false, false, true);
        emit GameArchive.ArchiveCommitted(gid1, merkle, storageRoot, 0);

        vm.prank(gm);
        archive.commitArchive(gid1, merkle, storageRoot, _participants(8), 1000, 2000, 0);

        GameArchive.ArchiveRecord memory r = archive.getArchive(gid1);
        assertEq(r.gameId, gid1);
        assertEq(r.merkleRoot, merkle);
        assertEq(r.storageRoot, storageRoot);
        assertEq(r.participants.length, 8);
        assertEq(r.startedAt, 1000);
        assertEq(r.endedAt, 2000);
        assertEq(r.winner, 0);
    }

    function test_commitArchive_notGameMaster_reverts() public {
        vm.expectRevert(abi.encodeWithSelector(GameArchive.NotGameMaster.selector, attacker));
        vm.prank(attacker);
        archive.commitArchive(gid1, merkle, storageRoot, _participants(8), 1000, 2000, 1);
    }

    function test_commitArchive_dedupesByGameId() public {
        vm.prank(gm);
        archive.commitArchive(gid1, merkle, storageRoot, _participants(8), 1000, 2000, 0);

        vm.expectRevert(abi.encodeWithSelector(GameArchive.ArchiveAlreadyCommitted.selector, gid1));
        vm.prank(gm);
        archive.commitArchive(gid1, merkle, storageRoot, _participants(8), 3000, 4000, 1);
    }

    function test_getArchive_notFound_reverts() public {
        vm.expectRevert(abi.encodeWithSelector(GameArchive.ArchiveNotFound.selector, gid1));
        archive.getArchive(gid1);
    }

    function test_recentArchives_returnsNewestFirst() public {
        vm.startPrank(gm);
        archive.commitArchive(gid1, merkle, storageRoot, _participants(2), 1000, 2000, 0);
        archive.commitArchive(gid2, merkle, storageRoot, _participants(2), 3000, 4000, 1);
        vm.stopPrank();

        bytes32[] memory recent = archive.recentArchives(0, 10);
        assertEq(recent.length, 2);
        assertEq(recent[0], gid2); // newest first
        assertEq(recent[1], gid1);
    }

    function test_recentArchives_paginates() public {
        vm.startPrank(gm);
        for (uint256 i; i < 5; ++i) {
            archive.commitArchive(bytes32(i + 100), merkle, storageRoot, _participants(2), uint64(i), uint64(i + 1), 0);
        }
        vm.stopPrank();

        bytes32[] memory page1 = archive.recentArchives(0, 2);
        assertEq(page1.length, 2);
        assertEq(page1[0], bytes32(uint256(104)));
        assertEq(page1[1], bytes32(uint256(103)));

        bytes32[] memory page2 = archive.recentArchives(2, 2);
        assertEq(page2.length, 2);
        assertEq(page2[0], bytes32(uint256(102)));
        assertEq(page2[1], bytes32(uint256(101)));
    }

    function test_totalArchives_increments() public {
        assertEq(archive.totalArchives(), 0);
        vm.prank(gm);
        archive.commitArchive(gid1, merkle, storageRoot, _participants(1), 1, 2, 0);
        assertEq(archive.totalArchives(), 1);
    }

    function test_setGameMaster_onlyOwner() public {
        vm.expectRevert(abi.encodeWithSelector(GameArchive.NotOwner.selector, attacker));
        vm.prank(attacker);
        archive.setGameMaster(attacker);

        archive.setGameMaster(attacker);
        assertEq(archive.gameMaster(), attacker);
    }
}
