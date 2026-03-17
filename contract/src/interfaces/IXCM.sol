// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

/// @title IXCM
/// @notice Interface for the Polkadot Hub XCM precompile at 0x00000000000000000000000000000000000a0000
/// @dev Reference: https://docs.polkadot.com/develop/smart-contracts/precompiles/xcm/
///      Three core functions: execute (local), send (cross-chain), weighMessage (fee estimation)
interface IXCM {
    // -------------------------------------------------------------------------
    // Core XCM functions (matches actual Polkadot Hub precompile ABI)
    // -------------------------------------------------------------------------

    /// @notice Execute an XCM message locally on this chain
    /// @param message SCALE-encoded XCM versioned message bytes
    /// @param maxWeight Maximum weight to allow for execution (ref_time, proof_size)
    /// @return success True if execution succeeded
    function execute(bytes memory message, uint64 maxWeight) external returns (bool success);

    /// @notice Send an XCM message to a destination parachain
    /// @param dest SCALE-encoded MultiLocation of the destination
    /// @param message SCALE-encoded XCM versioned message bytes
    /// @return success True if the message was dispatched
    function send(bytes memory dest, bytes memory message) external returns (bool success);

    /// @notice Estimate the execution weight of an XCM message
    /// @param message SCALE-encoded XCM versioned message bytes
    /// @return refTime Estimated ref_time weight units
    /// @return proofSize Estimated proof_size weight units
    function weighMessage(bytes memory message)
        external
        view
        returns (uint64 refTime, uint64 proofSize);
}
