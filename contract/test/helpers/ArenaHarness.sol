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

    /// @notice Force-set a food tile for testing
    function setFoodTile(
        uint256 arenaId,
        uint8 x,
        uint8 y,
        bool hasFood
    ) external {
        uint256 key = uint256(x) * arenas[arenaId].gridSize + uint256(y);
        foodTiles[arenaId][key] = hasFood;
    }

    /// @notice Directly call processFeeding for isolated testing
    function testProcessFeeding(
        uint256 arenaId,
        uint256 startIndex
    ) external returns (uint256) {
        return
            EvolutionEngine.processFeeding(
                arenaCreatures[arenaId],
                arenaCreatureIds[arenaId],
                foodTiles[arenaId],
                arenas[arenaId].gridSize,
                startIndex
            );
    }

    /// @notice Directly call processBreeding for isolated testing
    function testProcessBreeding(
        uint256 arenaId,
        uint256 startIndex
    ) external returns (uint256, uint256) {
        return
            EvolutionEngine.processBreeding(
                arenaCreatures[arenaId],
                arenaCreatureIds[arenaId],
                startIndex,
                arenas[arenaId].mutationRate,
                arenas[arenaId].gridSize,
                nextCreatureId
            );
    }

    /// @notice Expose internal spawn logic to manually inflate population
    function spawnRandomCreature(uint256 arenaId, address owner) external {
        _spawnRandomCreature(arenaId, owner);
    }
}
