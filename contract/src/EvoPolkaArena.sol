// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {
    ReentrancyGuard
} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {Pausable} from "@openzeppelin/contracts/utils/Pausable.sol";
import {CreatureLib} from "./libraries/CreatureLib.sol";
import {EvolutionEngine} from "./libraries/EvolutionEngine.sol";

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
        uint256 gridSize;
        uint256 creaturesPerPlayer;
        uint256 mutationRate;
        uint256 lastRoundBlock;
        uint256 roundInterval;
    }

    uint256 public nextArenaId;
    uint256 public nextCreatureId;

    mapping(uint256 => Arena) public arenas;

    mapping(uint256 => mapping(uint256 => CreatureLib.Creature))
        public arenaCreatures;
    mapping(uint256 => uint256[]) public arenaCreatureIds;

    mapping(uint256 => uint256) public arenaPlayerCount;
    mapping(uint256 => address[]) public arenaPlayers;
    mapping(uint256 => mapping(address => bool)) public hasJoined;

    // Phase tracking
    mapping(uint256 => uint8) public currentPhase;
    mapping(uint256 => uint256) public processedIndex;

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
    event RoundExecuted(
        uint256 indexed arenaId,
        uint256 round,
        uint256 survivors
    );
    event RoundPartial(
        uint256 indexed arenaId,
        uint256 round,
        uint256 processed
    );
    event CreatureDied(uint256 indexed arenaId, uint256 creatureId);
    event CombatOccurred(
        uint256 indexed arenaId,
        uint256 attacker,
        uint256 defender,
        bool attackerWon
    );
    event BreedingOccurred(
        uint256 indexed arenaId,
        uint256 parent1,
        uint256 parent2,
        uint256 child
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
        require(
            arenaPlayers[arenaId][0] == msg.sender || owner() == msg.sender,
            "Not authorized to start"
        );

        arena.state = ArenaState.ACTIVE;
        arena.lastRoundBlock = block.number;

        emit ArenaStarted(arenaId);
    }

    /// @notice Trigger a new evolution round if rules allow
    function runEvolutionRound(
        uint256 arenaId
    ) external whenNotPaused nonReentrant {
        Arena storage arena = arenas[arenaId];
        require(arena.state == ArenaState.ACTIVE, "Not in ACTIVE state");
        require(
            block.number >= arena.lastRoundBlock + arena.roundInterval,
            "Too soon to execute"
        );

        arena.state = ArenaState.EVOLVING;
        currentPhase[arenaId] = EvolutionEngine.PHASE_MOVEMENT;
        processedIndex[arenaId] = 0;

        _processPhases(arenaId);
    }

    /// @notice Continue a partially executed round if it ran out of gas
    function continueRound(
        uint256 arenaId
    ) external whenNotPaused nonReentrant {
        Arena storage arena = arenas[arenaId];
        require(arena.state == ArenaState.EVOLVING, "Not in EVOLVING state");

        _processPhases(arenaId);
    }

    /// @dev Internal delegator to handle phase state machine
    function _processPhases(uint256 arenaId) internal {
        Arena storage arena = arenas[arenaId];
        uint8 phase = currentPhase[arenaId];
        uint256 pIdx = processedIndex[arenaId];

        mapping(uint256 => CreatureLib.Creature)
            storage creatures = arenaCreatures[arenaId];
        uint256[] storage ids = arenaCreatureIds[arenaId];

        if (phase == EvolutionEngine.PHASE_MOVEMENT) {
            pIdx = EvolutionEngine.processMovement(
                creatures,
                ids,
                arena.gridSize,
                pIdx,
                arena.roundNumber
            );
            if (pIdx == 0) {
                phase = EvolutionEngine.PHASE_COMBAT;
            } else {
                processedIndex[arenaId] = pIdx;
                emit RoundPartial(arenaId, arena.roundNumber, pIdx);
                return;
            }
        }

        if (phase == EvolutionEngine.PHASE_COMBAT) {
            pIdx = EvolutionEngine.processCombat(creatures, ids, pIdx);
            if (pIdx == 0) {
                phase = EvolutionEngine.PHASE_FEEDING;
            } else {
                currentPhase[arenaId] = phase;
                processedIndex[arenaId] = pIdx;
                emit RoundPartial(arenaId, arena.roundNumber, pIdx);
                return;
            }
        }

        if (phase == EvolutionEngine.PHASE_FEEDING) {
            pIdx = EvolutionEngine.processFeeding(creatures, ids, pIdx);
            if (pIdx == 0) {
                phase = EvolutionEngine.PHASE_BREEDING;
            } else {
                currentPhase[arenaId] = phase;
                processedIndex[arenaId] = pIdx;
                emit RoundPartial(arenaId, arena.roundNumber, pIdx);
                return;
            }
        }

        if (phase == EvolutionEngine.PHASE_BREEDING) {
            pIdx = EvolutionEngine.processBreeding(
                creatures,
                ids,
                pIdx,
                arena.mutationRate,
                arena.gridSize
            );
            if (pIdx == 0) {
                phase = EvolutionEngine.PHASE_CULLING;
            } else {
                currentPhase[arenaId] = phase;
                processedIndex[arenaId] = pIdx;
                emit RoundPartial(arenaId, arena.roundNumber, pIdx);
                return;
            }
        }

        if (phase == EvolutionEngine.PHASE_CULLING) {
            pIdx = EvolutionEngine.processCulling(creatures, ids, pIdx);
            if (pIdx == 0) {
                _finalizeRound(arenaId);
            } else {
                currentPhase[arenaId] = phase;
                processedIndex[arenaId] = pIdx;
                emit RoundPartial(arenaId, arena.roundNumber, pIdx);
                return;
            }
        }
    }

    /// @dev End the round and check for arena finish conditions
    function _finalizeRound(uint256 arenaId) internal {
        Arena storage arena = arenas[arenaId];
        arena.roundNumber++;
        arena.lastRoundBlock = block.number;
        currentPhase[arenaId] = EvolutionEngine.PHASE_NONE;
        processedIndex[arenaId] = 0;

        if (arena.roundNumber >= arena.maxRounds) {
            arena.state = ArenaState.FINISHED;
        } else {
            arena.state = ArenaState.ACTIVE;
        }

        emit RoundExecuted(
            arenaId,
            arena.roundNumber,
            arenaCreatureIds[arenaId].length
        );
    }

    /// @dev Spawns a new creature with a random base genome
    function _spawnRandomCreature(uint256 arenaId, address owner) internal {
        uint256 cId = nextCreatureId++;

        bytes32 randomGenome = keccak256(
            abi.encode(block.prevrandao, block.number, owner, cId)
        );

        (
            uint8 speed,
            uint8 strength,
            uint8 intel,
            uint8 agg,
            uint8 repro,
            uint8 def
        ) = CreatureLib.decodeGenome(randomGenome);

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
            energy: 100,
            hp: 100,
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

    /// @notice Read a full creature struct for a given arena and creature ID
    function getCreature(
        uint256 arenaId,
        uint256 creatureId
    ) external view returns (CreatureLib.Creature memory) {
        return arenaCreatures[arenaId][creatureId];
    }

    /// @notice Read the creature ID list for a given arena
    function getCreatureIds(
        uint256 arenaId
    ) external view returns (uint256[] memory) {
        return arenaCreatureIds[arenaId];
    }
}
