// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {Test} from "forge-std/Test.sol";
import {CreatureLib} from "../src/libraries/CreatureLib.sol";

contract CreatureLibTest is Test {
    using CreatureLib for CreatureLib.Creature;
    using CreatureLib for bytes32;

    function test_DecodeGenome() public pure {
        // Create a genome with specific hex bytes at the beginning
        //                                Sp St In Ag Re De
        bytes32 genome = bytes32(
            0x1122334455660000000000000000000000000000000000000000000000000000
        );

        (
            uint8 speed,
            uint8 strength,
            uint8 intell,
            uint8 agg,
            uint8 repro,
            uint8 def
        ) = CreatureLib.decodeGenome(genome);

        assertEq(speed, 0x11);
        assertEq(strength, 0x22);
        assertEq(intell, 0x33);
        assertEq(agg, 0x44);
        assertEq(repro, 0x55);
        assertEq(def, 0x66);
    }

    function test_EncodeGenome() public pure {
        bytes32 baseGenome = bytes32(
            0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF
        );

        bytes32 newGenome = CreatureLib.encodeGenome(
            baseGenome,
            1,
            2,
            3,
            4,
            5,
            6
        );

        (
            uint8 speed,
            uint8 strength,
            uint8 intell,
            uint8 agg,
            uint8 repro,
            uint8 def
        ) = CreatureLib.decodeGenome(newGenome);

        assertEq(speed, 1);
        assertEq(strength, 2);
        assertEq(intell, 3);
        assertEq(agg, 4);
        assertEq(repro, 5);
        assertEq(def, 6);

        // Check that the rest of the bytes are still FF
        assertEq(uint8(newGenome[6]), 0xFF);
        assertEq(uint8(newGenome[31]), 0xFF);
    }

    function test_Crossover() public pure {
        bytes32 pA = bytes32(
            0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF
        );
        bytes32 pB = bytes32(
            0x0000000000000000000000000000000000000000000000000000000000000000
        );

        uint256 entropy = 127; // midpoint (127 bits)
        bytes32 child = CreatureLib.crossover(pA, pB, entropy);

        // child should be top bits from pA (1s), bottom bits from pB (0s).
        // Actual pivot = (127 % 255) + 1 = 128.
        // mask is ~0 << 128 (top 128 bits are 1, bottom 128 bits are 0)
        assertEq(
            child,
            bytes32(
                0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF00000000000000000000000000000000
            )
        );
    }

    function test_Mutate_ZeroRate() public pure {
        bytes32 genome = bytes32(
            0x1234567800000000000000000000000000000000000000000000000000000000
        );
        bytes32 mutated = CreatureLib.mutate(genome, 0, 12345);
        assertEq(mutated, genome);
    }

    function test_Mutate_HighRate() public pure {
        bytes32 genome = bytes32(
            0x0000000000000000000000000000000000000000000000000000000000000000
        );
        bytes32 mutated = CreatureLib.mutate(genome, 1000, 12345); // 10% mutation rate = ~25 bits
        assertTrue(mutated != genome);
    }

    function test_Fitness() public pure {
        CreatureLib.Creature memory c = CreatureLib.Creature({
            id: 1,
            owner: address(1),
            speed: 10,
            strength: 20,
            intelligence: 30,
            aggression: 40,
            reproRate: 50,
            defense: 10,
            energy: 100, // energy
            hp: 100,
            x: 0,
            y: 0,
            generation: 1, // gen + 1 = 2
            alive: true,
            genome: bytes32(0)
        });

        uint256 fit = CreatureLib.fitness(c);
        // baseTraits = 10 + 20 + 30 + 10 = 70
        // (70 * 100 * 2) / 1000 = 14
        assertEq(fit, 14);
    }

    function test_Fitness_Dead() public pure {
        CreatureLib.Creature memory c;
        c.alive = false;
        c.energy = 100;
        c.speed = 100;
        assertEq(CreatureLib.fitness(c), 0);

        c.alive = true;
        c.hp = 0;
        assertEq(CreatureLib.fitness(c), 0);
    }
}
