// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {EvoPolkaArena} from "../../src/EvoPolkaArena.sol";
import {CreatureLib} from "../../src/libraries/CreatureLib.sol";
import {EvolutionEngine} from "../../src/libraries/EvolutionEngine.sol";

/// @notice Harness exposing internal storage for deterministic combat/movement tests
contract ArenaHarness is EvoPolkaArena {
    /// @notice Force-set a creature's position, stats, and energy for testing
    function setCreatureState(
        uint256 arenaId,
        uint256 creatureId,
        uint8 x,
        uint8 y,
        uint8 speed,
        uint8 strength,
        uint8 intelligence,
        uint8 aggression,
        uint8 defense,
        uint16 energy,
        uint16 hp
    ) external {
        CreatureLib.Creature storage c = arenaCreatures[arenaId][creatureId];
        c.x = x;
        c.y = y;
        c.speed = speed;
        c.strength = strength;
        c.intelligence = intelligence;
        c.aggression = aggression;
        c.defense = defense;
        c.energy = energy;
        c.hp = hp;
    }

    /// @notice Directly call processMovement for isolated testing
    function testProcessMovement(
        uint256 arenaId,
        uint256 startIndex,
        uint256 roundNumber
    ) external returns (uint256) {
        return
            EvolutionEngine.processMovement(
                arenaCreatures[arenaId],
                arenaCreatureIds[arenaId],
                arenas[arenaId].gridSize,
                startIndex,
                roundNumber
            );
    }

    /// @notice Directly call processCombat for isolated testing
    function testProcessCombat(
        uint256 arenaId,
        uint256 startIndex
    ) external returns (uint256) {
        return
            EvolutionEngine.processCombat(
                arenaCreatures[arenaId],
                arenaCreatureIds[arenaId],
                startIndex
            );
    }
}
