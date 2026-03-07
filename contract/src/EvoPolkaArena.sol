// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {
    ReentrancyGuard
} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {Pausable} from "@openzeppelin/contracts/utils/Pausable.sol";
import {CreatureLib} from "./libraries/CreatureLib.sol";

/// @title EvoPolkaArena
/// @notice Core orchestrator for the on-chain genetic evolution game on Polkadot Hub
contract EvoPolkaArena is ReentrancyGuard, Ownable, Pausable {
    using CreatureLib for CreatureLib.Creature;
    using CreatureLib for bytes32;

    enum ArenaState {
        LOBBY,
        ACTIVE,
        EVOLVING,
        FINISHED
    }

    struct Arena {
        uint256 id;
        ArenaState state;
        uint256 stakePerPlayer;
        uint256 totalPot;
        uint256 roundNumber;
        uint256 maxRounds;
        uint256 gridSize; // NxN grid
        uint256 creaturesPerPlayer;
        uint256 mutationRate; // basis points 0-10000
        uint256 lastRoundBlock;
        uint256 roundInterval; // blocks between rounds
    }

    uint256 public nextArenaId;
    uint256 public nextCreatureId;

    mapping(uint256 => Arena) public arenas;

    // arenaId => (creatureId => Creature)
    mapping(uint256 => mapping(uint256 => CreatureLib.Creature))
        public arenaCreatures;
    // arenaId => creatureIds active in arena
    mapping(uint256 => uint256[]) public arenaCreatureIds;

    // arenaId => player count
    mapping(uint256 => uint256) public arenaPlayerCount;
    // arenaId => player address array
    mapping(uint256 => address[]) public arenaPlayers;
    // arenaId => player => joined boolean
    mapping(uint256 => mapping(address => bool)) public hasJoined;

    // Events
    event ArenaCreated(uint256 indexed arenaId, address creator);
    event PlayerJoined(uint256 indexed arenaId, address player);
    event ArenaStarted(uint256 indexed arenaId);
    event CreatureBorn(
        uint256 indexed arenaId,
        uint256 creatureId,
        address owner,
        bytes32 genome
    );

    constructor() Ownable(msg.sender) {}

    /// @notice Create a new Evolution Arena
    function createArena(
        uint256 stakePerPlayer,
        uint256 maxRounds,
        uint256 gridSize,
        uint256 creaturesPerPlayer,
        uint256 mutationRate,
        uint256 roundInterval
    ) external whenNotPaused returns (uint256 arenaId) {
        require(maxRounds > 0 && maxRounds <= 1000, "Invalid maxRounds");
        require(gridSize >= 10 && gridSize <= 100, "Invalid gridSize");
        require(
            creaturesPerPlayer > 0 && creaturesPerPlayer <= 10,
            "Invalid creatures count"
        );
        require(mutationRate <= 10000, "Invalid mutationRate");

        arenaId = nextArenaId++;

        Arena storage newArena = arenas[arenaId];
        newArena.id = arenaId;
        newArena.state = ArenaState.LOBBY;
        newArena.stakePerPlayer = stakePerPlayer;
        newArena.maxRounds = maxRounds;
        newArena.gridSize = gridSize;
        newArena.creaturesPerPlayer = creaturesPerPlayer;
        newArena.mutationRate = mutationRate;
        newArena.roundInterval = roundInterval;

        emit ArenaCreated(arenaId, msg.sender);
    }

    /// @notice Players join and spawn their initial creatures
    function joinArena(
        uint256 arenaId
    ) external payable nonReentrant whenNotPaused {
        Arena storage arena = arenas[arenaId];
        require(arena.state == ArenaState.LOBBY, "Not in LOBBY state");
        require(msg.value == arena.stakePerPlayer, "Incorrect stake amount");
        require(!hasJoined[arenaId][msg.sender], "Already joined");

        hasJoined[arenaId][msg.sender] = true;
        arenaPlayers[arenaId].push(msg.sender);
        arenaPlayerCount[arenaId]++;
        arena.totalPot += msg.value;

        // Spawn initial random creatures
        for (uint256 i = 0; i < arena.creaturesPerPlayer; i++) {
            _spawnRandomCreature(arenaId, msg.sender);
        }

        emit PlayerJoined(arenaId, msg.sender);
    }

    /// @notice Start the arena once enough players have joined
    function startArena(uint256 arenaId) external {
        Arena storage arena = arenas[arenaId];
        require(arena.state == ArenaState.LOBBY, "Not in LOBBY state");
        require(arenaPlayerCount[arenaId] >= 2, "Need at least 2 players");
        // Only the first player (or creator pattern) can start for now
        require(
            arenaPlayers[arenaId][0] == msg.sender || owner() == msg.sender,
            "Not authorized to start"
        );

        arena.state = ArenaState.ACTIVE;
        arena.lastRoundBlock = block.number;

        emit ArenaStarted(arenaId);
    }

    /// @dev Spawns a new creature with a random base genome
    function _spawnRandomCreature(uint256 arenaId, address owner) internal {
        uint256 cId = nextCreatureId++;

        // Generate a random 32-byte genome using block.prevrandao
        bytes32 randomGenome = keccak256(
            abi.encodePacked(block.prevrandao, block.number, owner, cId)
        );

        (
            uint8 speed,
            uint8 strength,
            uint8 intel,
            uint8 agg,
            uint8 repro,
            uint8 def
        ) = CreatureLib.decodeGenome(randomGenome);

        // Normalize initial traits so creatures aren't hopelessly broken
        // Ensuring a minimum of 10 for each stat just to make them viable, capped at 255 natively through modulo logic if desired.
        speed = speed < 10 ? 10 : speed;
        strength = strength < 10 ? 10 : strength;
        intel = intel < 10 ? 10 : intel;
        agg = agg < 10 ? 10 : agg;
        repro = repro < 10 ? 10 : repro;
        def = def < 10 ? 10 : def;

        bytes32 normalizedGenome = CreatureLib.encodeGenome(
            randomGenome,
            speed,
            strength,
            intel,
            agg,
            repro,
            def
        );

        CreatureLib.Creature memory newCreature = CreatureLib.Creature({
            id: cId,
            owner: owner,
            speed: speed,
            strength: strength,
            intelligence: intel,
            aggression: agg,
            reproRate: repro,
            defense: def,
            energy: 100, // starting energy
            hp: 100, // starting hit points
            x: uint8(
                uint256(keccak256(abi.encode(randomGenome, "X"))) %
                    arenas[arenaId].gridSize
            ),
            y: uint8(
                uint256(keccak256(abi.encode(randomGenome, "Y"))) %
                    arenas[arenaId].gridSize
            ),
            generation: 1,
            alive: true,
            genome: normalizedGenome
        });

        arenaCreatures[arenaId][cId] = newCreature;
        arenaCreatureIds[arenaId].push(cId);

        emit CreatureBorn(arenaId, cId, owner, normalizedGenome);
    }
}
