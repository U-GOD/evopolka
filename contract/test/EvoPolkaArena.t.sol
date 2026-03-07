// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {Test} from "forge-std/Test.sol";
import {EvoPolkaArena} from "../src/EvoPolkaArena.sol";

contract EvoPolkaArenaTest is Test {
    EvoPolkaArena public arena;

    // Test users
    address player1 = address(0x1);
    address player2 = address(0x2);

    function setUp() public {
        arena = new EvoPolkaArena();
        vm.deal(player1, 100 ether);
        vm.deal(player2, 100 ether);
    }

    function test_CreateArena() public {
        uint256 arenaId = arena.createArena({
            stakePerPlayer: 1 ether,
            maxRounds: 100,
            gridSize: 50,
            creaturesPerPlayer: 3,
            mutationRate: 500, // 5%
            roundInterval: 10
        });

        assertEq(arenaId, 0);

        (
            uint256 id,
            EvoPolkaArena.ArenaState state,
            uint256 stake,
            uint256 pot,
            uint256 rounds,
            uint256 maxRounds,
            uint256 gridSize,
            uint256 creaturesPerPlayer,
            uint256 mutation,
            uint256 lastRound,
            uint256 interval
        ) = arena.arenas(arenaId);

        assertEq(id, 0);
        assertEq(uint(state), uint(EvoPolkaArena.ArenaState.LOBBY));
        assertEq(stake, 1 ether);
        assertEq(pot, 0);
        assertEq(rounds, 0);
        assertEq(maxRounds, 100);
        assertEq(gridSize, 50);
        assertEq(creaturesPerPlayer, 3);
        assertEq(mutation, 500);
        assertEq(interval, 10);
    }

    function test_JoinArena() public {
        uint256 arenaId = arena.createArena(1 ether, 100, 50, 3, 500, 10);

        vm.prank(player1);
        arena.joinArena{value: 1 ether}(arenaId);

        (, , , uint256 pot, , , , , , , ) = arena.arenas(arenaId);
        assertEq(pot, 1 ether);
        assertEq(arena.arenaPlayerCount(arenaId), 1);
        assertTrue(arena.hasJoined(arenaId, player1));

        // Wait... did they get 3 creatures?
        // nextCreatureId should be 3 now.
        assertEq(arena.nextCreatureId(), 3);

        // Assert a creature actually spawned and exists
        (
            uint256 id,
            address owner,
            uint8 speed,
            , // str
            , // intl
            , // agg
            , // repro
            , // def
            uint16 nrg,
            uint16 hp,
            , // x
            , // y
            uint32 gen,
            bool alive,

        ) = arena.arenaCreatures(arenaId, 0); // bytes32 genome

        assertEq(owner, player1);
        assertEq(hp, 100);
        assertEq(nrg, 100);
        assertEq(gen, 1);
        assertTrue(alive);
        assertTrue(speed >= 10); // Normalization check
    }

    function test_JoinArena_RevertsWhenNotEnoughStake() public {
        uint256 arenaId = arena.createArena(1 ether, 100, 50, 3, 500, 10);

        vm.prank(player1);
        vm.expectRevert("Incorrect stake amount");
        arena.joinArena{value: 0.5 ether}(arenaId);
    }

    function test_StartArena() public {
        uint256 arenaId = arena.createArena(1 ether, 100, 50, 3, 500, 10);

        vm.prank(player1);
        arena.joinArena{value: 1 ether}(arenaId);

        vm.prank(player2);
        arena.joinArena{value: 1 ether}(arenaId);

        // Player 1 should be authorized to start because they were first.
        vm.prank(player1);
        arena.startArena(arenaId);

        (, EvoPolkaArena.ArenaState state, , , , , , , , , ) = arena.arenas(
            arenaId
        );
        assertEq(uint(state), uint(EvoPolkaArena.ArenaState.ACTIVE));
    }

    function test_StartArena_RevertsWhenOnlyOnePlayer() public {
        uint256 arenaId = arena.createArena(1 ether, 100, 50, 3, 500, 10);

        vm.prank(player1);
        arena.joinArena{value: 1 ether}(arenaId);

        vm.expectRevert("Need at least 2 players");
        arena.startArena(arenaId);
    }
}
