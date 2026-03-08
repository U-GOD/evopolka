// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {Test} from "forge-std/Test.sol";
import {EvoPolkaArena} from "../src/EvoPolkaArena.sol";

contract EmergencyControlsTest is Test {
    EvoPolkaArena public arena;
    address owner = address(this);
    address player1 = address(0x111);
    address player2 = address(0x222);

    receive() external payable {}

    function setUp() public {
        arena = new EvoPolkaArena();

        vm.deal(player1, 10 ether);
        vm.deal(player2, 10 ether);
        vm.deal(address(0x333), 10 ether); // another player
    }

    function test_Emergency_RevertsBeforeDelay() public {
        uint256 arenaId = arena.createArena(1 ether, 3, 20, 3, 500, 1);

        vm.prank(player1);
        arena.joinArena{value: 1 ether}(arenaId);

        vm.expectRevert("Too early");
        arena.emergencyWithdraw(arenaId);
    }

    function test_Emergency_SuccessAfterDelay() public {
        uint256 arenaId = arena.createArena(1 ether, 3, 20, 3, 500, 1);

        vm.prank(player1);
        arena.joinArena{value: 1 ether}(arenaId);

        vm.prank(player2);
        arena.joinArena{value: 1 ether}(arenaId);

        // Advance time by 7 days + 1 second
        vm.warp(block.timestamp + 7 days + 1);

        uint256 ownerBalBefore = address(this).balance;

        // Owner invokes emergency withdrawal
        arena.emergencyWithdraw(arenaId);

        uint256 ownerBalAfter = address(this).balance;

        // Total pot should be 2 ether
        assertEq(
            ownerBalAfter - ownerBalBefore,
            2 ether,
            "Owner should receive the 2 ether pot"
        );

        // Assert state is finished and pot is 0
        (, EvoPolkaArena.ArenaState state, , uint256 pot, , , , , , , ) = arena
            .arenas(arenaId);

        assertEq(
            uint(state),
            uint(EvoPolkaArena.ArenaState.FINISHED),
            "Arena should be forcefully FINISHED"
        );
        assertEq(pot, 0, "Pot should be drained to 0");
    }

    function test_Emergency_OnlyOwner() public {
        uint256 arenaId = arena.createArena(1 ether, 3, 20, 3, 500, 1);

        vm.warp(block.timestamp + 7 days + 1);

        vm.prank(player1);
        vm.expectRevert(); // Ownable revert msg varies based on oz ver, blind revert check is sufficient
        arena.emergencyWithdraw(arenaId);
    }

    function test_Emergency_RevertsIfAlreadyFinished() public {
        uint256 arenaId = arena.createArena(1 ether, 3, 20, 3, 500, 1);

        vm.prank(player1);
        arena.joinArena{value: 1 ether}(arenaId);

        vm.prank(player2);
        arena.joinArena{value: 1 ether}(arenaId);

        vm.prank(player1);
        arena.startArena(arenaId);

        uint256 currentBlock = block.number;
        for (uint i = 0; i < 3; i++) {
            currentBlock += 10;
            vm.roll(currentBlock);
            arena.runEvolutionRound(arenaId);
        }

        // Arena is FINISHED natively now
        vm.warp(block.timestamp + 7 days + 1);

        vm.expectRevert("Already finished");
        arena.emergencyWithdraw(arenaId);
    }

    function test_Pause_BlocksJoinAndRound() public {
        uint256 arenaId = arena.createArena(1 ether, 3, 20, 3, 500, 1);

        vm.prank(player1);
        arena.joinArena{value: 1 ether}(arenaId);

        vm.prank(player2);
        arena.joinArena{value: 1 ether}(arenaId);

        vm.prank(player1);
        arena.startArena(arenaId);

        // Pause
        arena.pause();

        // Attempt to run round while paused
        vm.roll(block.number + 10);
        vm.expectRevert(); // EnforcedPaused() / "Pausable: paused"
        arena.runEvolutionRound(arenaId);

        // Attempt another user join while paused
        vm.prank(address(0x333));
        vm.expectRevert();
        arena.joinArena{value: 1 ether}(arenaId);

        // Unpause
        arena.unpause();

        // Attempt should now succeed
        arena.runEvolutionRound(arenaId);

        // Assert phase advanced gracefully
        (uint256 id, EvoPolkaArena.ArenaState state, , , , , , , , , ) = arena
            .arenas(arenaId);
        assertEq(id, arenaId);
        assertEq(uint(state), uint(EvoPolkaArena.ArenaState.ACTIVE)); // Reverts to ACTIVE after 1 round
    }

    function test_Pause_OnlyOwner() public {
        vm.prank(player1);
        vm.expectRevert();
        arena.pause();

        vm.prank(player1);
        vm.expectRevert();
        arena.unpause();
    }
}
