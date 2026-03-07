// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

/// @title CreatureLib
/// @notice Genetic algorithm encoding, decoding, mutation, and crossover for EvoPolka creatures
library CreatureLib {
    struct Creature {
        uint256 id;
        address owner;
        uint8 speed; // 0-255 — tiles moved per round
        uint8 strength; // 0-255 — attack power
        uint8 intelligence; // 0-255 — foraging efficiency
        uint8 aggression; // 0-255 — combat initiation chance
        uint8 reproRate; // 0-255 — breeding probability
        uint8 defense; // 0-255 — damage reduction
        uint16 energy; // current energy (food consumed)
        uint16 hp; // hit points; 0 = dead
        uint8 x; // grid position X
        uint8 y; // grid position Y
        uint32 generation; // evolution generation counter
        bool alive;
        bytes32 genome; // packed 32-byte genetic data
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

    /// @notice Encode 6 core traits into a 32-byte genome (remaining 26 bytes are junk/random)
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
        // Turn the bytes32 into a byte array conceptually, but in solidity we use bitwise ops
        // Clear first 6 bytes (48 bits)
        uint256 cleared = uint256(newGenome) & (type(uint256).max >> 48);

        // Shift traits to their correct left-aligned positions
        uint256 packed = (uint256(speed) << 248) |
            (uint256(strength) << 240) |
            (uint256(intelligence) << 232) |
            (uint256(aggression) << 224) |
            (uint256(reproRate) << 216) |
            (uint256(defense) << 208);

        newGenome = bytes32(cleared | packed);
    }

    /// @notice Single-point crossover for two genomes
    /// @return childGenome the newly created genome
    function crossover(
        bytes32 parentA,
        bytes32 parentB,
        uint256 entropy
    ) internal pure returns (bytes32 childGenome) {
        // Crossover point from 1 to 255 (bit position)
        uint256 pivot = (entropy % 255) + 1;
        uint256 mask = type(uint256).max << pivot;

        uint256 pA = uint256(parentA);
        uint256 pB = uint256(parentB);

        childGenome = bytes32((pA & mask) | (pB & ~mask));
    }

    /// @notice Randomly flips bits in the genome based on a mutation rate (basis points 0-10000)
    function mutate(
        bytes32 genome,
        uint256 mutationRateBP,
        uint256 entropy
    ) internal pure returns (bytes32 mutatedGenome) {
        if (mutationRateBP == 0) return genome;

        uint256 g = uint256(genome);

        // We cycle through the 256 bits, deciding to flip based on entropy
        // To avoid looping 256 times and burning gas, we approximate mutation:
        // By selecting `numMutations` bits to flip randomly.
        // mutationRateBP is 0 - 10000. 10000 means ~256 bits flipped. => BP * 256 / 10000
        uint256 numMutations = (mutationRateBP * 256) / 10000;

        uint256 currentEntropy = entropy;

        for (uint256 i = 0; i < numMutations; i++) {
            currentEntropy = uint256(keccak256(abi.encode(currentEntropy)));
            uint256 bitToFlip = currentEntropy % 256;
            // Flip the bit
            g ^= (1 << bitToFlip);
        }

        mutatedGenome = bytes32(g);
    }

    /// @notice Fitness calculation
    /// fitness = (speed + strength + intelligence + defense) * energy * (generation + 1) / 1000
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
