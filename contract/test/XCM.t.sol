// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "forge-std/Test.sol";
import "../src/EvoPolkaArena.sol";
import "../src/interfaces/IXCM.sol";

/// @title XCM.t.sol
/// @notice Tests for the XCM precompile integration (sendCrossChainStake)
///         Tests verify local fallback behavior (precompile absent on Anvil) and access control
contract XCMTest is Test {
    EvoPolkaArena arena;
    address owner = makeAddr("owner");
    address nonOwner = makeAddr("nonOwner");

    function setUp() public {
        vm.prank(owner);
        arena = new EvoPolkaArena();
        vm.deal(owner, 100 ether);
        vm.deal(nonOwner, 10 ether);
    }

    // --- Access control ---

    function test_SendCrossChainStake_RevertsWhen_NotOwner() public {
        vm.prank(nonOwner);
        vm.expectRevert();
        arena.sendCrossChainStake{value: 1 ether}(1000, 1 ether);
    }

    // --- Validation ---

    function test_SendCrossChainStake_RevertsWhen_ZeroAmount() public {
        vm.prank(owner);
        vm.expectRevert("XCM: amount must be > 0");
        arena.sendCrossChainStake{value: 0}(1000, 0);
    }

    function test_SendCrossChainStake_RevertsWhen_InsufficientValue() public {
        vm.prank(owner);
        vm.expectRevert("XCM: insufficient msg.value");
        // Send 0.5 ETH but request 1 ETH
        arena.sendCrossChainStake{value: 0.5 ether}(1000, 1 ether);
    }

    // --- Fallback behavior on local Anvil ---

    function test_SendCrossChainStake_NoOpOnAnvil_EmitsEvent() public {
        // On Anvil there is no code at the XCM precompile address,
        // so the call is skipped but the event must still be emitted.
        vm.prank(owner);
        vm.expectEmit(true, false, false, true, address(arena));
        emit EvoPolkaArena.CrossChainStakeSent(1000, 1 ether);
        arena.sendCrossChainStake{value: 1 ether}(1000, 1 ether);
    }

    function test_SendCrossChainStake_NoOpOnAnvil_NoRevert() public {
        // Should complete without revert even with no precompile present
        vm.prank(owner);
        arena.sendCrossChainStake{value: 2 ether}(2000, 2 ether);
    }

    // --- Interface compile check ---

    function test_IXCM_InterfaceCompiles() public pure {
        // Static check: IXCM selector values are accessible
        bytes4 sendSel = IXCM.send.selector;
        bytes4 execSel = IXCM.execute.selector;
        bytes4 weighSel = IXCM.weighMessage.selector;
        assert(sendSel != execSel);
        assert(execSel != weighSel);
    }
}
