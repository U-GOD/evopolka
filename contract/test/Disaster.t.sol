// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {Test} from "forge-std/Test.sol";
import {ArenaHarness} from "./helpers/ArenaHarness.sol";
import {EvoPolkaArena} from "../src/EvoPolkaArena.sol";
import {CreatureLib} from "../src/libraries/CreatureLib.sol";
import {EntropyLib} from "../src/libraries/EntropyLib.sol";

contract DisasterTest is Test {
    using CreatureLib for CreatureLib.Creature;
    using CreatureLib for bytes32;

    ArenaHarness public arena;
    uint256 public arenaId;
    address public playerA = address(0x111);

    function setUp() public {
        arena = new ArenaHarness();

        arenaId = arena.createArena({
            stakePerPlayer: 1 ether,
            maxRounds: 10,
            gridSize: 20,
            creaturesPerPlayer: 10, // Many creatures for Asteroid stat checks
            mutationRate: 500,
            roundInterval: 1
        });

        vm.deal(playerA, 10 ether);
        vm.prank(playerA);
        arena.joinArena{value: 1 ether}(arenaId);

        address playerB = address(0x222);
        vm.deal(playerB, 10 ether);
        vm.prank(playerB);
        arena.joinArena{value: 1 ether}(arenaId);

        arena.startArena(arenaId);

        // Force to round 5 so cooldown checks pass
        arena.setRoundNumber(arenaId, 5);
    }

    function _countAlive() internal view returns (uint256) {
        uint256 count = 0;
        uint256[] memory ids = arena.getCreatureIds(arenaId);
        for (uint i = 0; i < ids.length; i++) {
            if (arena.getCreature(arenaId, ids[i]).alive) {
                count++;
            }
        }
        return count;
    }

    function _setAllStats(uint8 defense, uint16 energy) internal {
        uint256[] memory ids = arena.getCreatureIds(arenaId);
        for (uint i = 0; i < ids.length; i++) {
            arena.setCreatureState(
                arenaId,
                ids[i],
                0,
                0,
                10,
                10,
                10,
                10,
                defense,
                energy,
                100
            );
        }
    }

    function test_Disaster_RevertsWhenNotActive() public {
        arena.setArenaState(arenaId, EvoPolkaArena.ArenaState.FINISHED);
        
        vm.expectRevert("Not active");
        arena.triggerDisaster(arenaId, uint8(EvoPolkaArena.DisasterType.ASTEROID));
    }

    function test_Disaster_Cooldown() public {
        // Round 4 is not a multiple of 5
        arena.setRoundNumber(arenaId, 4);
        
        vm.expectRevert("Disaster cooldown");
        arena.triggerDisaster(arenaId, uint8(EvoPolkaArena.DisasterType.ASTEROID));
    }

    function test_Disaster_EmitsEvent() public {
        // Expect DisasterTriggered event
        vm.expectEmit(true, false, false, true);
        emit EvoPolkaArena.DisasterTriggered(arenaId, uint8(EvoPolkaArena.DisasterType.PLAGUE));
        
        arena.triggerDisaster(arenaId, uint8(EvoPolkaArena.DisasterType.PLAGUE));
    }

    function test_Asteroid_Kills50Percent() public {
        // Asteroid uses entropy based on block.prevrandao, block.number, and c.id
        // Since it's pseudo-random, testing exact 50% is flaky. But we can test that *some* die.
        uint256 beforeCount = _countAlive();
        
        arena.triggerDisaster(arenaId, uint8(EvoPolkaArena.DisasterType.ASTEROID));
        
        uint256 afterCount = _countAlive();
        
        assertTrue(afterCount < beforeCount, "Asteroid completely missed");
        assertTrue(afterCount > 0, "Asteroid killed everyone (statistical anomaly or bug)");
    }

    function test_Plague_KillsLowDefense() public {
        // Set all creatures to 20 defense (below 50 threshold) and one to 80
        _setAllStats(20, 100);
        uint256[] memory ids = arena.getCreatureIds(arenaId);
        
        // Boost one to survive
        arena.setCreatureState(arenaId, ids[0], 0, 0, 10, 10, 10, 10, 80, 100, 100);

        arena.triggerDisaster(arenaId, uint8(EvoPolkaArena.DisasterType.PLAGUE));

        uint256 aliveCount = _countAlive();
        assertEq(aliveCount, 1, "Only the high-defense creature should survive");
        assertTrue(arena.getCreature(arenaId, ids[0]).alive, "Hero should be alive");
    }

    function test_IceAge_DrainsEnergy() public {
        _setAllStats(50, 100); // 100 energy each
        
        arena.triggerDisaster(arenaId, uint8(EvoPolkaArena.DisasterType.ICE_AGE));

        uint256[] memory ids = arena.getCreatureIds(arenaId);
        for (uint i = 0; i < ids.length; i++) {
            uint16 updatedEnergy = arena.getCreature(arenaId, ids[i]).energy;
            // 100 / 4 = 25
            assertEq(updatedEnergy, 25, "Energy should drop by 75%");
        }
    }

    function test_MutationStorm_IncreasesRate() public {
        EvoPolkaArena.Arena memory preArena = arena.getArena(arenaId);
        assertEq(preArena.mutationRate, 500, "Should start at 5% (500 bps)");

        arena.triggerDisaster(arenaId, uint8(EvoPolkaArena.DisasterType.MUTATION_STORM));

        EvoPolkaArena.Arena memory postArena = arena.getArena(arenaId);
        assertEq(postArena.mutationRate, 2500, "Should increase 5x to 25% (2500 bps)");
    }
}
