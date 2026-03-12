// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

/// @notice Interface for Polkadot Hub's native XCM Precompile at 0x...0a0000
/// @dev Enables sending cross-chain messages via XCM to other parachains
interface IXCM {
    /// @notice Send an XCM message to a destination chain
    /// @param dest The destination multilocation (e.g., ParaId)
    /// @param message The XCM message payload
    /// @return success True if the message was successfully dispatched
    function send(bytes memory dest, bytes memory message) external returns (bool success);

    /// @notice Send a generic cross-chain transfer or arbitrary data (scaffold)
    /// @param destChainId The destination chain ID or parachain ID
    /// @param payload The encoded payload to execute on the destination chain
    /// @return The result hash of the message execution
    function executeCrossChain(uint32 destChainId, bytes memory payload) external payable returns (bytes32);
}
