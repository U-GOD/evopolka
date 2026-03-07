// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {CreatureLib} from "./CreatureLib.sol";

/// @title EvolutionEngine
/// @notice Library implementing the 5 evolution phases with gas-safe batching
library EvolutionEngine {
    uint8 constant PHASE_NONE = 0;
    uint8 constant PHASE_MOVEMENT = 1;
    uint8 constant PHASE_COMBAT = 2;
    uint8 constant PHASE_FEEDING = 3;
    uint8 constant PHASE_BREEDING = 4;
    uint8 constant PHASE_CULLING = 5;

    uint256 constant MAX_BATCH = 20;
    uint256 constant GAS_RESERVE = 50_000;

    /// @notice Process the movement phase for a batch of creatures
    /// @return 0 if phase complete, otherwise the next startIndex to resume from
    function processMovement(
        mapping(uint256 => CreatureLib.Creature) storage creatures,
        uint256[] storage creatureIds,
        uint256 gridSize,
        uint256 startIndex,
        uint256 roundNumber
    ) internal returns (uint256) {
        uint256 len = creatureIds.length;
        uint256 processed;

        for (uint256 i = startIndex; i < len; i++) {
            if (processed >= MAX_BATCH || gasleft() < GAS_RESERVE) {
                return i;
            }

            CreatureLib.Creature storage c = creatures[creatureIds[i]];
            if (!c.alive) continue;

            uint256 tiles = c.speed / 10;
            if (tiles == 0) tiles = 1;

            uint16 moveCost = uint16(tiles);
            if (c.energy <= moveCost) {
                c.energy = 0;
                continue;
            }
            c.energy -= moveCost;

            bytes32 entropy = keccak256(
                abi.encode(block.prevrandao, roundNumber, c.id)
            );
            uint256 direction = uint256(entropy) % 4;

            uint8 posX = c.x;
            uint8 posY = c.y;
            uint8 maxCoord = uint8(gridSize - 1);

            unchecked {
                if (direction == 0 && posY + uint8(tiles) <= maxCoord) {
                    posY += uint8(tiles);
                } else if (direction == 0) {
                    posY = maxCoord;
                } else if (direction == 1 && posY >= uint8(tiles)) {
                    posY -= uint8(tiles);
                } else if (direction == 1) {
                    posY = 0;
                } else if (direction == 2 && posX + uint8(tiles) <= maxCoord) {
                    posX += uint8(tiles);
                } else if (direction == 2) {
                    posX = maxCoord;
                } else if (direction == 3 && posX >= uint8(tiles)) {
                    posX -= uint8(tiles);
                } else {
                    posX = 0;
                }
            }

            c.x = posX;
            c.y = posY;

            processed++;
        }

        return 0;
    }

    event CombatOccurred(
        uint256 indexed arenaId,
        uint256 attacker,
        uint256 defender,
        bool attackerWon
    );
    event CreatureDied(uint256 indexed arenaId, uint256 creatureId);

    /// @notice Process the combat phase — creatures sharing a tile fight
    /// @return 0 if phase complete, otherwise the next startIndex to resume from
    function processCombat(
        mapping(uint256 => CreatureLib.Creature) storage creatures,
        uint256[] storage creatureIds,
        uint256 startIndex
    ) internal returns (uint256) {
        uint256 len = creatureIds.length;
        uint256 processed;

        bool[] memory fought = new bool[](len);

        for (uint256 i = startIndex; i < len; i++) {
            if (processed >= MAX_BATCH || gasleft() < GAS_RESERVE) {
                return i;
            }

            CreatureLib.Creature storage a = creatures[creatureIds[i]];
            if (!a.alive || fought[i]) continue;

            for (uint256 j = i + 1; j < len; j++) {
                if (fought[j]) continue;

                CreatureLib.Creature storage b = creatures[creatureIds[j]];
                if (!b.alive) continue;
                if (a.x != b.x || a.y != b.y) continue;

                fought[i] = true;
                fought[j] = true;

                CreatureLib.Creature storage attacker;
                CreatureLib.Creature storage defender;

                if (a.aggression >= b.aggression) {
                    attacker = a;
                    defender = b;
                } else {
                    attacker = b;
                    defender = a;
                }

                uint16 damage = uint16(attacker.strength);
                uint16 defBonus = uint16(defender.defense) / 2;
                damage = damage > defBonus ? damage - defBonus : 1;

                bool killed;
                if (defender.hp <= damage) {
                    defender.hp = 0;
                    defender.alive = false;
                    killed = true;
                    attacker.energy += defender.energy / 2;
                    emit CreatureDied(0, defender.id);
                } else {
                    defender.hp -= damage;
                }

                emit CombatOccurred(0, attacker.id, defender.id, killed);
                break;
            }

            processed++;
        }

        return 0;
    }

    /// @notice Process the feeding phase
    function processFeeding(
        mapping(uint256 => CreatureLib.Creature) storage creatures,
        uint256[] storage creatureIds,
        uint256 startIndex
    ) internal returns (uint256) {
        return 0;
    }

    /// @notice Process the breeding phase
    function processBreeding(
        mapping(uint256 => CreatureLib.Creature) storage creatures,
        uint256[] storage creatureIds,
        uint256 startIndex,
        uint256 mutationRate,
        uint256 gridSize
    ) internal returns (uint256) {
        return 0;
    }

    /// @notice Process the culling phase
    function processCulling(
        mapping(uint256 => CreatureLib.Creature) storage creatures,
        uint256[] storage creatureIds,
        uint256 startIndex
    ) internal returns (uint256) {
        return 0;
    }
}
