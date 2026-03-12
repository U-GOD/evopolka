// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

/// @title EntropyLib
/// @notice BLAKE2-first entropy with keccak256 fallback for cross-environment compatibility.
/// @dev Uses the Polkadot Hub System precompile (0x...0900) for BLAKE2b-256 hashing when
///      available. Falls back to keccak256 on EVM-only environments (anvil, Hardhat).
library EntropyLib {
    /// @dev System precompile address on Polkadot Hub.
    address internal constant SYSTEM_PRECOMPILE = 0x0000000000000000000000000000000000000900;

    /// @dev Function selector for ISystem.hashBlake256(bytes).
    bytes4 internal constant BLAKE256_SELECTOR = bytes4(keccak256("hashBlake256(bytes)"));

    /// @notice Produce a 32-byte entropy digest from `seed`.
    /// @param  seed  Packed entropy material (e.g. abi.encode(block.prevrandao, nonce, id)).
    /// @return digest  32-byte hash (BLAKE2b-256 on PVM, keccak256 on EVM).
    function getEntropy(bytes memory seed) internal view returns (bytes32 digest) {
        if (SYSTEM_PRECOMPILE.code.length > 0) {
            bytes memory payload = abi.encodeWithSelector(BLAKE256_SELECTOR, seed);
            (bool ok, bytes memory result) = SYSTEM_PRECOMPILE.staticcall(payload);
            if (ok && result.length >= 32) {
                return abi.decode(result, (bytes32));
            }
        }
        return keccak256(seed);
    }
}
