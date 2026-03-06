// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {Test} from "forge-std/Test.sol";
import {EvoPolkaArena} from "../src/EvoPolkaArena.sol";

contract EvoPolkaArenaTest is Test {
    EvoPolkaArena public arena;

    function setUp() public {
        arena = new EvoPolkaArena();
    }

    function test_Version() public view {
        assertEq(arena.version(), "EvoPolka v0.1.0");
    }

    function test_InitialArenaId() public view {
        assertEq(arena.nextArenaId(), 0);
    }

    function test_OwnerIsDeployer() public view {
        assertEq(arena.owner(), address(this));
    }
}
