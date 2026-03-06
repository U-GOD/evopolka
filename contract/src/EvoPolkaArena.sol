// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {
    ReentrancyGuard
} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {Pausable} from "@openzeppelin/contracts/utils/Pausable.sol";

/// @title EvoPolkaArena
/// @notice On-chain artificial life evolution arena on Polkadot Hub
/// @dev Placeholder — full implementation coming in Phase 1
contract EvoPolkaArena is ReentrancyGuard, Ownable, Pausable {
    enum ArenaState {
        LOBBY,
        ACTIVE,
        EVOLVING,
        FINISHED
    }

    uint256 public nextArenaId;

    event ArenaCreated(uint256 indexed arenaId, address creator);

    constructor() Ownable(msg.sender) {}

    /// @notice Placeholder to verify the build works
    function version() external pure returns (string memory) {
        return "EvoPolka v0.1.0";
    }
}
