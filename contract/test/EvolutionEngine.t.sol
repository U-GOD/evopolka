// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {Test} from "forge-std/Test.sol";
import {EvoPolkaArena} from "../src/EvoPolkaArena.sol";
import {CreatureLib} from "../src/libraries/CreatureLib.sol";
import {EvolutionEngine} from "../src/libraries/EvolutionEngine.sol";

contract EvolutionEngineTest is Test {
    EvoPolkaArena public arena;

    address player1 = address(0x1);
    address player2 = address(0x2);
    uint256 arenaId;

    function setUp() public {
        arena = new EvoPolkaArena();
        vm.deal(player1, 100 ether);
        vm.deal(player2, 100 ether);

        arenaId = arena.createArena({
            stakePerPlayer: 1 ether,
            maxRounds: 5,
            gridSize: 50,
            creaturesPerPlayer: 2,
            mutationRate: 500,
            roundInterval: 10
        });

        vm.prank(player1);
        arena.joinArena{value: 1 ether}(arenaId);

        vm.prank(player2);
        arena.joinArena{value: 1 ether}(arenaId);

        vm.prank(player1);
        arena.startArena(arenaId);
    }

    // ---- Round Orchestration Tests ----

    function test_RunEvolutionRound_Orchestration() public {
        vm.roll(block.number + 10);

        (
            ,
            EvoPolkaArena.ArenaState state,
            ,
            ,
            uint256 roundNumber,
            ,
            ,
            ,
            ,
            ,

        ) = arena.arenas(arenaId);
        assertEq(uint(state), uint(EvoPolkaArena.ArenaState.ACTIVE));
        assertEq(roundNumber, 0);

        vm.prank(player1);
        arena.runEvolutionRound(arenaId);

        (
            ,
            EvoPolkaArena.ArenaState newState,
            ,
            ,
            uint256 newRoundNumber,
            ,
            ,
            ,
            ,
            ,

        ) = arena.arenas(arenaId);

        assertEq(uint(newState), uint(EvoPolkaArena.ArenaState.ACTIVE));
        assertEq(newRoundNumber, 1);
        assertEq(arena.currentPhase(arenaId), EvolutionEngine.PHASE_NONE);
    }

    function test_RunEvolutionRound_TooSoon() public {
        vm.roll(block.number + 5);

        vm.expectRevert("Too soon to execute");
        vm.prank(player1);
        arena.runEvolutionRound(arenaId);
    }

    function test_RunEvolutionRound_TransitionsToFinished() public {
        for (uint i = 0; i < 5; i++) {
            vm.roll(block.number + 10 * (i + 1));
            arena.runEvolutionRound(arenaId);
        }

        (
            ,
            EvoPolkaArena.ArenaState newState,
            ,
            ,
            uint256 newRoundNumber,
            ,
            ,
            ,
            ,
            ,

        ) = arena.arenas(arenaId);
        assertEq(newRoundNumber, 5);
        assertEq(uint(newState), uint(EvoPolkaArena.ArenaState.FINISHED));
    }

    function test_ContinueRound_RevertsNotInEvolving() public {
        vm.expectRevert("Not in EVOLVING state");
        arena.continueRound(arenaId);
    }

    // ---- Movement Tests ----

    function test_Movement_BasicDirection() public {
        uint256[] memory ids = arena.getCreatureIds(arenaId);
        assertTrue(ids.length == 4);

        CreatureLib.Creature memory before0 = arena.getCreature(
            arenaId,
            ids[0]
        );
        uint8 oldX = before0.x;
        uint8 oldY = before0.y;

        vm.roll(block.number + 10);
        arena.runEvolutionRound(arenaId);

        CreatureLib.Creature memory after0 = arena.getCreature(arenaId, ids[0]);
        bool moved = (after0.x != oldX || after0.y != oldY);
        assertTrue(moved, "Creature should have moved");
    }

    function test_Movement_ClampsToGrid() public {
        uint256[] memory ids = arena.getCreatureIds(arenaId);

        vm.roll(block.number + 10);
        arena.runEvolutionRound(arenaId);

        for (uint256 i = 0; i < ids.length; i++) {
            CreatureLib.Creature memory c = arena.getCreature(arenaId, ids[i]);
            assertTrue(c.x < 50, "X out of bounds");
            assertTrue(c.y < 50, "Y out of bounds");
        }
    }

    function test_Movement_EnergyCost() public {
        uint256[] memory ids = arena.getCreatureIds(arenaId);
        CreatureLib.Creature memory before0 = arena.getCreature(
            arenaId,
            ids[0]
        );
        uint16 energyBefore = before0.energy;

        vm.roll(block.number + 10);
        arena.runEvolutionRound(arenaId);

        CreatureLib.Creature memory after0 = arena.getCreature(arenaId, ids[0]);
        assertTrue(
            after0.energy < energyBefore,
            "Energy should decrease after movement"
        );
    }

    function test_Movement_BatchLimit() public {
        EvoPolkaArena bigArena = new EvoPolkaArena();
        uint256 bigId = bigArena.createArena({
            stakePerPlayer: 1 ether,
            maxRounds: 5,
            gridSize: 50,
            creaturesPerPlayer: 10,
            mutationRate: 500,
            roundInterval: 1
        });

        address p1 = address(0x10);
        address p2 = address(0x20);
        address p3 = address(0x30);
        vm.deal(p1, 100 ether);
        vm.deal(p2, 100 ether);
        vm.deal(p3, 100 ether);

        vm.prank(p1);
        bigArena.joinArena{value: 1 ether}(bigId);
        vm.prank(p2);
        bigArena.joinArena{value: 1 ether}(bigId);
        vm.prank(p3);
        bigArena.joinArena{value: 1 ether}(bigId);

        uint256[] memory ids = bigArena.getCreatureIds(bigId);
        assertEq(ids.length, 30);

        vm.prank(p1);
        bigArena.startArena(bigId);

        vm.roll(block.number + 1);
        bigArena.runEvolutionRound(bigId);

        (, EvoPolkaArena.ArenaState state, , , , , , , , , ) = bigArena.arenas(
            bigId
        );
        assertTrue(
            uint(state) == uint(EvoPolkaArena.ArenaState.ACTIVE) ||
                uint(state) == uint(EvoPolkaArena.ArenaState.EVOLVING),
            "Should finish or be in progress"
        );
    }
}
