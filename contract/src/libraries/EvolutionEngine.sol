// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {CreatureLib} from "./CreatureLib.sol";
import {EntropyLib} from "./EntropyLib.sol";

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

            bytes32 entropy = EntropyLib.getEntropy(
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
        mapping(uint256 => bool) storage foodMap,
        uint256 gridSize,
        uint256 startIndex
    ) internal returns (uint256) {
        uint256 len = creatureIds.length;
        uint256 processed;

        for (uint256 i = startIndex; i < len; i++) {
            if (processed >= MAX_BATCH || gasleft() < GAS_RESERVE) {
                return i;
            }

            CreatureLib.Creature storage c = creatures[creatureIds[i]];
            if (!c.alive) continue;

            uint256 posKey = uint256(c.x) * gridSize + uint256(c.y);
            if (foodMap[posKey]) {
                foodMap[posKey] = false;
                uint16 gain = uint16(c.intelligence) / 5;
                if (gain == 0) gain = 1;

                if (c.energy + gain > 500) {
                    c.energy = 500;
                } else {
                    c.energy += gain;
                }
            }

            processed++;
        }

        return 0;
    }

    event BreedingOccurred(
        uint256 indexed arenaId,
        uint256 parent1,
        uint256 parent2,
        uint256 child
    );
    event CreatureBorn(
        uint256 indexed arenaId,
        uint256 creatureId,
        address owner,
        bytes32 genome
    );

    /// @notice Process the breeding phase
    function processBreeding(
        mapping(uint256 => CreatureLib.Creature) storage creatures,
        uint256[] storage creatureIds,
        uint256 startIndex,
        uint256 mutationRate,
        uint256 gridSize,
        uint256 nextCreatureIdRef
    ) internal returns (uint256, uint256) {
        uint256 len = creatureIds.length;
        uint256 processed;
        uint256 maxPopulation = (gridSize * gridSize) / 2;

        for (uint256 i = startIndex; i < len; i++) {
            if (processed >= MAX_BATCH || gasleft() < GAS_RESERVE) {
                return (i, nextCreatureIdRef);
            }

            if (creatureIds.length >= maxPopulation) {
                return (0, nextCreatureIdRef);
            }

            CreatureLib.Creature storage pA = creatures[creatureIds[i]];
            if (!pA.alive || pA.energy < 150) {
                processed++;
                continue;
            }

            for (uint256 j = i + 1; j < len; j++) {
                if (gasleft() < GAS_RESERVE) {
                    return (i, nextCreatureIdRef);
                }

                CreatureLib.Creature storage pB = creatures[creatureIds[j]];
                if (!pB.alive || pB.energy < 150) continue;

                uint256 distX = pA.x > pB.x ? pA.x - pB.x : pB.x - pA.x;
                uint256 distY = pA.y > pB.y ? pA.y - pB.y : pB.y - pA.y;
                if (distX > 2 || distY > 2) continue;

                pA.energy -= 50;
                pB.energy -= 50;

                uint256 entropy = uint256(
                    EntropyLib.getEntropy(
                        abi.encode(
                            block.prevrandao,
                            nextCreatureIdRef,
                            pA.id,
                            pB.id
                        )
                    )
                );

                bytes32 childGenome = CreatureLib.crossover(
                    pA.genome,
                    pB.genome,
                    entropy
                );
                childGenome = CreatureLib.mutate(
                    childGenome,
                    mutationRate,
                    entropy
                );

                (
                    uint8 speed,
                    uint8 strength,
                    uint8 intel,
                    uint8 agg,
                    uint8 repro,
                    uint8 def
                ) = CreatureLib.decodeGenome(childGenome);
                speed = speed < 10 ? 10 : speed;
                strength = strength < 10 ? 10 : strength;
                intel = intel < 10 ? 10 : intel;
                agg = agg < 10 ? 10 : agg;
                repro = repro < 10 ? 10 : repro;
                def = def < 10 ? 10 : def;
                childGenome = CreatureLib.encodeGenome(
                    childGenome,
                    speed,
                    strength,
                    intel,
                    agg,
                    repro,
                    def
                );

                CreatureLib.Creature storage stronger = pA.strength >
                    pB.strength
                    ? pA
                    : pB;

                uint8 childX = stronger.x;
                uint8 childY = stronger.y;
                if (entropy % 2 == 0) {
                    childX = childX > 0 ? childX - 1 : childX + 1;
                } else {
                    childY = childY > 0 ? childY - 1 : childY + 1;
                }
                if (childX >= gridSize) childX = uint8(gridSize - 1);
                if (childY >= gridSize) childY = uint8(gridSize - 1);

                uint32 childGen = pA.generation > pB.generation
                    ? pA.generation + 1
                    : pB.generation + 1;

                uint256 childId = nextCreatureIdRef++;

                creatureIds.push(childId);
                creatures[childId] = CreatureLib.Creature({
                    id: childId,
                    owner: stronger.owner,
                    speed: speed,
                    strength: strength,
                    intelligence: intel,
                    aggression: agg,
                    reproRate: repro,
                    defense: def,
                    energy: 80,
                    hp: 80,
                    x: childX,
                    y: childY,
                    generation: childGen,
                    alive: true,
                    genome: childGenome
                });

                emit BreedingOccurred(0, pA.id, pB.id, childId);
                emit CreatureBorn(0, childId, stronger.owner, childGenome);
                break;
            }

            processed++;
        }

        return (0, nextCreatureIdRef);
    }

    /// @notice Process the culling phase
    function processCulling(
        mapping(uint256 => CreatureLib.Creature) storage creatures,
        uint256[] storage creatureIds,
        uint256 startIndex
    ) internal returns (uint256) {
        uint256 len = creatureIds.length;

        // Execute the whole culling phase in one shot to properly identify the bottom 20%
        if (startIndex > 0) return 0;

        uint256 aliveCount = 0;

        // Pass 1: Kill 0 energy/hp and count remaining alive
        for (uint256 i = 0; i < len; i++) {
            CreatureLib.Creature storage c = creatures[creatureIds[i]];
            if (!c.alive) continue;

            if (c.energy == 0 || c.hp == 0) {
                c.alive = false;
                emit CreatureDied(0, c.id);
            } else {
                aliveCount++;
            }
        }

        // Pass 2: Sort and kill bottom 20%
        if (aliveCount > 0) {
            uint256[] memory aliveIds = new uint256[](aliveCount);
            uint256[] memory fitnesses = new uint256[](aliveCount);

            uint256 idx = 0;
            for (uint256 i = 0; i < len; i++) {
                CreatureLib.Creature storage c = creatures[creatureIds[i]];
                if (c.alive) {
                    aliveIds[idx] = c.id;
                    fitnesses[idx] = CreatureLib.fitness(c);
                    idx++;
                }
            }

            if (aliveCount > 1) {
                _quickSort(aliveIds, fitnesses, 0, int256(aliveCount - 1));
            }

            uint256 toKill = aliveCount / 5; // bottom 20%
            for (uint256 i = 0; i < toKill; i++) {
                uint256 killId = aliveIds[i];
                creatures[killId].alive = false;
                emit CreatureDied(0, killId);
            }
        }

        return 0;
    }

    function _quickSort(
        uint256[] memory ids,
        uint256[] memory fitnesses,
        int256 left,
        int256 right
    ) internal pure {
        int256 i = left;
        int256 j = right;
        if (i == j) return;
        uint256 pivot = fitnesses[uint256(left + (right - left) / 2)];
        while (i <= j) {
            while (fitnesses[uint256(i)] < pivot) i++;
            while (pivot < fitnesses[uint256(j)]) j--;
            if (i <= j) {
                (fitnesses[uint256(i)], fitnesses[uint256(j)]) = (
                    fitnesses[uint256(j)],
                    fitnesses[uint256(i)]
                );
                (ids[uint256(i)], ids[uint256(j)]) = (
                    ids[uint256(j)],
                    ids[uint256(i)]
                );
                i++;
                j--;
            }
        }
        if (left < j) _quickSort(ids, fitnesses, left, j);
        if (i < right) _quickSort(ids, fitnesses, i, right);
    }
}
