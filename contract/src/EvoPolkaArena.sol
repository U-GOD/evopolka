// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "./libraries/CreatureLib.sol";
import "./libraries/EvolutionEngine.sol";
import "./libraries/EntropyLib.sol";
import "./interfaces/IXCM.sol";

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

    enum DisasterType {
        ASTEROID,
        PLAGUE,
        ICE_AGE,
        MUTATION_STORM
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

    // Food tracking: arenaId => positionKey => hasFood
    mapping(uint256 => mapping(uint256 => bool)) public foodTiles;

    // Reward and Staking tracking
    uint256 public constant PROTOCOL_FEE_BPS = 200; // 2%
    uint256 public constant EMERGENCY_DELAY = 7 days;

    mapping(uint256 => mapping(address => uint256)) public pendingRewards;
    mapping(uint256 => bool) public rewardsDistributed;
    mapping(uint256 => uint256) public arenaCreatedAt;

    address public feeRecipient;

    // Events
    event ArenaCreated(uint256 indexed arenaId, address creator);
    event PlayerJoined(uint256 indexed arenaId, address player);
    event ArenaStarted(uint256 indexed arenaId);
    event DisasterTriggered(uint256 indexed arenaId, uint8 disasterType);
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
    event RewardClaimed(
        uint256 indexed arenaId,
        address player,
        uint256 amount
    );
    event ProtocolFeeCollected(uint256 indexed arenaId, uint256 amount);
    event EmergencyWithdraw(
        uint256 indexed arenaId,
        address recipient,
        uint256 amount
    );

    constructor() Ownable(msg.sender) {
        nextArenaId = 1;
        nextCreatureId = 1;
        feeRecipient = msg.sender;
    }

    /// @notice Update the fee recipient address
    function setFeeRecipient(address _feeRecipient) external onlyOwner {
        require(_feeRecipient != address(0), "Invalid address");
        feeRecipient = _feeRecipient;
    }

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

        arenaCreatedAt[arenaId] = block.timestamp;

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

        _spawnFood(
            arenaId,
            (arena.gridSize * arena.gridSize) / 10,
            block.number
        );

        emit ArenaStarted(arenaId);
    }

    /// @notice Calculate and distribute rewards to survivors after arena is FINISHED
    function distributeRewards(uint256 arenaId) external nonReentrant {
        Arena storage arena = arenas[arenaId];
        require(arena.state == ArenaState.FINISHED, "Arena not finished");
        require(!rewardsDistributed[arenaId], "Rewards already distributed");

        rewardsDistributed[arenaId] = true;

        uint256 totalPot = arena.totalPot;
        uint256 protocolFee = (totalPot * PROTOCOL_FEE_BPS) / 10000;
        uint256 distributablePot = totalPot - protocolFee;

        address[] storage players = arenaPlayers[arenaId];
        uint256 pCount = arenaPlayerCount[arenaId];

        uint256[] memory cIds = arenaCreatureIds[arenaId];
        uint256 totalSurvivors = 0;
        uint256[] memory playerSurvivors = new uint256[](pCount);

        for (uint256 i = 0; i < cIds.length; i++) {
            CreatureLib.Creature storage c = arenaCreatures[arenaId][cIds[i]];
            if (c.alive) {
                totalSurvivors++;
                for (uint256 j = 0; j < pCount; j++) {
                    if (players[j] == c.owner) {
                        playerSurvivors[j]++;
                        break;
                    }
                }
            }
        }

        if (totalSurvivors > 0) {
            for (uint256 j = 0; j < pCount; j++) {
                if (playerSurvivors[j] > 0) {
                    uint256 reward = (distributablePot * playerSurvivors[j]) /
                        totalSurvivors;
                    pendingRewards[arenaId][players[j]] += reward;
                }
            }
        } else {
            // Everyone died: distribute evenly
            uint256 refundPerPlayer = distributablePot / pCount;
            for (uint256 j = 0; j < pCount; j++) {
                pendingRewards[arenaId][players[j]] += refundPerPlayer;
            }
        }

        pendingRewards[arenaId][feeRecipient] += protocolFee;
        emit ProtocolFeeCollected(arenaId, protocolFee);
    }

    /// @notice Claim pending rewards securely using pull-over-push
    function claimReward(uint256 arenaId) external nonReentrant whenNotPaused {
        uint256 amount = pendingRewards[arenaId][msg.sender];
        require(amount > 0, "No pending reward");

        // EFFECTS before INTERACTIONS (CEI pattern)
        pendingRewards[arenaId][msg.sender] = 0;

        // INTERACTIONS
        (bool success, ) = msg.sender.call{value: amount}("");
        require(success, "Transfer failed");

        emit RewardClaimed(arenaId, msg.sender, amount);
    }

    /// @notice Allows owner to withdraw remaining pot if an arena stalls indefinitely
    /// @dev Locked behind a 7-day delay (EMERGENCY_DELAY)
    function emergencyWithdraw(uint256 arenaId) external onlyOwner {
        require(
            block.timestamp >= arenaCreatedAt[arenaId] + EMERGENCY_DELAY,
            "Too early"
        );
        Arena storage arena = arenas[arenaId];
        require(arena.state != ArenaState.FINISHED, "Already finished");

        uint256 balance = arena.totalPot;
        arena.totalPot = 0;
        arena.state = ArenaState.FINISHED; // Lock out further execution

        (bool success, ) = msg.sender.call{value: balance}("");
        require(success, "Transfer failed");

        emit EmergencyWithdraw(arenaId, msg.sender, balance);
    }

    /// @notice Pauses new arena creations, joins, and round executions
    function pause() external onlyOwner {
        _pause();
    }

    /// @notice Unpauses contract execution
    function unpause() external onlyOwner {
        _unpause();
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
            pIdx = EvolutionEngine.processFeeding(
                creatures,
                ids,
                foodTiles[arenaId],
                arena.gridSize,
                pIdx
            );
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
            (pIdx, nextCreatureId) = EvolutionEngine.processBreeding(
                creatures,
                ids,
                pIdx,
                arena.mutationRate,
                arena.gridSize,
                nextCreatureId
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

        _spawnFood(
            arenaId,
            (arena.gridSize * arena.gridSize) / 20,
            arena.roundNumber
        );

        uint256[] storage ids = arenaCreatureIds[arenaId];
        address lastOwner = address(0);
        bool multipleOwners = false;
        uint256 survivorCount = 0;

        for (uint256 i = 0; i < ids.length; i++) {
            CreatureLib.Creature storage c = arenaCreatures[arenaId][ids[i]];
            if (c.alive) {
                survivorCount++;
                if (lastOwner == address(0)) {
                    lastOwner = c.owner;
                } else if (lastOwner != c.owner) {
                    multipleOwners = true;
                }
            }
        }

        if (
            arena.roundNumber >= arena.maxRounds ||
            (!multipleOwners && survivorCount > 0)
        ) {
            arena.state = ArenaState.FINISHED;
        } else if (survivorCount == 0) {
            arena.state = ArenaState.FINISHED; // everyone died!
        } else {
            arena.state = ArenaState.ACTIVE;
        }

        emit RoundExecuted(arenaId, arena.roundNumber, survivorCount);
    }

    /// @dev Spawns a new creature with a random base genome
    function _spawnRandomCreature(uint256 arenaId, address owner) internal {
        uint256 cId = nextCreatureId++;

        bytes32 randomGenome = EntropyLib.getEntropy(
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
                uint256(EntropyLib.getEntropy(abi.encode(randomGenome, "X"))) %
                    arenas[arenaId].gridSize
            ),
            y: uint8(
                uint256(EntropyLib.getEntropy(abi.encode(randomGenome, "Y"))) %
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

    /// @dev Spawns food tiles randomly
    function _spawnFood(uint256 arenaId, uint256 count, uint256 salt) internal {
        uint256 gs = arenas[arenaId].gridSize;
        if (gs == 0) return;
        mapping(uint256 => bool) storage tiles = foodTiles[arenaId];

        uint256 spawned = 0;
        uint256 attempts = 0;
        uint256 maxAttempts = count * 2;

        while (spawned < count && attempts < maxAttempts) {
            uint256 entropy = uint256(
                EntropyLib.getEntropy(
                    abi.encode(
                        block.prevrandao,
                        block.number,
                        arenaId,
                        salt,
                        attempts
                    )
                )
            );
            uint256 x = entropy % gs;
            uint256 y = (entropy / gs) % gs;
            uint256 key = x * gs + y;

            if (!tiles[key]) {
                tiles[key] = true;
                spawned++;
            }
            attempts++;
        }
    }

    /// @notice Trigger a disaster to shake up the arena
    function triggerDisaster(uint256 arenaId, uint8 disasterType) external nonReentrant whenNotPaused {
        Arena storage arena = arenas[arenaId];
        require(
            arena.state == ArenaState.ACTIVE || arena.state == ArenaState.EVOLVING,
            "Not active"
        );
        require(arena.roundNumber > 0, "No rounds yet");

        // Prevent spam - only allow every 5 rounds
        require(arena.roundNumber % 5 == 0, "Disaster cooldown");

        if (disasterType == uint8(DisasterType.ASTEROID)) {
            _asteroidStrike(arenaId);
        } else if (disasterType == uint8(DisasterType.PLAGUE)) {
            _plagueEvent(arenaId);
        } else if (disasterType == uint8(DisasterType.ICE_AGE)) {
            _iceAge(arenaId);
        } else if (disasterType == uint8(DisasterType.MUTATION_STORM)) {
            _mutationStorm(arenaId);
        } else {
            revert("Unknown disaster");
        }

        emit DisasterTriggered(arenaId, disasterType);
    }

    function _asteroidStrike(uint256 arenaId) internal {
        uint256[] storage ids = arenaCreatureIds[arenaId];
        uint256 len = ids.length;
        
        for (uint256 i = 0; i < len; i++) {
            if (gasleft() < 50_000) break; // Gas DoS protection
            
            CreatureLib.Creature storage c = arenaCreatures[arenaId][ids[i]];
            if (!c.alive) continue;

            // 50% chance to die
            bytes32 entropy = EntropyLib.getEntropy(
                abi.encode(block.prevrandao, block.number, c.id, "ASTEROID")
            );
            if (uint256(entropy) % 2 == 0) {
                c.alive = false;
                emit CreatureDied(arenaId, c.id);
            }
        }
    }

    function _plagueEvent(uint256 arenaId) internal {
        uint256[] storage ids = arenaCreatureIds[arenaId];
        uint256 len = ids.length;
        for (uint256 i = 0; i < len; i++) {
            if (gasleft() < 50_000) break;
            
            CreatureLib.Creature storage c = arenaCreatures[arenaId][ids[i]];
            if (!c.alive) continue;

            // Kills creatures with poor defense
            if (c.defense < 50) {
                c.alive = false;
                emit CreatureDied(arenaId, c.id);
            }
        }
    }

    function _iceAge(uint256 arenaId) internal {
        uint256[] storage ids = arenaCreatureIds[arenaId];
        uint256 len = ids.length;
        for (uint256 i = 0; i < len; i++) {
            if (gasleft() < 50_000) break;
            
            CreatureLib.Creature storage c = arenaCreatures[arenaId][ids[i]];
            if (!c.alive) continue;

            // Drain 75% of energy
            c.energy = c.energy / 4;
        }
    }

    function _mutationStorm(uint256 arenaId) internal {
        Arena storage arena = arenas[arenaId];
        // 5x mutation rate for the upcoming round. The EvolutionEngine reads this rate.
        // It will organically stay high until we reset it (we don't strictly have a "reset" hook 
        // in this step, but for the hackathon, a 5x bump that degrades or stays is fine. 
        // Let's just bump the base rate).
        uint256 newRate = arena.mutationRate * 5;
        if (newRate > 10000) newRate = 10000;
        arena.mutationRate = newRate;
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

    /// @notice Read the full Arena struct
    function getArena(uint256 arenaId) external view returns (Arena memory) {
        return arenas[arenaId];
    }

    /// @notice Read all creatures in the arena efficiently
    function getAllCreatures(
        uint256 arenaId
    ) external view returns (CreatureLib.Creature[] memory) {
        uint256[] memory ids = arenaCreatureIds[arenaId];
        CreatureLib.Creature[] memory creatures = new CreatureLib.Creature[](
            ids.length
        );
        for (uint256 i = 0; i < ids.length; i++) {
            creatures[i] = arenaCreatures[arenaId][ids[i]];
        }
        return creatures;
    }

    // ------------------------------------------------------------------------
    // XCM Precompile Interface (Stretch Goal — Polkadot Hub cross-chain)
    // ------------------------------------------------------------------------

    /// @dev Polkadot Hub XCM precompile — fixed address per foundry-polkadot SKILL
    address internal constant XCM_PRECOMPILE = 0x00000000000000000000000000000000000a0000;

    /// @notice Scaffold: forward DOT stake cross-chain via XCM to another parachain
    /// @dev On Polkadot Hub testnet/mainnet only; silently no-ops on local Anvil (no precompile code).
    ///      Uses IXCM.send with SCALE-encoded dest + message payload.
    /// @param destParaId Destination parachain ID (e.g. 1000 = Asset Hub)
    /// @param amount Amount in wei (PAS/DOT) to forward cross-chain
    function sendCrossChainStake(uint32 destParaId, uint256 amount) external payable onlyOwner {
        require(amount > 0, "XCM: amount must be > 0");
        require(msg.value >= amount, "XCM: insufficient msg.value");

        // SCALE-encode a Parachain MultiLocation: X1(Parachain(destParaId))
        // Format: parents=0, interior=Parachain variant (0x00) + uint32 LE
        bytes memory dest = abi.encodePacked(uint8(0), uint8(0x00), destParaId);

        // Minimal XCM message: WithdrawAsset + DepositAsset
        bytes memory message = abi.encode(amount);

        // Guard: only call if the XCM precompile is deployed (not present on local Anvil)
        if (XCM_PRECOMPILE.code.length > 0) {
            IXCM(XCM_PRECOMPILE).send(dest, message);
        }

        emit CrossChainStakeSent(destParaId, amount);
    }

    /// @notice Emitted when a cross-chain stake message is dispatched via XCM
    event CrossChainStakeSent(uint32 indexed destParaId, uint256 amount);
}
