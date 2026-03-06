---
name: foundry-polkadot
description: Foundry-Polkadot development patterns for Polkadot Hub PVM smart contracts using resolc compiler
---

# Foundry-Polkadot Development Skill

## Overview
This project uses **Foundry-Polkadot** to compile Solidity contracts to **PVM (PolkaVM / RISC-V)** bytecode via the `resolc` compiler, targeting **Polkadot Hub**.

## Critical PVM Differences from EVM

You MUST account for these when writing Solidity for PVM:

1. **No 63/64 gas rule** — All gas is forwarded on external calls. This means untrusted external calls can consume ALL remaining gas. Always use reentrancy guards and set explicit gas limits on `.call{}`.

2. **Contract instantiation by CODE HASH** — Contracts are deployed by uploading code first, then instantiating by hash. The `new Contract()` pattern works differently. Prefer factory patterns.

3. **Bytecode bloat (10-20x)** — `resolc` produces significantly larger bytecode than `solc`. Mitigations:
   - Split contracts into small libraries
   - Use external functions over public where possible
   - Minimize storage slot usage
   - Keep inheritance chains shallow

4. **Fixed heap memory** — Heap is not gas-metered but has a fixed size. Avoid large dynamic arrays in memory. Prefer storage iteration.

5. **Fixed stack size** — Avoid deeply nested function calls (>10 levels deep).

6. **No floating point** — Use only integer math. Basis points (uint256, 0-10000) for percentages.

## Network Configuration

```toml
# foundry.toml
[profile.default]
src = "src"
out = "out"
test = "test"
libs = ["lib"]
solc_version = "0.8.28"
optimizer = true
optimizer_runs = 200

[rpc_endpoints]
polkadot_testnet = "https://eth-rpc-testnet.polkadot.io/"
```

## Precompile Addresses

When calling precompiles, use these exact addresses:

| Precompile | Address | Purpose |
|-----------|---------|---------|
| System | `0x0000000000000000000000000000000000000900` | BLAKE2, sr25519, account queries, balance checks |
| XCM | `0x00000000000000000000000000000000000a0000` | Cross-chain messaging: execute, send, weighMessage |
| Staking V2 | `0x0000000000000000000000000000000000000805` | addStake, removeStake delegation |
| ERC20 | Mapped by asset ID (upper 32 bits) | Native asset ERC20 interface |

## Common Commands

```bash
# Build
forge build

# Test with verbose output
forge test -vvv

# Test specific contract
forge test --match-contract <TestName> -vvv

# Gas report
forge test --gas-report

# Deploy to Polkadot Hub testnet
forge create src/<Contract>.sol:<Contract> \
  --rpc-url https://eth-rpc-testnet.polkadot.io/ \
  --private-key $PRIVATE_KEY

# Deploy with constructor args
forge create src/<Contract>.sol:<Contract> \
  --rpc-url https://eth-rpc-testnet.polkadot.io/ \
  --private-key $PRIVATE_KEY \
  --constructor-args <arg1> <arg2>

# Read from deployed contract
cast call <ADDRESS> "functionName()" \
  --rpc-url https://eth-rpc-testnet.polkadot.io/

# Send transaction
cast send <ADDRESS> "functionName(uint256)" <value> \
  --rpc-url https://eth-rpc-testnet.polkadot.io/ \
  --private-key $PRIVATE_KEY

# Fork testnet for testing
forge test --fork-url https://eth-rpc-testnet.polkadot.io/
```

## Testnet Info

- **Faucet:** https://faucet.polkadot.io (select Polkadot Hub TestNet)
- **Token:** PAS (testnet DOT)
- **Block time:** ~6 seconds
- **RPC (Ethereum JSON-RPC):** https://eth-rpc-testnet.polkadot.io/

## Foundry Test Convention

- Test files go in `test/` with `.t.sol` extension
- Test contracts inherit from `forge-std/Test.sol`
- Test functions start with `test_` (expected pass) or `testFail_` (expected revert)
- Use `vm.prank()`, `vm.deal()`, `vm.warp()` for state manipulation
- Deployment scripts go in `script/` with `.s.sol` extension, inheriting `forge-std/Script.sol`
