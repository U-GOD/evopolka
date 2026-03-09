export const arenaAbi = [
  {
    "type": "constructor",
    "inputs": [],
    "stateMutability": "nonpayable"
  },
  {
    "type": "function",
    "name": "EMERGENCY_DELAY",
    "inputs": [],
    "outputs": [
      {
        "name": "",
        "type": "uint256",
        "internalType": "uint256"
      }
    ],
    "stateMutability": "view"
  },
  {
    "type": "function",
    "name": "PROTOCOL_FEE_BPS",
    "inputs": [],
    "outputs": [
      {
        "name": "",
        "type": "uint256",
        "internalType": "uint256"
      }
    ],
    "stateMutability": "view"
  },
  {
    "type": "function",
    "name": "arenaCreatedAt",
    "inputs": [
      {
        "name": "",
        "type": "uint256",
        "internalType": "uint256"
      }
    ],
    "outputs": [
      {
        "name": "",
        "type": "uint256",
        "internalType": "uint256"
      }
    ],
    "stateMutability": "view"
  },
  {
    "type": "function",
    "name": "arenaCreatureIds",
    "inputs": [
      {
        "name": "",
        "type": "uint256",
        "internalType": "uint256"
      },
      {
        "name": "",
        "type": "uint256",
        "internalType": "uint256"
      }
    ],
    "outputs": [
      {
        "name": "",
        "type": "uint256",
        "internalType": "uint256"
      }
    ],
    "stateMutability": "view"
  },
  {
    "type": "function",
    "name": "arenaCreatures",
    "inputs": [
      {
        "name": "",
        "type": "uint256",
        "internalType": "uint256"
      },
      {
        "name": "",
        "type": "uint256",
        "internalType": "uint256"
      }
    ],
    "outputs": [
      {
        "name": "id",
        "type": "uint256",
        "internalType": "uint256"
      },
      {
        "name": "owner",
        "type": "address",
        "internalType": "address"
      },
      {
        "name": "speed",
        "type": "uint8",
        "internalType": "uint8"
      },
      {
        "name": "strength",
        "type": "uint8",
        "internalType": "uint8"
      },
      {
        "name": "intelligence",
        "type": "uint8",
        "internalType": "uint8"
      },
      {
        "name": "aggression",
        "type": "uint8",
        "internalType": "uint8"
      },
      {
        "name": "reproRate",
        "type": "uint8",
        "internalType": "uint8"
      },
      {
        "name": "defense",
        "type": "uint8",
        "internalType": "uint8"
      },
      {
        "name": "energy",
        "type": "uint16",
        "internalType": "uint16"
      },
      {
        "name": "hp",
        "type": "uint16",
        "internalType": "uint16"
      },
      {
        "name": "x",
        "type": "uint8",
        "internalType": "uint8"
      },
      {
        "name": "y",
        "type": "uint8",
        "internalType": "uint8"
      },
      {
        "name": "generation",
        "type": "uint32",
        "internalType": "uint32"
      },
      {
        "name": "alive",
        "type": "bool",
        "internalType": "bool"
      },
      {
        "name": "genome",
        "type": "bytes32",
        "internalType": "bytes32"
      }
    ],
    "stateMutability": "view"
  },
  {
    "type": "function",
    "name": "arenaPlayerCount",
    "inputs": [
      {
        "name": "",
        "type": "uint256",
        "internalType": "uint256"
      }
    ],
    "outputs": [
      {
        "name": "",
        "type": "uint256",
        "internalType": "uint256"
      }
    ],
    "stateMutability": "view"
  },
  {
    "type": "function",
    "name": "arenaPlayers",
    "inputs": [
      {
        "name": "",
        "type": "uint256",
        "internalType": "uint256"
      },
      {
        "name": "",
        "type": "uint256",
        "internalType": "uint256"
      }
    ],
    "outputs": [
      {
        "name": "",
        "type": "address",
        "internalType": "address"
      }
    ],
    "stateMutability": "view"
  },
  {
    "type": "function",
    "name": "arenas",
    "inputs": [
      {
        "name": "",
        "type": "uint256",
        "internalType": "uint256"
      }
    ],
    "outputs": [
      {
        "name": "id",
        "type": "uint256",
        "internalType": "uint256"
      },
      {
        "name": "state",
        "type": "uint8",
        "internalType": "enum EvoPolkaArena.ArenaState"
      },
      {
        "name": "stakePerPlayer",
        "type": "uint256",
        "internalType": "uint256"
      },
      {
        "name": "totalPot",
        "type": "uint256",
        "internalType": "uint256"
      },
      {
        "name": "roundNumber",
        "type": "uint256",
        "internalType": "uint256"
      },
      {
        "name": "maxRounds",
        "type": "uint256",
        "internalType": "uint256"
      },
      {
        "name": "gridSize",
        "type": "uint256",
        "internalType": "uint256"
      },
      {
        "name": "creaturesPerPlayer",
        "type": "uint256",
        "internalType": "uint256"
      },
      {
        "name": "mutationRate",
        "type": "uint256",
        "internalType": "uint256"
      },
      {
        "name": "lastRoundBlock",
        "type": "uint256",
        "internalType": "uint256"
      },
      {
        "name": "roundInterval",
        "type": "uint256",
        "internalType": "uint256"
      }
    ],
    "stateMutability": "view"
  },
  {
    "type": "function",
    "name": "claimReward",
    "inputs": [
      {
        "name": "arenaId",
        "type": "uint256",
        "internalType": "uint256"
      }
    ],
    "outputs": [],
    "stateMutability": "nonpayable"
  },
  {
    "type": "function",
    "name": "continueRound",
    "inputs": [
      {
        "name": "arenaId",
        "type": "uint256",
        "internalType": "uint256"
      }
    ],
    "outputs": [],
    "stateMutability": "nonpayable"
  },
  {
    "type": "function",
    "name": "createArena",
    "inputs": [
      {
        "name": "stakePerPlayer",
        "type": "uint256",
        "internalType": "uint256"
      },
      {
        "name": "maxRounds",
        "type": "uint256",
        "internalType": "uint256"
      },
      {
        "name": "gridSize",
        "type": "uint256",
        "internalType": "uint256"
      },
      {
        "name": "creaturesPerPlayer",
        "type": "uint256",
        "internalType": "uint256"
      },
      {
        "name": "mutationRate",
        "type": "uint256",
        "internalType": "uint256"
      },
      {
        "name": "roundInterval",
        "type": "uint256",
        "internalType": "uint256"
      }
    ],
    "outputs": [
      {
        "name": "arenaId",
        "type": "uint256",
        "internalType": "uint256"
      }
    ],
    "stateMutability": "nonpayable"
  },
  {
    "type": "function",
    "name": "currentPhase",
    "inputs": [
      {
        "name": "",
        "type": "uint256",
        "internalType": "uint256"
      }
    ],
    "outputs": [
      {
        "name": "",
        "type": "uint8",
        "internalType": "uint8"
      }
    ],
    "stateMutability": "view"
  },
  {
    "type": "function",
    "name": "distributeRewards",
    "inputs": [
      {
        "name": "arenaId",
        "type": "uint256",
        "internalType": "uint256"
      }
    ],
    "outputs": [],
    "stateMutability": "nonpayable"
  },
  {
    "type": "function",
    "name": "emergencyWithdraw",
    "inputs": [
      {
        "name": "arenaId",
        "type": "uint256",
        "internalType": "uint256"
      }
    ],
    "outputs": [],
    "stateMutability": "nonpayable"
  },
  {
    "type": "function",
    "name": "feeRecipient",
    "inputs": [],
    "outputs": [
      {
        "name": "",
        "type": "address",
        "internalType": "address"
      }
    ],
    "stateMutability": "view"
  },
  {
    "type": "function",
    "name": "foodTiles",
    "inputs": [
      {
        "name": "",
        "type": "uint256",
        "internalType": "uint256"
      },
      {
        "name": "",
        "type": "uint256",
        "internalType": "uint256"
      }
    ],
    "outputs": [
      {
        "name": "",
        "type": "bool",
        "internalType": "bool"
      }
    ],
    "stateMutability": "view"
  },
  {
    "type": "function",
    "name": "getCreature",
    "inputs": [
      {
        "name": "arenaId",
        "type": "uint256",
        "internalType": "uint256"
      },
      {
        "name": "creatureId",
        "type": "uint256",
        "internalType": "uint256"
      }
    ],
    "outputs": [
      {
        "name": "",
        "type": "tuple",
        "internalType": "struct CreatureLib.Creature",
        "components": [
          {
            "name": "id",
            "type": "uint256",
            "internalType": "uint256"
          },
          {
            "name": "owner",
            "type": "address",
            "internalType": "address"
          },
          {
            "name": "speed",
            "type": "uint8",
            "internalType": "uint8"
          },
          {
            "name": "strength",
            "type": "uint8",
            "internalType": "uint8"
          },
          {
            "name": "intelligence",
            "type": "uint8",
            "internalType": "uint8"
          },
          {
            "name": "aggression",
            "type": "uint8",
            "internalType": "uint8"
          },
          {
            "name": "reproRate",
            "type": "uint8",
            "internalType": "uint8"
          },
          {
            "name": "defense",
            "type": "uint8",
            "internalType": "uint8"
          },
          {
            "name": "energy",
            "type": "uint16",
            "internalType": "uint16"
          },
          {
            "name": "hp",
            "type": "uint16",
            "internalType": "uint16"
          },
          {
            "name": "x",
            "type": "uint8",
            "internalType": "uint8"
          },
          {
            "name": "y",
            "type": "uint8",
            "internalType": "uint8"
          },
          {
            "name": "generation",
            "type": "uint32",
            "internalType": "uint32"
          },
          {
            "name": "alive",
            "type": "bool",
            "internalType": "bool"
          },
          {
            "name": "genome",
            "type": "bytes32",
            "internalType": "bytes32"
          }
        ]
      }
    ],
    "stateMutability": "view"
  },
  {
    "type": "function",
    "name": "getCreatureIds",
    "inputs": [
      {
        "name": "arenaId",
        "type": "uint256",
        "internalType": "uint256"
      }
    ],
    "outputs": [
      {
        "name": "",
        "type": "uint256[]",
        "internalType": "uint256[]"
      }
    ],
    "stateMutability": "view"
  },
  {
    "type": "function",
    "name": "getArena",
    "inputs": [
      {
        "name": "arenaId",
        "type": "uint256",
        "internalType": "uint256"
      }
    ],
    "outputs": [
      {
        "name": "",
        "type": "tuple",
        "internalType": "struct EvoPolkaArena.Arena",
        "components": [
          { "name": "id", "type": "uint256", "internalType": "uint256" },
          { "name": "state", "type": "uint8", "internalType": "enum EvoPolkaArena.ArenaState" },
          { "name": "stakePerPlayer", "type": "uint256", "internalType": "uint256" },
          { "name": "totalPot", "type": "uint256", "internalType": "uint256" },
          { "name": "roundNumber", "type": "uint256", "internalType": "uint256" },
          { "name": "maxRounds", "type": "uint256", "internalType": "uint256" },
          { "name": "gridSize", "type": "uint256", "internalType": "uint256" },
          { "name": "creaturesPerPlayer", "type": "uint256", "internalType": "uint256" },
          { "name": "mutationRate", "type": "uint256", "internalType": "uint256" },
          { "name": "lastRoundBlock", "type": "uint256", "internalType": "uint256" },
          { "name": "roundInterval", "type": "uint256", "internalType": "uint256" }
        ]
      }
    ],
    "stateMutability": "view"
  },
  {
    "type": "function",
    "name": "getAllCreatures",
    "inputs": [
      {
        "name": "arenaId",
        "type": "uint256",
        "internalType": "uint256"
      }
    ],
    "outputs": [
      {
        "name": "",
        "type": "tuple[]",
        "internalType": "struct CreatureLib.Creature[]",
        "components": [
          { "name": "id", "type": "uint256", "internalType": "uint256" },
          { "name": "owner", "type": "address", "internalType": "address" },
          { "name": "speed", "type": "uint8", "internalType": "uint8" },
          { "name": "strength", "type": "uint8", "internalType": "uint8" },
          { "name": "intelligence", "type": "uint8", "internalType": "uint8" },
          { "name": "aggression", "type": "uint8", "internalType": "uint8" },
          { "name": "reproRate", "type": "uint8", "internalType": "uint8" },
          { "name": "defense", "type": "uint8", "internalType": "uint8" },
          { "name": "energy", "type": "uint16", "internalType": "uint16" },
          { "name": "hp", "type": "uint16", "internalType": "uint16" },
          { "name": "x", "type": "uint8", "internalType": "uint8" },
          { "name": "y", "type": "uint8", "internalType": "uint8" },
          { "name": "generation", "type": "uint32", "internalType": "uint32" },
          { "name": "alive", "type": "bool", "internalType": "bool" },
          { "name": "genome", "type": "bytes32", "internalType": "bytes32" }
        ]
      }
    ],
    "stateMutability": "view"
  },
  {
    "type": "function",
    "name": "hasJoined",
    "inputs": [
      {
        "name": "",
        "type": "uint256",
        "internalType": "uint256"
      },
      {
        "name": "",
        "type": "address",
        "internalType": "address"
      }
    ],
    "outputs": [
      {
        "name": "",
        "type": "bool",
        "internalType": "bool"
      }
    ],
    "stateMutability": "view"
  },
  {
    "type": "function",
    "name": "joinArena",
    "inputs": [
      {
        "name": "arenaId",
        "type": "uint256",
        "internalType": "uint256"
      }
    ],
    "outputs": [],
    "stateMutability": "payable"
  },
  {
    "type": "function",
    "name": "nextArenaId",
    "inputs": [],
    "outputs": [
      {
        "name": "",
        "type": "uint256",
        "internalType": "uint256"
      }
    ],
    "stateMutability": "view"
  },
  {
    "type": "function",
    "name": "nextCreatureId",
    "inputs": [],
    "outputs": [
      {
        "name": "",
        "type": "uint256",
        "internalType": "uint256"
      }
    ],
    "stateMutability": "view"
  },
  {
    "type": "function",
    "name": "owner",
    "inputs": [],
    "outputs": [
      {
        "name": "",
        "type": "address",
        "internalType": "address"
      }
    ],
    "stateMutability": "view"
  },
  {
    "type": "function",
    "name": "pause",
    "inputs": [],
    "outputs": [],
    "stateMutability": "nonpayable"
  },
  {
    "type": "function",
    "name": "paused",
    "inputs": [],
    "outputs": [
      {
        "name": "",
        "type": "bool",
        "internalType": "bool"
      }
    ],
    "stateMutability": "view"
  },
  {
    "type": "function",
    "name": "pendingRewards",
    "inputs": [
      {
        "name": "",
        "type": "uint256",
        "internalType": "uint256"
      },
      {
        "name": "",
        "type": "address",
        "internalType": "address"
      }
    ],
    "outputs": [
      {
        "name": "",
        "type": "uint256",
        "internalType": "uint256"
      }
    ],
    "stateMutability": "view"
  },
  {
    "type": "function",
    "name": "processedIndex",
    "inputs": [
      {
        "name": "",
        "type": "uint256",
        "internalType": "uint256"
      }
    ],
    "outputs": [
      {
        "name": "",
        "type": "uint256",
        "internalType": "uint256"
      }
    ],
    "stateMutability": "view"
  },
  {
    "type": "function",
    "name": "renounceOwnership",
    "inputs": [],
    "outputs": [],
    "stateMutability": "nonpayable"
  },
  {
    "type": "function",
    "name": "rewardsDistributed",
    "inputs": [
      {
        "name": "",
        "type": "uint256",
        "internalType": "uint256"
      }
    ],
    "outputs": [
      {
        "name": "",
        "type": "bool",
        "internalType": "bool"
      }
    ],
    "stateMutability": "view"
  },
  {
    "type": "function",
    "name": "runEvolutionRound",
    "inputs": [
      {
        "name": "arenaId",
        "type": "uint256",
        "internalType": "uint256"
      }
    ],
    "outputs": [],
    "stateMutability": "nonpayable"
  },
  {
    "type": "function",
    "name": "setFeeRecipient",
    "inputs": [
      {
        "name": "_feeRecipient",
        "type": "address",
        "internalType": "address"
      }
    ],
    "outputs": [],
    "stateMutability": "nonpayable"
  },
  {
    "type": "function",
    "name": "startArena",
    "inputs": [
      {
        "name": "arenaId",
        "type": "uint256",
        "internalType": "uint256"
      }
    ],
    "outputs": [],
    "stateMutability": "nonpayable"
  },
  {
    "type": "function",
    "name": "transferOwnership",
    "inputs": [
      {
        "name": "newOwner",
        "type": "address",
        "internalType": "address"
      }
    ],
    "outputs": [],
    "stateMutability": "nonpayable"
  },
  {
    "type": "function",
    "name": "unpause",
    "inputs": [],
    "outputs": [],
    "stateMutability": "nonpayable"
  },
  {
    "type": "event",
    "name": "ArenaCreated",
    "inputs": [
      {
        "name": "arenaId",
        "type": "uint256",
        "indexed": true,
        "internalType": "uint256"
      },
      {
        "name": "creator",
        "type": "address",
        "indexed": false,
        "internalType": "address"
      }
    ],
    "anonymous": false
  },
  {
    "type": "event",
    "name": "ArenaStarted",
    "inputs": [
      {
        "name": "arenaId",
        "type": "uint256",
        "indexed": true,
        "internalType": "uint256"
      }
    ],
    "anonymous": false
  },
  {
    "type": "event",
    "name": "BreedingOccurred",
    "inputs": [
      {
        "name": "arenaId",
        "type": "uint256",
        "indexed": true,
        "internalType": "uint256"
      },
      {
        "name": "parent1",
        "type": "uint256",
        "indexed": false,
        "internalType": "uint256"
      },
      {
        "name": "parent2",
        "type": "uint256",
        "indexed": false,
        "internalType": "uint256"
      },
      {
        "name": "child",
        "type": "uint256",
        "indexed": false,
        "internalType": "uint256"
      }
    ],
    "anonymous": false
  },
  {
    "type": "event",
    "name": "BreedingOccurred",
    "inputs": [
      {
        "name": "arenaId",
        "type": "uint256",
        "indexed": true,
        "internalType": "uint256"
      },
      {
        "name": "parent1",
        "type": "uint256",
        "indexed": false,
        "internalType": "uint256"
      },
      {
        "name": "parent2",
        "type": "uint256",
        "indexed": false,
        "internalType": "uint256"
      },
      {
        "name": "child",
        "type": "uint256",
        "indexed": false,
        "internalType": "uint256"
      }
    ],
    "anonymous": false
  },
  {
    "type": "event",
    "name": "CombatOccurred",
    "inputs": [
      {
        "name": "arenaId",
        "type": "uint256",
        "indexed": true,
        "internalType": "uint256"
      },
      {
        "name": "attacker",
        "type": "uint256",
        "indexed": false,
        "internalType": "uint256"
      },
      {
        "name": "defender",
        "type": "uint256",
        "indexed": false,
        "internalType": "uint256"
      },
      {
        "name": "attackerWon",
        "type": "bool",
        "indexed": false,
        "internalType": "bool"
      }
    ],
    "anonymous": false
  },
  {
    "type": "event",
    "name": "CombatOccurred",
    "inputs": [
      {
        "name": "arenaId",
        "type": "uint256",
        "indexed": true,
        "internalType": "uint256"
      },
      {
        "name": "attacker",
        "type": "uint256",
        "indexed": false,
        "internalType": "uint256"
      },
      {
        "name": "defender",
        "type": "uint256",
        "indexed": false,
        "internalType": "uint256"
      },
      {
        "name": "attackerWon",
        "type": "bool",
        "indexed": false,
        "internalType": "bool"
      }
    ],
    "anonymous": false
  },
  {
    "type": "event",
    "name": "CreatureBorn",
    "inputs": [
      {
        "name": "arenaId",
        "type": "uint256",
        "indexed": true,
        "internalType": "uint256"
      },
      {
        "name": "creatureId",
        "type": "uint256",
        "indexed": false,
        "internalType": "uint256"
      },
      {
        "name": "owner",
        "type": "address",
        "indexed": false,
        "internalType": "address"
      },
      {
        "name": "genome",
        "type": "bytes32",
        "indexed": false,
        "internalType": "bytes32"
      }
    ],
    "anonymous": false
  },
  {
    "type": "event",
    "name": "CreatureBorn",
    "inputs": [
      {
        "name": "arenaId",
        "type": "uint256",
        "indexed": true,
        "internalType": "uint256"
      },
      {
        "name": "creatureId",
        "type": "uint256",
        "indexed": false,
        "internalType": "uint256"
      },
      {
        "name": "owner",
        "type": "address",
        "indexed": false,
        "internalType": "address"
      },
      {
        "name": "genome",
        "type": "bytes32",
        "indexed": false,
        "internalType": "bytes32"
      }
    ],
    "anonymous": false
  },
  {
    "type": "event",
    "name": "CreatureDied",
    "inputs": [
      {
        "name": "arenaId",
        "type": "uint256",
        "indexed": true,
        "internalType": "uint256"
      },
      {
        "name": "creatureId",
        "type": "uint256",
        "indexed": false,
        "internalType": "uint256"
      }
    ],
    "anonymous": false
  },
  {
    "type": "event",
    "name": "CreatureDied",
    "inputs": [
      {
        "name": "arenaId",
        "type": "uint256",
        "indexed": true,
        "internalType": "uint256"
      },
      {
        "name": "creatureId",
        "type": "uint256",
        "indexed": false,
        "internalType": "uint256"
      }
    ],
    "anonymous": false
  },
  {
    "type": "event",
    "name": "EmergencyWithdraw",
    "inputs": [
      {
        "name": "arenaId",
        "type": "uint256",
        "indexed": true,
        "internalType": "uint256"
      },
      {
        "name": "recipient",
        "type": "address",
        "indexed": false,
        "internalType": "address"
      },
      {
        "name": "amount",
        "type": "uint256",
        "indexed": false,
        "internalType": "uint256"
      }
    ],
    "anonymous": false
  },
  {
    "type": "event",
    "name": "OwnershipTransferred",
    "inputs": [
      {
        "name": "previousOwner",
        "type": "address",
        "indexed": true,
        "internalType": "address"
      },
      {
        "name": "newOwner",
        "type": "address",
        "indexed": true,
        "internalType": "address"
      }
    ],
    "anonymous": false
  },
  {
    "type": "event",
    "name": "Paused",
    "inputs": [
      {
        "name": "account",
        "type": "address",
        "indexed": false,
        "internalType": "address"
      }
    ],
    "anonymous": false
  },
  {
    "type": "event",
    "name": "PlayerJoined",
    "inputs": [
      {
        "name": "arenaId",
        "type": "uint256",
        "indexed": true,
        "internalType": "uint256"
      },
      {
        "name": "player",
        "type": "address",
        "indexed": false,
        "internalType": "address"
      }
    ],
    "anonymous": false
  },
  {
    "type": "event",
    "name": "ProtocolFeeCollected",
    "inputs": [
      {
        "name": "arenaId",
        "type": "uint256",
        "indexed": true,
        "internalType": "uint256"
      },
      {
        "name": "amount",
        "type": "uint256",
        "indexed": false,
        "internalType": "uint256"
      }
    ],
    "anonymous": false
  },
  {
    "type": "event",
    "name": "RewardClaimed",
    "inputs": [
      {
        "name": "arenaId",
        "type": "uint256",
        "indexed": true,
        "internalType": "uint256"
      },
      {
        "name": "player",
        "type": "address",
        "indexed": false,
        "internalType": "address"
      },
      {
        "name": "amount",
        "type": "uint256",
        "indexed": false,
        "internalType": "uint256"
      }
    ],
    "anonymous": false
  },
  {
    "type": "event",
    "name": "RoundExecuted",
    "inputs": [
      {
        "name": "arenaId",
        "type": "uint256",
        "indexed": true,
        "internalType": "uint256"
      },
      {
        "name": "round",
        "type": "uint256",
        "indexed": false,
        "internalType": "uint256"
      },
      {
        "name": "survivors",
        "type": "uint256",
        "indexed": false,
        "internalType": "uint256"
      }
    ],
    "anonymous": false
  },
  {
    "type": "event",
    "name": "RoundPartial",
    "inputs": [
      {
        "name": "arenaId",
        "type": "uint256",
        "indexed": true,
        "internalType": "uint256"
      },
      {
        "name": "round",
        "type": "uint256",
        "indexed": false,
        "internalType": "uint256"
      },
      {
        "name": "processed",
        "type": "uint256",
        "indexed": false,
        "internalType": "uint256"
      }
    ],
    "anonymous": false
  },
  {
    "type": "event",
    "name": "Unpaused",
    "inputs": [
      {
        "name": "account",
        "type": "address",
        "indexed": false,
        "internalType": "address"
      }
    ],
    "anonymous": false
  },
  {
    "type": "error",
    "name": "EnforcedPause",
    "inputs": []
  },
  {
    "type": "error",
    "name": "ExpectedPause",
    "inputs": []
  },
  {
    "type": "error",
    "name": "OwnableInvalidOwner",
    "inputs": [
      {
        "name": "owner",
        "type": "address",
        "internalType": "address"
      }
    ]
  },
  {
    "type": "error",
    "name": "OwnableUnauthorizedAccount",
    "inputs": [
      {
        "name": "account",
        "type": "address",
        "internalType": "address"
      }
    ]
  },
  {
    "type": "error",
    "name": "ReentrancyGuardReentrantCall",
    "inputs": []
  }
] as const;