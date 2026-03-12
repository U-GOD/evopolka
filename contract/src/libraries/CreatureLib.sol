// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {EntropyLib} from "./EntropyLib.sol";

/// @title CreatureLib
/// @notice Genetic algorithm encoding, decoding, mutation, and crossover for EvoPolka creatures
library CreatureLib {
    struct Creature {
        uint256 id;
        address owner;
        uint8 speed;
        uint8 strength;
        uint8 intelligence;
        uint8 aggression;
        uint8 reproRate;
        uint8 defense;
        uint16 energy;
        uint16 hp;
        uint8 x;
        uint8 y;
        uint32 generation;
        bool alive;
        bytes32 genome;
    }

    /// @notice Decode 32-byte genome into 6 core traits (first 6 bytes)
    function decodeGenome(
        bytes32 genome
    )
        internal
        pure
        returns (
            uint8 speed,
            uint8 strength,
            uint8 intelligence,
            uint8 aggression,
            uint8 reproRate,
            uint8 defense
        )
    {
        speed = uint8(genome[0]);
        strength = uint8(genome[1]);
        intelligence = uint8(genome[2]);
        aggression = uint8(genome[3]);
        reproRate = uint8(genome[4]);
        defense = uint8(genome[5]);
    }

    /// @notice Encode 6 core traits into a 32-byte genome
    /// @dev Only overrides the first 6 bytes of the provided baseGenome
    function encodeGenome(
        bytes32 baseGenome,
        uint8 speed,
        uint8 strength,
        uint8 intelligence,
        uint8 aggression,
        uint8 reproRate,
        uint8 defense
    ) internal pure returns (bytes32 newGenome) {
        newGenome = baseGenome;
        uint256 cleared = uint256(newGenome) & (type(uint256).max >> 48);
        uint256 packed = (uint256(speed) << 248) |
            (uint256(strength) << 240) |
            (uint256(intelligence) << 232) |
            (uint256(aggression) << 224) |
            (uint256(reproRate) << 216) |
            (uint256(defense) << 208);

        newGenome = bytes32(cleared | packed);
    }

    function crossover(
        bytes32 parentA,
        bytes32 parentB,
        uint256 entropy
    ) internal pure returns (bytes32 childGenome) {
        uint256 pivot = (entropy % 255) + 1;
        uint256 mask = type(uint256).max << pivot;

        uint256 pA = uint256(parentA);
        uint256 pB = uint256(parentB);

        childGenome = bytes32((pA & mask) | (pB & ~mask));
    }

    function mutate(
        bytes32 genome,
        uint256 mutationRateBp,
        uint256 entropy
    ) internal view returns (bytes32 mutatedGenome) {
        if (mutationRateBp == 0) return genome;

        uint256 g = uint256(genome);
        uint256 numMutations = (mutationRateBp * 256) / 10000;
        uint256 currentEntropy = entropy;

        for (uint256 i = 0; i < numMutations; i++) {
            currentEntropy = uint256(EntropyLib.getEntropy(abi.encode(currentEntropy)));
            uint256 bitToFlip = currentEntropy % 256;
            g ^= (uint256(1) << bitToFlip);
        }

        mutatedGenome = bytes32(g);
    }

    /// @notice Calculates creature fitness using core traits, energy, and generation
    function fitness(Creature memory c) internal pure returns (uint256) {
        if (c.hp == 0 || !c.alive) return 0;

        uint256 baseTraits = uint256(c.speed) +
            uint256(c.strength) +
            uint256(c.intelligence) +
            uint256(c.defense);

        return
            (baseTraits * uint256(c.energy) * (uint256(c.generation) + 1)) /
            1000;
    }
}
