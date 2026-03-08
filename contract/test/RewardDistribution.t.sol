// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {Test} from "forge-std/Test.sol";
import {EvoPolkaArena} from "../src/EvoPolkaArena.sol";
import {ArenaHarness} from "./helpers/ArenaHarness.sol";

contract RewardDistributionTest is Test {
    ArenaHarness public arena;

    address player1 = address(0x1);
    address player2 = address(0x2);
    uint256 arenaId;
    uint256 stake = 1 ether;

    function setUp() public {
        arena = new ArenaHarness();
        vm.deal(player1, 100 ether);
        vm.deal(player2, 100 ether);

        arenaId = arena.createArena({
            stakePerPlayer: stake,
            maxRounds: 3,
            gridSize: 20,
            creaturesPerPlayer: 3,
            mutationRate: 500,
            roundInterval: 1
        });

        vm.prank(player1);
        arena.joinArena{value: stake}(arenaId);

        vm.prank(player2);
        arena.joinArena{value: stake}(arenaId);

        vm.prank(player1);
        arena.startArena(arenaId);
    }

    function test_Rewards_ProtocolFee() public {
        // Force arena to finish
        arena.setArenaState(arenaId, EvoPolkaArena.ArenaState.FINISHED);

        // Distribute rewards
        arena.distributeRewards(arenaId);

        // Calculate expected fee: 2% of total pot
        uint256 totalPot = stake * 2;
        uint256 expectedFee = (totalPot * 200) / 10000;

        uint256 actualFee = arena.pendingRewards(arenaId, arena.feeRecipient());
        assertEq(actualFee, expectedFee, "Protocol fee should be 2%");
    }

    function test_Rewards_ProportionalDistribution() public {
        uint256[] memory ids = arena.getCreatureIds(arenaId);

        // Player 1 has creatures 0, 1, 2
        // Player 2 has creatures 3, 4, 5

        // Kill 2 of Player 2's creatures
        arena.killCreature(arenaId, ids[3]);
        arena.killCreature(arenaId, ids[4]);

        // Now Player 1 has 3 survivors, Player 2 has 1 survivor. Total = 4.
        // P1 should get 75% of distributable pot. P2 should get 25%.

        arena.setArenaState(arenaId, EvoPolkaArena.ArenaState.FINISHED);
        arena.distributeRewards(arenaId);

        uint256 totalPot = stake * 2;
        uint256 protocolFee = (totalPot * 200) / 10000;
        uint256 distributablePot = totalPot - protocolFee;

        uint256 p1Expected = (distributablePot * 3) / 4;
        uint256 p2Expected = (distributablePot * 1) / 4;

        uint256 p1Actual = arena.pendingRewards(arenaId, player1);
        uint256 p2Actual = arena.pendingRewards(arenaId, player2);

        assertEq(p1Actual, p1Expected, "Player 1 should receive 75% of pot");
        assertEq(p2Actual, p2Expected, "Player 2 should receive 25% of pot");
    }

    function test_Rewards_AllDeadRefund() public {
        uint256[] memory ids = arena.getCreatureIds(arenaId);

        // Kill ALL creatures
        for (uint i = 0; i < ids.length; i++) {
            arena.killCreature(arenaId, ids[i]);
        }

        arena.setArenaState(arenaId, EvoPolkaArena.ArenaState.FINISHED);
        arena.distributeRewards(arenaId);

        uint256 totalPot = stake * 2;
        uint256 protocolFee = (totalPot * 200) / 10000;
        uint256 distributablePot = totalPot - protocolFee;

        uint256 expectedRefund = distributablePot / 2;

        uint256 p1Actual = arena.pendingRewards(arenaId, player1);
        uint256 p2Actual = arena.pendingRewards(arenaId, player2);

        assertEq(
            p1Actual,
            expectedRefund,
            "Player 1 should get half of distributable pot back"
        );
        assertEq(
            p2Actual,
            expectedRefund,
            "Player 2 should get half of distributable pot back"
        );
    }

    function test_Rewards_CannotDistributeTwice() public {
        arena.setArenaState(arenaId, EvoPolkaArena.ArenaState.FINISHED);

        arena.distributeRewards(arenaId);

        vm.expectRevert("Rewards already distributed");
        arena.distributeRewards(arenaId);
    }
}
