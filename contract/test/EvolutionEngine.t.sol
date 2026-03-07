// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {Test} from "forge-std/Test.sol";
import {EvoPolkaArena} from "../src/EvoPolkaArena.sol";
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

    function test_RunEvolutionRound_Orchestration() public {
        // Must wait for round interval
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
}
