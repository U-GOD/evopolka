// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {Test} from "forge-std/Test.sol";
import {EvoPolkaArena} from "../src/EvoPolkaArena.sol";
import {CreatureLib} from "../src/libraries/CreatureLib.sol";
import {ArenaHarness} from "./helpers/ArenaHarness.sol";

contract FeedingTest is Test {
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
            maxRounds: 10,
            gridSize: 50,
            creaturesPerPlayer: 1,
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

    function test_Feeding_CreatureGainsEnergy() public {
        uint256[] memory ids = arena.getCreatureIds(arenaId);

        // Put creature on (5,5) with 50 intelligence and 100 energy
        arena.setCreatureState(
            arenaId,
            ids[0],
            5,
            5,
            50,
            50,
            50,
            50,
            50,
            100,
            100
        );

        // Spawn food on (5,5)
        arena.setFoodTile(arenaId, 5, 5, true);

        // Run feeding phase
        arena.testProcessFeeding(arenaId, 0);

        CreatureLib.Creature memory fedCreature = arena.getCreature(
            arenaId,
            ids[0]
        );
        // intel 50 / 5 = 10 gain
        assertEq(fedCreature.energy, 110, "Creature should gain 10 energy");
    }

    function test_Feeding_FoodConsumed() public {
        uint256[] memory ids = arena.getCreatureIds(arenaId);

        arena.setCreatureState(
            arenaId,
            ids[0],
            5,
            5,
            50,
            50,
            50,
            50,
            50,
            100,
            100
        );
        arena.setFoodTile(arenaId, 5, 5, true);

        arena.testProcessFeeding(arenaId, 0);

        // Tile (5,5) key = 5 * 50 + 5 = 255
        bool hasFood = arena.foodTiles(arenaId, 255);
        assertFalse(hasFood, "Food tile should be consumed");
    }

    function test_Feeding_FoodRespawns() public {
        // At start, arena size is 50x50 = 2500. 2500 / 10 = 250 spawned.
        // Wait, during setup startArena is called which spawns 250.
        // But let's check manually.
        uint256 countInitial = 0;
        for (uint256 i = 0; i < 2500; i++) {
            if (arena.foodTiles(arenaId, i)) {
                countInitial++;
            }
        }
        assertTrue(countInitial > 0, "Initial food spawned");

        vm.roll(block.number + 1);

        // End round spawns (gridSize*gridSize)/20 = 2500 / 20 = 125 more food.
        arena.runEvolutionRound(arenaId);

        uint256 countAfter = 0;
        for (uint256 i = 0; i < 2500; i++) {
            if (arena.foodTiles(arenaId, i)) {
                countAfter++;
            }
        }
        assertTrue(
            countAfter > countInitial,
            "New food should respawn after round"
        );
    }

    function test_Feeding_EnergyCap() public {
        uint256[] memory ids = arena.getCreatureIds(arenaId);

        // Put creature on (5,5) with 50 intelligence and 495 energy
        arena.setCreatureState(
            arenaId,
            ids[0],
            5,
            5,
            50,
            50,
            50,
            50,
            50,
            495,
            100
        );

        arena.setFoodTile(arenaId, 5, 5, true);

        arena.testProcessFeeding(arenaId, 0);

        CreatureLib.Creature memory fedCreature = arena.getCreature(
            arenaId,
            ids[0]
        );
        // intel 50 / 5 = 10 gain, 495 + 10 = 505 -> capped at 500
        assertEq(fedCreature.energy, 500, "Energy should be capped at 500");
    }
}
