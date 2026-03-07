// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {Test} from "forge-std/Test.sol";
import {EvoPolkaArena} from "../src/EvoPolkaArena.sol";
import {CreatureLib} from "../src/libraries/CreatureLib.sol";
import {EvolutionEngine} from "../src/libraries/EvolutionEngine.sol";
import {ArenaHarness} from "./helpers/ArenaHarness.sol";

contract CombatTest is Test {
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

    function test_Combat_AttackerWins() public {
        uint256[] memory ids = arena.getCreatureIds(arenaId);

        // Strong attacker on same tile as weak defender
        arena.setCreatureState(
            arenaId,
            ids[0],
            5,
            5,
            50,
            200,
            50,
            200,
            50,
            100,
            100
        );
        arena.setCreatureState(
            arenaId,
            ids[1],
            5,
            5,
            50,
            10,
            50,
            10,
            10,
            100,
            10
        );

        arena.testProcessCombat(arenaId, 0);

        CreatureLib.Creature memory defender = arena.getCreature(
            arenaId,
            ids[1]
        );
        assertFalse(defender.alive, "Weak defender should be dead");
        assertEq(defender.hp, 0);
    }

    function test_Combat_DefenderSurvives() public {
        uint256[] memory ids = arena.getCreatureIds(arenaId);

        // Weak attacker vs heavily armored defender
        arena.setCreatureState(
            arenaId,
            ids[0],
            5,
            5,
            50,
            20,
            50,
            200,
            10,
            100,
            100
        );
        arena.setCreatureState(
            arenaId,
            ids[1],
            5,
            5,
            50,
            10,
            50,
            10,
            250,
            100,
            200
        );

        arena.testProcessCombat(arenaId, 0);

        CreatureLib.Creature memory defender = arena.getCreature(
            arenaId,
            ids[1]
        );
        assertTrue(defender.alive, "High-defense defender should survive");
        assertTrue(defender.hp > 0, "Defender HP should remain positive");
    }

    function test_Combat_EnergyAbsorption() public {
        uint256[] memory ids = arena.getCreatureIds(arenaId);

        // Attacker kills defender (100 energy), should absorb 50
        arena.setCreatureState(
            arenaId,
            ids[0],
            5,
            5,
            50,
            250,
            50,
            200,
            50,
            80,
            100
        );
        arena.setCreatureState(
            arenaId,
            ids[1],
            5,
            5,
            50,
            10,
            50,
            10,
            10,
            100,
            5
        );

        arena.testProcessCombat(arenaId, 0);

        CreatureLib.Creature memory attacker = arena.getCreature(
            arenaId,
            ids[0]
        );
        assertEq(
            attacker.energy,
            130,
            "Attacker should gain 50% of defender's 100 energy"
        );
    }

    function test_Combat_DeadCreatureRemoved() public {
        uint256[] memory ids = arena.getCreatureIds(arenaId);

        arena.setCreatureState(
            arenaId,
            ids[0],
            5,
            5,
            50,
            200,
            50,
            200,
            50,
            100,
            100
        );
        arena.setCreatureState(
            arenaId,
            ids[1],
            5,
            5,
            50,
            10,
            50,
            10,
            10,
            100,
            1
        );

        arena.testProcessCombat(arenaId, 0);

        CreatureLib.Creature memory dead = arena.getCreature(arenaId, ids[1]);
        assertFalse(dead.alive, "Dead creature alive flag should be false");
        assertEq(dead.hp, 0, "Dead creature HP should be 0");
    }
}
