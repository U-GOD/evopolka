// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {Test} from "forge-std/Test.sol";
import {EvoPolkaArena} from "../src/EvoPolkaArena.sol";
import {CreatureLib} from "../src/libraries/CreatureLib.sol";
import {ArenaHarness} from "./helpers/ArenaHarness.sol";

contract CullingTest is Test {
    ArenaHarness public arena;

    address player1 = address(0x1);
    address player2 = address(0x2);
    address player3 = address(0x3);
    uint256 arenaId;

    function setUp() public {
        arena = new ArenaHarness();
        vm.deal(player1, 100 ether);
        vm.deal(player2, 100 ether);
        vm.deal(player3, 100 ether);

        arenaId = arena.createArena({
            stakePerPlayer: 1 ether,
            maxRounds: 10,
            gridSize: 50,
            creaturesPerPlayer: 1,
            mutationRate: 500, // 5% mutation
            roundInterval: 1
        });
    }

    function test_Culling_ZeroEnergyDies() public {
        vm.prank(player1);
        arena.joinArena{value: 1 ether}(arenaId);

        vm.prank(player2);
        arena.joinArena{value: 1 ether}(arenaId);

        vm.prank(player1);
        arena.startArena(arenaId);

        uint256[] memory ids = arena.getCreatureIds(arenaId);

        // P1 creature has 0 energy, P2 creature has 100 energy
        arena.setCreatureState(
            arenaId,
            ids[0],
            10,
            10,
            50,
            50,
            50,
            50,
            50,
            0,
            100
        );
        arena.setCreatureState(
            arenaId,
            ids[1],
            10,
            11,
            50,
            50,
            50,
            50,
            50,
            100,
            100
        );

        arena.testProcessCulling(arenaId, 0);

        CreatureLib.Creature memory c1 = arena.getCreature(arenaId, ids[0]);
        CreatureLib.Creature memory c2 = arena.getCreature(arenaId, ids[1]);

        assertFalse(c1.alive, "0 energy creature should be dead");
        assertTrue(c2.alive, "100 energy creature should be alive");
    }

    function test_Culling_Bottom20Percent() public {
        uint256 bigArenaId = arena.createArena(1 ether, 10, 50, 5, 500, 1);

        vm.prank(player1);
        arena.joinArena{value: 1 ether}(bigArenaId); // 5 creatures

        vm.prank(player2);
        arena.joinArena{value: 1 ether}(bigArenaId); // 5 creatures -> total 10

        vm.prank(player1);
        arena.startArena(bigArenaId);

        uint256[] memory ids = arena.getCreatureIds(bigArenaId);
        assertEq(ids.length, 10, "Should have 10 creatures");

        // Set different stats to vary fitness. Fitness = (speed+str+int+def) * energy * gen / 1000
        for (uint i = 0; i < 10; i++) {
            // Give them escalating energy so fitness scales with their index.
            // Index 0 will have lowest fitness, index 9 highest.
            arena.setCreatureState(
                bigArenaId,
                ids[i],
                0,
                0,
                50,
                50,
                50,
                50,
                50,
                uint16(100 + i * 10),
                100
            );
        }

        // Culling should kill 2 creatures (20% of 10)
        // Since fitness is lowest for index 0 and 1, they should die.
        arena.testProcessCulling(bigArenaId, 0);

        uint aliveCount = 0;
        for (uint i = 0; i < 10; i++) {
            CreatureLib.Creature memory c = arena.getCreature(
                bigArenaId,
                ids[i]
            );
            if (c.alive) {
                aliveCount++;
            }
        }

        assertEq(
            aliveCount,
            8,
            "Should have 8 alive creatures left after 20% cull"
        );

        CreatureLib.Creature memory c0 = arena.getCreature(bigArenaId, ids[0]);
        CreatureLib.Creature memory c1 = arena.getCreature(bigArenaId, ids[1]);
        CreatureLib.Creature memory c2 = arena.getCreature(bigArenaId, ids[2]);

        assertFalse(c0.alive, "Lowest fitness should die");
        assertFalse(c1.alive, "Second lowest fitness should die");
        assertTrue(c2.alive, "Third lowest should survive");
    }

    function test_Culling_ArenaFinishesWhenOneOwner() public {
        vm.prank(player1);
        arena.joinArena{value: 1 ether}(arenaId);

        vm.prank(player2);
        arena.joinArena{value: 1 ether}(arenaId);

        vm.prank(player3);
        arena.joinArena{value: 1 ether}(arenaId);

        vm.prank(player1);
        arena.startArena(arenaId);

        uint256[] memory ids = arena.getCreatureIds(arenaId);
        // Player 1's creature has 0 energy, Player 2's creature has 0 energy, Player 3's creature lives
        arena.setCreatureState(
            arenaId,
            ids[0],
            10,
            10,
            50,
            50,
            50,
            50,
            50,
            0,
            100
        );
        arena.setCreatureState(
            arenaId,
            ids[1],
            10,
            10,
            50,
            50,
            50,
            50,
            50,
            0,
            100
        );
        arena.setCreatureState(
            arenaId,
            ids[2],
            10,
            10,
            50,
            50,
            50,
            50,
            50,
            100,
            100
        );

        arena.testProcessCulling(arenaId, 0);

        // Finalize round checks the survival count
        arena.testFinalizeRound(arenaId);

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

        // Should be finished because only Player 3 remains.
        assertEq(
            uint(state),
            uint(EvoPolkaArena.ArenaState.FINISHED),
            "Arena should be finished"
        );
    }
}
