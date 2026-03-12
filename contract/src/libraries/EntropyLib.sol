// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

/// @title EntropyLib — BLAKE2-first entropy with keccak256 fallback
/// @notice Provides a single `getEntropy(bytes)` function that:
///         1. Attempts to call the Polkadot Hub System precompile for BLAKE2b-256
///         2. Falls back to keccak256 when the precompile is unavailable (local anvil, EVM forks)
/// @dev    This allows the same contract bytecode to run on both PVM (production) and EVM (tests)
///         without conditional compilation or separate builds.
///         The fallback is safe because both hashing algorithms produce 32-byte pseudo-random digests
///         from the same seed inputs — only the algorithm differs.
library EntropyLib {
    /// @dev System precompile address on Polkadot Hub (per foundry-polkadot SKILL).
    address internal constant SYSTEM_PRECOMPILE = 0x0000000000000000000000000000000000000900;

    /// @dev Selector for `hashBlake256(bytes)` = bytes4(keccak256("hashBlake256(bytes)"))
    bytes4 internal constant BLAKE256_SELECTOR = bytes4(keccak256("hashBlake256(bytes)"));

    /// @notice Produce a 32-byte entropy digest from `seed`.
    ///         Uses BLAKE2b-256 on Polkadot Hub; keccak256 elsewhere.
    /// @param  seed  Packed entropy material (e.g. abi.encode(block.prevrandao, roundNumber, creatureId))
    /// @return digest  The 32-byte hash result.
    function getEntropy(bytes memory seed) internal view returns (bytes32 digest) {
        // Fast path: check if the System precompile exists at 0x...0900
        if (SYSTEM_PRECOMPILE.code.length > 0) {
            // Encode the call: hashBlake256(bytes)
            bytes memory payload = abi.encodeWithSelector(BLAKE256_SELECTOR, seed);

            // staticcall — pure/view, no state change, safe to call
            (bool ok, bytes memory result) = SYSTEM_PRECOMPILE.staticcall(payload);

            if (ok && result.length >= 32) {
                return abi.decode(result, (bytes32));
            }
            // If the precompile call failed for any reason, fall through to keccak256
        }

        // Fallback: keccak256 (works on anvil, hardhat, any EVM)
        return keccak256(seed);
    }
}
