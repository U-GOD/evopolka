// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {CreatureLib} from "./CreatureLib.sol";

/// @title EvolutionEngine
/// @notice External library handling the heavy logic of the 5 evolution phases
/// @dev Separated from EvoPolkaArena to prevent PVM bytecode bloat
library EvolutionEngine {
    uint8 constant PHASE_NONE = 0;
    uint8 constant PHASE_MOVEMENT = 1;
    uint8 constant PHASE_COMBAT = 2;
    uint8 constant PHASE_FEEDING = 3;
    uint8 constant PHASE_BREEDING = 4;
    uint8 constant PHASE_CULLING = 5;

    uint256 constant MAX_BATCH = 20;

    /// @notice Process the movement phase for a batch of creatures
    /// @return newProcessedIndex The updated index, or 0 if phase is complete
    function processMovement(
        uint256 arenaId,
        uint256 startIndex,
        uint256 roundNumber
    ) external returns (uint256 newProcessedIndex) {
        return 0;
    }

    /// @notice Process the combat phase
    function processCombat(
        uint256 arenaId,
        uint256 startIndex
    ) external returns (uint256 newProcessedIndex) {
        return 0;
    }

    /// @notice Process the feeding phase
    function processFeeding(
        uint256 arenaId,
        uint256 startIndex
    ) external returns (uint256 newProcessedIndex) {
        return 0;
    }

    /// @notice Process the breeding phase
    function processBreeding(
        uint256 arenaId,
        uint256 startIndex,
        uint256 mutationRate,
        uint256 gridSize
    ) external returns (uint256 newProcessedIndex) {
        return 0;
    }

    /// @notice Process the culling phase
    function processCulling(
        uint256 arenaId,
        uint256 startIndex
    ) external returns (uint256 newProcessedIndex) {
        return 0;
    }
}
