---
name: solidity-security
description: Solidity smart contract security patterns using OpenZeppelin for safe, auditable contracts
---

# Solidity Security Patterns Skill

## Overview
Apply these security patterns to ALL smart contracts in this project. We use **OpenZeppelin Contracts** as our security foundation.

## Mandatory Patterns

### 1. Reentrancy Protection
ALWAYS use `ReentrancyGuard` on functions that transfer value or make external calls.

```solidity
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

contract MyContract is ReentrancyGuard {
    function withdraw() external nonReentrant {
        // safe
    }
}
```

### 2. Checks-Effects-Interactions (CEI)
ALWAYS follow this exact order in every function:
1. **Checks** — validate inputs, require statements, access control
2. **Effects** — update state variables
3. **Interactions** — external calls, transfers

```solidity
function claimReward(uint256 arenaId) external nonReentrant {
    // CHECKS
    require(arenas[arenaId].state == ArenaState.FINISHED, "Not finished");
    uint256 reward = pendingRewards[msg.sender][arenaId];
    require(reward > 0, "No reward");

    // EFFECTS
    pendingRewards[msg.sender][arenaId] = 0;

    // INTERACTIONS
    (bool success, ) = msg.sender.call{value: reward}("");
    require(success, "Transfer failed");
}
```

### 3. Access Control
Use `Ownable` for admin functions. Use custom modifiers for role-based access.

```solidity
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract MyContract is Ownable {
    constructor() Ownable(msg.sender) {}

    function emergencyPause() external onlyOwner {
        // admin only
    }
}
```

### 4. Pausable
Use `Pausable` for emergency stop mechanisms.

```solidity
import {Pausable} from "@openzeppelin/contracts/utils/Pausable.sol";

contract MyContract is Pausable {
    function joinArena() external payable whenNotPaused {
        // can be paused in emergency
    }
}
```

### 5. Integer Safety
Solidity 0.8+ has built-in overflow/underflow protection. Do NOT use SafeMath (it's redundant). However:
- Use `uint256` for token amounts and financial math
- Use `uint8`/`uint16` for bounded values (gene traits) that are logically capped
- When dividing, always check for zero divisor

### 6. Pull Over Push for Payments
NEVER iterate and send funds. Store amounts owed and let users withdraw.

```solidity
// BAD — push pattern
for (uint i = 0; i < winners.length; i++) {
    payable(winners[i]).transfer(reward); // can fail, blocking everyone
}

// GOOD — pull pattern
mapping(address => uint256) public pendingRewards;

function claimReward() external nonReentrant {
    uint256 amount = pendingRewards[msg.sender];
    require(amount > 0, "Nothing to claim");
    pendingRewards[msg.sender] = 0;
    (bool ok, ) = msg.sender.call{value: amount}("");
    require(ok, "Transfer failed");
}
```

### 7. Gas DoS Protection
For loops over dynamic arrays, ALWAYS:
- Cap the maximum iterations
- Use `gasleft()` checks for breaking early
- Allow batched/continued execution

```solidity
uint256 constant MAX_BATCH = 20;

function processCreatures(uint256 start, uint256 count) external {
    uint256 end = start + count;
    if (end > creatures.length) end = creatures.length;
    require(end - start <= MAX_BATCH, "Batch too large");

    for (uint256 i = start; i < end; i++) {
        if (gasleft() < 50_000) break;
        _processCreature(i);
    }
}
```

## OpenZeppelin Import Paths

With Foundry, after running `forge install OpenZeppelin/openzeppelin-contracts`, set the remapping in `foundry.toml`:

```toml
remappings = ["@openzeppelin/=lib/openzeppelin-contracts/"]
```

Common imports:
```solidity
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {Pausable} from "@openzeppelin/contracts/utils/Pausable.sol";
```

## Security Checklist (Run Before Every Deployment)

- [ ] All value transfers protected by `nonReentrant`
- [ ] All functions follow checks-effects-interactions
- [ ] No unbounded loops without gas checks or batch limits
- [ ] Admin functions gated by `onlyOwner`
- [ ] Emergency pause implemented and tested
- [ ] No use of `tx.origin` for auth (use `msg.sender`)
- [ ] No use of `block.timestamp` for critical randomness (use `block.prevrandao`)
- [ ] All user inputs validated (non-zero, within bounds)
- [ ] Events emitted for all state changes
- [ ] No selfdestruct usage
