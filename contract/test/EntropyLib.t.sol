// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "forge-std/Test.sol";
import "../src/libraries/EntropyLib.sol";
import "../src/interfaces/ISystem.sol";

/// @title EntropyLibTest — Tests for BLAKE2/keccak256 fallback entropy
contract EntropyLibTest is Test {
    /// @notice On local anvil, the System precompile does not exist.
    ///         EntropyLib should gracefully fall back to keccak256.
    function test_Fallback_UsesKeccak256OnAnvil() public view {
        bytes memory seed = abi.encode(
            uint256(12345),
            uint256(1),
            uint256(42)
        );

        // Call EntropyLib — on anvil, should fall back to keccak256
        bytes32 result = EntropyLib.getEntropy(seed);

        // The result should match a plain keccak256 of the same seed
        bytes32 expected = keccak256(seed);
        assertEq(result, expected, "Fallback should return keccak256 on anvil");
    }

    /// @notice Verify different seeds produce different entropy (non-collision sanity check)
    function test_Entropy_DifferentSeeds() public view {
        bytes memory seedA = abi.encode(uint256(1), uint256(2), uint256(3));
        bytes memory seedB = abi.encode(uint256(4), uint256(5), uint256(6));

        bytes32 a = EntropyLib.getEntropy(seedA);
        bytes32 b = EntropyLib.getEntropy(seedB);

        assertTrue(a != b, "Different seeds must produce different entropy");
    }

    /// @notice Verify same seed always produces the same entropy (determinism)
    function test_Entropy_Deterministic() public view {
        bytes memory seed = abi.encode(uint256(999), uint256(0), uint256(7));

        bytes32 first = EntropyLib.getEntropy(seed);
        bytes32 second = EntropyLib.getEntropy(seed);

        assertEq(first, second, "Same seed must produce same entropy");
    }

    /// @notice Verify the ISystem interface compiles and the precompile address constant is correct
    function test_Interface_Compiles() public pure {
        // The System precompile address is fixed on Polkadot Hub
        address expected = 0x0000000000000000000000000000000000000900;
        assertEq(EntropyLib.SYSTEM_PRECOMPILE, expected, "Precompile address mismatch");
    }

    /// @notice Verify that the BLAKE256_SELECTOR matches the expected function selector
    function test_SelectorIsCorrect() public pure {
        bytes4 expected = bytes4(keccak256("hashBlake256(bytes)"));
        assertEq(EntropyLib.BLAKE256_SELECTOR, expected, "Selector mismatch");
    }
}
