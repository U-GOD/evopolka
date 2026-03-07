// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {Test} from "forge-std/Test.sol";
import {EvoPolkaArena} from "../src/EvoPolkaArena.sol";
import {CreatureLib} from "../src/libraries/CreatureLib.sol";
import {ArenaHarness} from "./helpers/ArenaHarness.sol";

contract IntegrationTest is Test {
    ArenaHarness public arena;

    address player1 = address(0x1);
    address player2 = address(0x2);
    uint256 arenaId;

    function setUp() public {
        arena = new ArenaHarness();
        vm.deal(player1, 100 ether);
        vm.deal(player2, 100 ether);

        arenaId = arena.createArena({
            stakePerPlayer: 1 ether,
            maxRounds: 3,
            gridSize: 20,
            creaturesPerPlayer: 3,
            mutationRate: 500,
            roundInterval: 1
        });

        vm.prank(player1);
        arena.joinArena{value: 1 ether}(arenaId);

        vm.prank(player2);
        arena.joinArena{value: 1 ether}(arenaId);

        vm.prank(player1);
        arena.startArena(arenaId);
    }

    function test_Integration_RoundCounterIncrements() public {
        (
            ,
            EvoPolkaArena.ArenaState stateBefore,
            ,
            ,
            uint256 roundBefore,
            ,
            ,
            ,
            ,
            ,

        ) = arena.arenas(arenaId);
        assertEq(uint(stateBefore), uint(EvoPolkaArena.ArenaState.ACTIVE));
        assertEq(roundBefore, 0);

        vm.roll(block.number + 2);
        arena.runEvolutionRound(arenaId);

        (, , , , uint256 roundAfter, , , , , , ) = arena.arenas(arenaId);
        assertEq(roundAfter, 1, "Round number should increment to 1");
    }

    function test_Integration_ThreeRoundsFinishesArena() public {
        // maxRounds = 3, so after 3 rounds the arena should be FINISHED
        for (uint i = 0; i < 3; i++) {
            (, , , , , , , , , uint256 lastBlock, uint256 interval) = arena
                .arenas(arenaId);
            vm.roll(lastBlock + interval + 1);

            (, EvoPolkaArena.ArenaState st, , , , , , , , , ) = arena.arenas(
                arenaId
            );
            if (uint(st) == uint(EvoPolkaArena.ArenaState.FINISHED)) break;

            arena.runEvolutionRound(arenaId);
        }

        (
            ,
            EvoPolkaArena.ArenaState finalState,
            ,
            ,
            uint256 finalRound,
            ,
            ,
            ,
            ,
            ,

        ) = arena.arenas(arenaId);
        assertEq(
            uint(finalState),
            uint(EvoPolkaArena.ArenaState.FINISHED),
            "Arena should be FINISHED after max rounds"
        );
        assertEq(finalRound, 3, "Round number should be 3");
    }

    function test_Integration_PopulationChangesAcrossRounds() public {
        uint256[] memory idsBefore = arena.getCreatureIds(arenaId);
        uint256 initialPop = idsBefore.length;
        assertEq(initialPop, 6, "Should start with 6 creatures (3 per player)");

        vm.roll(block.number + 2);
        arena.runEvolutionRound(arenaId);

        // Population may increase (breeding) or stay same, but IDs array only grows
        uint256[] memory idsAfter = arena.getCreatureIds(arenaId);
        assertTrue(
            idsAfter.length >= initialPop,
            "Population array should not shrink"
        );
    }

    function test_Integration_CreaturesCanDieAcrossRounds() public {
        uint256[] memory ids = arena.getCreatureIds(arenaId);

        // Weaken one creature so it dies during culling
        arena.setCreatureState(arenaId, ids[0], 5, 5, 10, 10, 10, 10, 10, 1, 1);

        vm.roll(block.number + 2);
        arena.runEvolutionRound(arenaId);

        CreatureLib.Creature memory weakCreature = arena.getCreature(
            arenaId,
            ids[0]
        );
        // The creature with 1 energy/1 hp should be dead after movement drains energy
        // or culling removes it as the weakest
        assertFalse(
            weakCreature.alive,
            "Weakened creature should die during the round"
        );
    }

    function test_Integration_ArenaFinishesWhenOnePlayerRemains() public {
        uint256[] memory ids = arena.getCreatureIds(arenaId);

        // Kill all of player 2's creatures (ids[3], ids[4], ids[5])
        arena.setCreatureState(
            arenaId,
            ids[3],
            5,
            5,
            10,
            10,
            10,
            10,
            10,
            0,
            100
        );
        arena.setCreatureState(
            arenaId,
            ids[4],
            5,
            5,
            10,
            10,
            10,
            10,
            10,
            0,
            100
        );
        arena.setCreatureState(
            arenaId,
            ids[5],
            5,
            5,
            10,
            10,
            10,
            10,
            10,
            0,
            100
        );

        // Boost player 1's creatures so they survive culling
        arena.setCreatureState(
            arenaId,
            ids[0],
            5,
            5,
            200,
            200,
            200,
            200,
            200,
            300,
            100
        );
        arena.setCreatureState(
            arenaId,
            ids[1],
            5,
            5,
            200,
            200,
            200,
            200,
            200,
            300,
            100
        );
        arena.setCreatureState(
            arenaId,
            ids[2],
            5,
            5,
            200,
            200,
            200,
            200,
            200,
            300,
            100
        );

        vm.roll(block.number + 2);
        arena.runEvolutionRound(arenaId);

        (, EvoPolkaArena.ArenaState state, , , , , , , , , ) = arena.arenas(
            arenaId
        );
        assertEq(
            uint(state),
            uint(EvoPolkaArena.ArenaState.FINISHED),
            "Arena should finish when only one owner remains"
        );
    }

    function test_Integration_CannotRunRoundTooSoon() public {
        // roundInterval is 1, so we need at least 1 block gap
        vm.expectRevert("Too soon to execute");
        arena.runEvolutionRound(arenaId);
    }

    function test_Integration_CannotRunRoundOnFinishedArena() public {
        // Run 3 rounds to finish the arena
        for (uint i = 0; i < 3; i++) {
            (, , , , , , , , , uint256 lastBlock, uint256 interval) = arena
                .arenas(arenaId);
            vm.roll(lastBlock + interval + 1);
            (, EvoPolkaArena.ArenaState st, , , , , , , , , ) = arena.arenas(
                arenaId
            );
            if (uint(st) == uint(EvoPolkaArena.ArenaState.FINISHED)) break;
            arena.runEvolutionRound(arenaId);
        }

        vm.roll(block.number + 2);
        vm.expectRevert("Not in ACTIVE state");
        arena.runEvolutionRound(arenaId);
    }
}
