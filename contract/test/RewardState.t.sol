// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {Test} from "forge-std/Test.sol";
import {EvoPolkaArena} from "../src/EvoPolkaArena.sol";

contract RewardStateTest is Test {
    EvoPolkaArena public arena;

    function setUp() public {
        arena = new EvoPolkaArena();
    }

    function test_RewardState_FeeRecipientIsOwner() public {
        assertEq(
            arena.feeRecipient(),
            address(this),
            "Fee recipient should be deployer"
        );
    }

    function test_RewardState_SetFeeRecipient() public {
        address newRecipient = address(0x123);
        arena.setFeeRecipient(newRecipient);
        assertEq(
            arena.feeRecipient(),
            newRecipient,
            "Fee recipient should be updatable by owner"
        );
    }

    function test_RewardState_SetFeeRecipientNonOwner() public {
        vm.prank(address(0x111));
        vm.expectRevert(
            abi.encodeWithSignature(
                "OwnableUnauthorizedAccount(address)",
                address(0x111)
            )
        );
        arena.setFeeRecipient(address(0x123));
    }

    function test_RewardState_ArenaCreatedAtIsSet() public {
        uint256 expectedTime = 100000;
        vm.warp(expectedTime);

        uint256 arenaId = arena.createArena({
            stakePerPlayer: 1 ether,
            maxRounds: 10,
            gridSize: 20,
            creaturesPerPlayer: 3,
            mutationRate: 500,
            roundInterval: 1
        });

        assertEq(
            arena.arenaCreatedAt(arenaId),
            expectedTime,
            "arenaCreatedAt should equal block.timestamp"
        );
    }
}
