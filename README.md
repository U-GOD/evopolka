<p align="center">
  <h1 align="center">EvoPolka</h1>
  <p align="center">
    On-Chain Artificial Life Evolution Arena on Polkadot Hub
    <br />
    <strong>Polkadot Solidity Hackathon 2026 &mdash; PVM Track</strong>
    <br />
    <br />
    <a href="https://docs.polkadot.com/develop/smart-contracts/">Polkadot Docs</a>
    &middot;
    <a href="https://faucet.polkadot.io">Testnet Faucet</a>
    &middot;
    <a href="https://discord.gg/WWgzkDfPQF">OpenGuild Discord</a>
  </p>
</p>

<br />

## About

EvoPolka is a fully on-chain genetic algorithm evolution simulator deployed on Polkadot Hub using the Polkadot Virtual Machine (PVM). Players stake DOT as "energy" to enter an arena. The smart contract spawns AI creatures with genetic traits — speed, strength, intelligence, aggression, reproduction rate, and defense — encoded in a compact 32-byte genome. Every round, the system executes a full evolution cycle: movement, combat, feeding, breeding with genetic crossover and mutation, and fitness-based natural selection.

Survivors inherit the staked pot. Everything is 100% on-chain and verifiable. A real-time dashboard renders hundreds of colorful creatures evolving before your eyes — a chaotic digital petri dish where artificial life meets real economic stakes.

No off-chain oracles. No trusted servers. Just pure, auditable evolution running on Polkadot's next-generation virtual machine.

## Why This Exists

On-chain AI agent evolution and verifiable compute are among the most active narratives in 2026 (DePIN, AgentFi), but all simulations run off-chain or in untrusted environments. There is no way to verify that an evolution run was fair, that mutations were random, or that selection was unbiased.

EvoPolka turns Polkadot Hub into a public, auditable evolution laboratory. Every genetic operation — every mutation, every crossover, every death — is a verifiable on-chain event. This is the first fully on-chain genetic algorithm evolution arena on any major blockchain.

## Features

- **Verifiable Genetic Algorithms** — Mutation, crossover, and fitness scoring executed entirely in Solidity on PVM. Every operation emits events for full auditability.
- **Real Economic Stakes** — Players stake native DOT tokens. Winners are determined by which players' creatures survive the longest and claim a proportional share of the pot.
- **Arena System** — Create or join arenas with configurable parameters: mutation rate, grid size, number of creatures per player, round count, and stake amount.
- **Five-Phase Evolution Rounds** — Each round executes movement, combat, feeding, breeding, and culling in sequence. Batched execution handles gas limits gracefully.
- **Disaster Events** — Asteroid strikes, plagues, ice ages, and mutation storms shake up the evolutionary landscape, preventing stale equilibria.
- **Precompile Integration** — Uses Polkadot Hub's native System precompile for BLAKE2 hashing (entropy) and account operations.
- **Real-Time Visualization** — React + Canvas frontend renders creatures as colored sprites on a grid, with particle effects for combat, breeding, and death. Colors are derived from each creature's genome.
- **Cross-Chain Ready** — Architecture supports XCM integration for cross-parachain arena pots and multi-chain tournaments.

## Tech Stack

| Layer | Technology |
|-------|-----------|
| Smart Contracts | Solidity 0.8.28 |
| Virtual Machine | PVM (PolkaVM / RISC-V) via `pallet-revive` |
| Compiler | `resolc` (Solidity -> YUL -> LLVM IR -> RISC-V) |
| Dev Framework | Foundry-Polkadot (`forge`, `cast`, `anvil`) |
| Dependencies | OpenZeppelin Contracts (ReentrancyGuard, Ownable, Pausable) |
| Frontend | React + TypeScript + Vite + HTML5 Canvas |
| Chain Interaction | ethers.js v6 via Ethereum JSON-RPC |
| Network | Polkadot Hub (Testnet / Mainnet) |

## Architecture

```
                         ┌──────────────────────────────┐
                         │       Frontend (React)       │
                         │   Canvas Renderer + ethers   │
                         └──────────┬───────────────────┘
                                    │ JSON-RPC
                         ┌──────────▼───────────────────┐
                         │    Polkadot Hub (PVM)         │
                         │                               │
                         │  EvoPolkaArena.sol             │
                         │    │                           │
                         │    ├── CreatureLib.sol          │
                         │    ├── EvolutionEngine.sol      │
                         │    └── RewardDistributor.sol    │
                         │                               │
                         │  Precompiles                   │
                         │    ├── System (0x...0900)       │
                         │    └── XCM    (0x...0a0000)     │
                         └───────────────────────────────┘
```

**EvoPolkaArena.sol** is the main orchestrator contract. It manages arena lifecycle (creation, joining, starting, finishing), delegates genetic operations to **CreatureLib.sol**, evolution logic to **EvolutionEngine.sol**, and reward distribution to **RewardDistributor.sol**.

## Project Structure

```
evopolka/
├── src/                          # Solidity contracts
│   ├── EvoPolkaArena.sol         # Main orchestrator
│   ├── libraries/
│   │   ├── CreatureLib.sol       # Creature struct + genetics
│   │   ├── EvolutionEngine.sol   # Movement, combat, breeding
│   │   └── RewardDistributor.sol # Staking + reward logic
│   └── interfaces/
│       ├── ISystemPrecompile.sol  # System precompile interface
│       └── IXCMPrecompile.sol     # XCM precompile interface
├── test/                         # Forge tests
│   ├── CreatureLib.t.sol
│   ├── EvoPolkaArena.t.sol
│   ├── EvolutionEngine.t.sol
│   └── Integration.t.sol
├── script/                       # Deployment scripts
│   ├── Deploy.s.sol
│   └── SeedArena.s.sol
├── frontend/                     # React + Canvas dashboard
│   ├── src/
│   └── public/
├── foundry.toml
└── README.md
```

## Prerequisites

- [Foundry-Polkadot](https://github.com/nickytonline/foundryup-polkadot) (forge, cast, anvil with resolc support)
- [Node.js](https://nodejs.org/) >= 18 (for frontend)
- [MetaMask](https://metamask.io/) or compatible wallet
- WSL or Git Bash (Windows users -- foundryup-polkadot does not support PowerShell)

## Getting Started

### 1. Install Foundry-Polkadot

```bash
curl -L https://raw.githubusercontent.com/nickytonline/foundryup-polkadot/main/install.sh | bash
foundryup-polkadot
```

### 2. Clone and Build

```bash
git clone https://github.com/your-username/evopolka.git
cd evopolka
forge install
forge build
```

### 3. Run Tests

```bash
forge test -vvv
```

### 4. Configure Wallet

Add Polkadot Hub Testnet to MetaMask:

| Field | Value |
|-------|-------|
| Network Name | Polkadot Hub Testnet |
| RPC URL | `https://eth-rpc-testnet.polkadot.io/` |
| Currency Symbol | PAS |

Get testnet tokens at [faucet.polkadot.io](https://faucet.polkadot.io).

### 5. Deploy to Testnet

```bash
forge create src/EvoPolkaArena.sol:EvoPolkaArena \
  --rpc-url https://eth-rpc-testnet.polkadot.io/ \
  --private-key $PRIVATE_KEY
```

### 6. Launch Frontend

```bash
cd frontend
npm install
npm run dev
```

## How It Works

### Creature Genetics

Each creature carries a 32-byte genome encoding six core traits:

| Trait | Range | Effect |
|-------|-------|--------|
| Speed | 0-255 | Tiles moved per round |
| Strength | 0-255 | Attack power in combat |
| Intelligence | 0-255 | Efficiency at foraging food |
| Aggression | 0-255 | Likelihood of initiating combat |
| Reproduction Rate | 0-255 | Chance of breeding when energy is sufficient |
| Defense | 0-255 | Damage reduction in combat |

### Evolution Round

Each call to `runEvolutionRound()` executes five phases:

1. **Movement** — Creatures navigate the grid toward food or weaker targets. Speed determines distance.
2. **Combat** — Creatures sharing a tile fight. Strength vs. defense, with aggression determining who initiates. Losers take HP damage; at zero HP, they die and the attacker absorbs their energy.
3. **Feeding** — Creatures on food tiles gain energy proportional to intelligence. Food respawns semi-randomly.
4. **Breeding** — The top 25% by fitness reproduce via single-point crossover of parent genomes, with random bit-flip mutations at a configurable rate.
5. **Culling** — The bottom 20% by fitness are removed. Zero-energy creatures die.

### Arena Lifecycle

```
CREATE  ->  LOBBY  ->  ACTIVE  ->  EVOLVING (rounds)  ->  FINISHED
  |          |          |              |                    |
  |       Players     Arena         Evolution           Winners
  |       join &      starts        rounds run          claim
  |       stake DOT                                     rewards
```

### Rewards

When an arena finishes, the staked pot is distributed:
- 98% split proportionally among surviving creatures' owners
- 2% protocol fee for sustainability

## PVM Track Categories

EvoPolka targets all three PVM track categories:

| Category | How We Hit It |
|----------|--------------|
| PVM-experiments | Solidity compiled to PVM via resolc; architecture ready for Rust GA engine integration |
| Applications using Polkadot native assets | DOT staked as arena entry fee and distributed as rewards |
| Accessing native functionality via precompiles | System precompile for BLAKE2 entropy; XCM precompile for cross-chain arenas |

## Security Considerations

This is a hackathon project. While we follow best practices, it has not undergone a formal audit.

- ReentrancyGuard on all value transfers
- Checks-effects-interactions pattern throughout
- Overflow protection via Solidity 0.8+ built-in checks
- Access control on privileged operations
- No external oracle dependency (randomness from `block.prevrandao`)
- Emergency pause via OpenZeppelin Pausable
- Maximum creature cap per arena to prevent gas DoS
- Gas limit checks in evolution loops with batched execution

## Roadmap

- **v1.0** — Hackathon MVP: Core arena, evolution engine, staking, Canvas frontend
- **v1.1** — Rust GA engine deployed as separate PVM contract for higher performance
- **v1.2** — NFT creatures (ERC-721) with persistent genomes across arenas
- **v2.0** — XCM cross-chain tournaments: multi-parachain arena pots
- **v2.1** — AI Agent SDK: plug in custom strategies that compete in arenas
- **v3.0** — Governance: community votes on evolution parameters, new trait types

## Resources

| Resource | Link |
|----------|------|
| Polkadot Developer Docs | [docs.polkadot.com](https://docs.polkadot.com/develop/smart-contracts/) |
| Foundry-Polkadot | [GitHub](https://github.com/nickytonline/foundryup-polkadot) |
| OpenGuild Codecamp | [codecamp.openguild.wtf](https://codecamp.openguild.wtf) |
| Builders Hub | [build.openguild.wtf](https://build.openguild.wtf/hackathon-resources) |
| Polkadot Faucet | [faucet.polkadot.io](https://faucet.polkadot.io) |

## License

This project is licensed under the MIT License. See [LICENSE](LICENSE) for details.

---

<p align="center">
  Built with ❤️ for the Polkadot Solidity Hackathon 2026 — powered by PVM
</p>
