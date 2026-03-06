---
name: evopolka-patterns
description: EvoPolka project-specific patterns for the on-chain genetic algorithm evolution arena
---

# EvoPolka Development Patterns Skill

## Overview
EvoPolka is an on-chain artificial life evolution arena on Polkadot Hub. This skill defines the project-specific patterns, data structures, and conventions.

## Core Data Structures

### Creature
```solidity
struct Creature {
    uint256 id;
    address owner;
    uint8 speed;        // 0-255 — tiles moved per round
    uint8 strength;     // 0-255 — attack power
    uint8 intelligence; // 0-255 — foraging efficiency
    uint8 aggression;   // 0-255 — combat initiation chance
    uint8 reproRate;    // 0-255 — breeding probability
    uint8 defense;      // 0-255 — damage reduction
    uint16 energy;      // current energy (food consumed)
    uint16 hp;          // hit points; 0 = dead
    uint8 x;            // grid position X
    uint8 y;            // grid position Y
    uint32 generation;  // evolution generation counter
    bool alive;
    bytes32 genome;     // packed 32-byte genetic data
}
```

### Arena
```solidity
enum ArenaState { LOBBY, ACTIVE, EVOLVING, FINISHED }

struct Arena {
    uint256 id;
    ArenaState state;
    uint256 stakePerPlayer;
    uint256 totalPot;
    uint256 roundNumber;
    uint256 maxRounds;
    uint256 gridSize;       // NxN grid
    uint256 creaturesPerPlayer;
    uint256 mutationRate;   // basis points 0-10000
    uint256 lastRoundBlock;
    uint256 roundInterval;  // blocks between rounds
}
```

## Genetic Algorithm Conventions

### Genome Encoding
- 32 bytes = 256 bits
- First 6 bytes map to traits (speed, strength, intelligence, aggression, reproRate, defense)
- Remaining bytes are "junk DNA" — available for future traits and used in crossover

### Mutation
- Flip random bits based on `mutationRate` (basis points)
- Use `keccak256(abi.encodePacked(block.prevrandao, block.number, nonce++))` for entropy
- NEVER use `block.timestamp` for randomness

### Crossover
- Single-point crossover: pick a random bit position, take parent A's bits before it and parent B's after
- Both parents must have `energy > breedingThreshold` and be in top 25% fitness

### Fitness Function
```
fitness = (speed + strength + intelligence + defense) * energy * (generation + 1) / 1000
```
Higher is better. Used for breeding selection and culling decisions.

## Evolution Round Order (MUST follow this sequence)

1. **MOVEMENT** — Each creature moves `speed/10` tiles toward nearest food or weaker creature
2. **COMBAT** — Creatures sharing a tile fight. `attacker.strength` vs `defender.defense`
3. **FEEDING** — Creatures on food tiles gain energy proportional to `intelligence`
4. **BREEDING** — Top 25% by fitness breed if energy sufficient. Crossover + mutation
5. **CULLING** — Bottom 20% by fitness die. Zero-energy creatures die

## Event Emission Rules

Emit events for EVERY state change visible to the frontend:

```solidity
event ArenaCreated(uint256 indexed arenaId, address creator);
event PlayerJoined(uint256 indexed arenaId, address player);
event ArenaStarted(uint256 indexed arenaId);
event RoundExecuted(uint256 indexed arenaId, uint256 round, uint256 survivors);
event RoundPartial(uint256 indexed arenaId, uint256 round, uint256 processed);
event CreatureBorn(uint256 indexed arenaId, uint256 creatureId, address owner, bytes32 genome);
event CreatureDied(uint256 indexed arenaId, uint256 creatureId);
event CombatOccurred(uint256 indexed arenaId, uint256 attacker, uint256 defender, bool attackerWon);
event BreedingOccurred(uint256 indexed arenaId, uint256 parent1, uint256 parent2, uint256 child);
event DisasterTriggered(uint256 indexed arenaId, uint8 disasterType);
event ArenaFinished(uint256 indexed arenaId);
event RewardClaimed(uint256 indexed arenaId, address player, uint256 amount);
```

## Gas Optimization Rules

1. **Batch processing** — Process at most 20 creatures per transaction call
2. **Gas checks** — In any loop, check `gasleft() > 50_000` before each iteration
3. **Partial rounds** — If gas runs out mid-round, emit `RoundPartial` and let the caller continue with `continueRound()`
4. **Storage packing** — Pack creature traits into as few storage slots as possible (6 uint8s = 6 bytes = fits in one slot with other fields)

## Reward Distribution

```
protocolFee  = totalPot * 2 / 100
playerPool   = totalPot - protocolFee
playerReward = playerPool * playerSurvivors[player] / totalSurvivors
```

Use pull pattern: store rewards in a `mapping(address => uint256)`, let players claim via `claimReward()`.

## File Naming Convention

| Type | Directory | Naming |
|------|-----------|--------|
| Contracts | `src/` | `PascalCase.sol` |
| Libraries | `src/libraries/` | `PascalCase.sol` |
| Interfaces | `src/interfaces/` | `IPascalCase.sol` |
| Tests | `test/` | `PascalCase.t.sol` |
| Deploy scripts | `script/` | `PascalCase.s.sol` |

## Testing Conventions

- Every public/external function must have at least one test
- Test names: `test_FunctionName_Scenario` (e.g., `test_JoinArena_RevertsWhenFull`)
- Test revert messages: `test_FunctionName_RevertsWhen_Condition`
- Use `vm.deal(address, amount)` to fund test accounts
- Use `vm.prank(address)` to impersonate callers
- Use `vm.expectEmit()` to verify events
- Use `vm.expectRevert()` to verify revert conditions
