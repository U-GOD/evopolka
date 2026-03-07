// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {Test} from "forge-std/Test.sol";
import {EvoPolkaArena} from "../src/EvoPolkaArena.sol";
import {CreatureLib} from "../src/libraries/CreatureLib.sol";
import {ArenaHarness} from "./helpers/ArenaHarness.sol";

contract BreedingTest is Test {
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
            mutationRate: 500, // 5% mutation
            roundInterval: 1
        });

        vm.prank(player1);
        arena.joinArena{value: 1 ether}(arenaId);

        vm.prank(player2);
        arena.joinArena{value: 1 ether}(arenaId);

        vm.prank(player1);
        arena.startArena(arenaId);
    }

    function test_Breeding_EligibleParents() public {
        uint256[] memory ids = arena.getCreatureIds(arenaId);
        assertEq(ids.length, 2, "Should have 2 creatures initially");

        // Give them both > 150 energy and adjacent coordinates
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
            200,
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
            200,
            100
        );

        (uint256 pIdx, uint256 newNextId) = arena.testProcessBreeding(
            arenaId,
            0
        );

        uint256[] memory newIds = arena.getCreatureIds(arenaId);
        assertEq(newIds.length, 3, "New creature should be born");
    }

    function test_Breeding_NotEligibleInsufficientEnergy() public {
        uint256[] memory ids = arena.getCreatureIds(arenaId);
        // Distance is 1, energy is too low
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
            149,
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
            150,
            100
        );

        arena.testProcessBreeding(arenaId, 0);

        uint256[] memory newIds = arena.getCreatureIds(arenaId);
        assertEq(newIds.length, 2, "No creature should be born");
    }

    function test_Breeding_NotEligibleTooFar() public {
        uint256[] memory ids = arena.getCreatureIds(arenaId);
        // Distance is 3, energy is high enough
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
            200,
            100
        );
        arena.setCreatureState(
            arenaId,
            ids[1],
            10,
            13,
            50,
            50,
            50,
            50,
            50,
            200,
            100
        );

        arena.testProcessBreeding(arenaId, 0);

        uint256[] memory newIds = arena.getCreatureIds(arenaId);
        assertEq(
            newIds.length,
            2,
            "No creature should be born because they are too far"
        );
    }

    function test_Breeding_ParentsLoseEnergy() public {
        uint256[] memory ids = arena.getCreatureIds(arenaId);
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
            200,
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
            160,
            100
        );

        arena.testProcessBreeding(arenaId, 0);

        CreatureLib.Creature memory pA = arena.getCreature(arenaId, ids[0]);
        CreatureLib.Creature memory pB = arena.getCreature(arenaId, ids[1]);

        assertEq(pA.energy, 150, "Parent A should have spent 50 energy");
        assertEq(pB.energy, 110, "Parent B should have spent 50 energy");
    }

    function test_Breeding_ChildAttributes() public {
        uint256[] memory ids = arena.getCreatureIds(arenaId);
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
            200,
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
            200,
            100
        );

        arena.testProcessBreeding(arenaId, 0);

        uint256[] memory newIds = arena.getCreatureIds(arenaId);
        uint256 childId = newIds[2];
        CreatureLib.Creature memory child = arena.getCreature(arenaId, childId);

        assertEq(child.energy, 80, "Child energy should be 80");
        assertEq(child.hp, 80, "Child HP should be 80");
        // Child generation = max(1, 1) + 1 = 2
        assertEq(child.generation, 2, "Child generation should be 2");

        uint256 distA = child.x > 10 ? child.x - 10 : 10 - child.x;
        uint256 distB = child.y > 11 ? child.y - 11 : 11 - child.y; // distance to either parent
        assertTrue(distA <= 2 && distB <= 2, "Child should spawn near parents");
    }

    function test_Breeding_CreatureCapEnforced() public {
        // Grid size 10 means max population 100/2 = 50.
        uint256 smallArenaId = arena.createArena(1 ether, 10, 10, 2, 500, 1);

        vm.prank(player1);
        arena.joinArena{value: 1 ether}(smallArenaId); // 2 creatures

        vm.prank(player2);
        arena.joinArena{value: 1 ether}(smallArenaId); // 2 creatures -> total 4.

        // Force IDs to 50
        for (uint i = 0; i < 46; i++) {
            arena.spawnRandomCreature(smallArenaId, address(this));
        }

        uint256[] memory ids = arena.getCreatureIds(smallArenaId);
        assertEq(ids.length, 50, "Should have exactly 50 creatures at cap");

        // Take two random creatures and try to breed them
        arena.setCreatureState(
            smallArenaId,
            ids[0],
            10,
            10,
            50,
            50,
            50,
            50,
            50,
            200,
            100
        );
        arena.setCreatureState(
            smallArenaId,
            ids[1],
            10,
            11,
            50,
            50,
            50,
            50,
            50,
            200,
            100
        );

        arena.testProcessBreeding(smallArenaId, 0);

        uint256[] memory newIds = arena.getCreatureIds(smallArenaId);
        assertEq(newIds.length, 50, "Should not exceed max population cap");
    }
}
