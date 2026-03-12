// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

/// @title ISystem — Polkadot Hub System Precompile Interface
/// @notice Solidity interface for the System precompile at 0x0000000000000000000000000000000000000900.
///         Provides access to Polkadot-native cryptographic primitives and runtime queries.
/// @dev    Only callable on Polkadot Hub (PVM). On local anvil/EVM chains these calls will revert
///         — use EntropyLib.sol for a safe fallback wrapper.
///         Reference: https://docs.polkadot.com/develop/smart-contracts/precompiles/
interface ISystem {
    // ──────────────────────────── Hashing ────────────────────────────

    /// @notice Compute the BLAKE2b 256-bit hash of `input`.
    ///         BLAKE2 is Polkadot's native hashing algorithm and is significantly
    ///         more efficient than keccak256 when running inside PVM.
    /// @param  input  Arbitrary bytes to hash.
    /// @return digest The 32-byte BLAKE2b-256 digest.
    function hashBlake256(bytes memory input) external pure returns (bytes32 digest);

    /// @notice Compute the BLAKE2b 128-bit hash of `input`.
    ///         Useful when a shorter hash is sufficient (e.g. storage key prefixes).
    /// @param  input  Arbitrary bytes to hash.
    /// @return digest The first 16 bytes of the BLAKE2b-128 digest (left-padded in bytes32).
    function hashBlake128(bytes memory input) external pure returns (bytes32 digest);
}
