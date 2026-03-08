// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {Test} from "forge-std/Test.sol";
import {EvoPolkaArena} from "../src/EvoPolkaArena.sol";

// Reentrancy attacker
contract Attacker {
    EvoPolkaArena public arena;
    uint256 public arenaId;
    uint256 public attackCount;

    constructor(address _arena) {
        arena = EvoPolkaArena(_arena);
    }

    function setArenaId(uint256 _id) external {
        arenaId = _id;
    }

    receive() external payable {
        if (attackCount < 2) {
            attackCount++;
            arena.claimReward(arenaId);
        }
    }
}

contract ClaimRewardsTest is Test {
    EvoPolkaArena public arena;
    address player1 = address(0x111);
    address player2 = address(0x222);

    function setUp() public {
        arena = new EvoPolkaArena();
    }

    function test_Claim_SuccessfulWithdraw() public {
        // We will seed the contract with some ETH manually and manipulate pendingRewards
        // But since pendingRewards is purely internal to EvoPolkaArena, we simulate via the entire flow.

        // Create, Join, Start, Finish, Distribute
        vm.deal(player1, 10 ether);
        vm.deal(player2, 10 ether);

        uint256 arenaId = arena.createArena(1 ether, 3, 20, 3, 500, 1);

        vm.prank(player1);
        arena.joinArena{value: 1 ether}(arenaId);

        vm.prank(player2);
        arena.joinArena{value: 1 ether}(arenaId);

        vm.prank(player1);
        arena.startArena(arenaId);

        // Cheat: fast-forward rounds to maxRounds
        uint256 currentBlock = block.number;
        for (uint i = 0; i < 3; i++) {
            currentBlock += 10;
            vm.roll(currentBlock);
            arena.runEvolutionRound(arenaId);
        }

        arena.distributeRewards(arenaId);

        // Everyone survived exactly 3 creatures if we didn't force damage.
        // Thus exact 50-50 split of 1.96 ETH. Each gets 0.98 ETH.
        uint256 p1BalBefore = player1.balance;
        uint256 p2BalBefore = player2.balance;

        vm.prank(player1);
        arena.claimReward(arenaId);

        vm.prank(player2);
        arena.claimReward(arenaId);

        uint256 p1BalAfter = player1.balance;
        uint256 p2BalAfter = player2.balance;

        assertEq(
            p1BalAfter - p1BalBefore,
            0.98 ether,
            "Player 1 should have exactly claimed 0.98 ether"
        );
        assertEq(
            p2BalAfter - p2BalBefore,
            0.98 ether,
            "Player 2 should have exactly claimed 0.98 ether"
        );

        // Ensure pendingRewards mapping zeroed out
        assertEq(arena.pendingRewards(arenaId, player1), 0);
        assertEq(arena.pendingRewards(arenaId, player2), 0);
    }

    function test_Claim_ZeroBalanceReverts() public {
        uint256 arenaId = arena.createArena(1 ether, 3, 20, 3, 500, 1);

        vm.prank(player1);
        vm.expectRevert("No pending reward");
        arena.claimReward(arenaId);
    }

    function test_Claim_ReentrancyBlocked() public {
        // Setup attacker
        Attacker attacker = new Attacker(address(arena));

        vm.deal(address(attacker), 10 ether);
        vm.deal(player1, 10 ether);

        uint256 arenaId = arena.createArena(1 ether, 1, 20, 3, 500, 1);
        attacker.setArenaId(arenaId);

        vm.prank(address(attacker));
        arena.joinArena{value: 1 ether}(arenaId);

        vm.prank(player1);
        arena.joinArena{value: 1 ether}(arenaId);

        vm.prank(address(attacker));
        arena.startArena(arenaId);

        vm.roll(block.number + 2);
        arena.runEvolutionRound(arenaId); // Ends arena

        arena.distributeRewards(arenaId);

        // Attacker attempts to claim
        uint256 attackerBalBefore = address(attacker).balance;

        // Call will revert because the inner claimReward triggers the reentrancy lock.
        vm.prank(address(attacker));
        vm.expectRevert();
        arena.claimReward(arenaId);

        // It failed, so balance shouldn't change
        uint256 attackerBalAfter = address(attacker).balance;
        assertEq(
            attackerBalBefore,
            attackerBalAfter,
            "Reentrancy should be fully blocked, retaining funds"
        );
    }
}
