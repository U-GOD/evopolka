import { useReadContract, useWriteContract, useWaitForTransactionReceipt } from 'wagmi';
import { arenaAbi } from '../config/abi';
import { parseEther } from 'viem';

export const ARENA_ADDRESS = '0x0b9496919b87bed8cd568209a9366e8078b78a4d';

export function useArena(arenaId: bigint) {
  const { data: rawArena, refetch: refetchArena } = useReadContract({
    address: ARENA_ADDRESS,
    abi: arenaAbi,
    functionName: 'getArena',
    args: [arenaId],
    query: {
      enabled: arenaId > 0n,
      refetchInterval: 6000,
    }
  });

  // Map the tuple back to an object since the contract was changed to return individual vars
  const arena = rawArena ? {
    id: (rawArena as any)[0],
    state: (rawArena as any)[1],
    stakePerPlayer: (rawArena as any)[2],
    totalPot: (rawArena as any)[3],
    roundNumber: (rawArena as any)[4],
    maxRounds: (rawArena as any)[5],
    gridSize: (rawArena as any)[6],
    creaturesPerPlayer: (rawArena as any)[7],
    mutationRate: (rawArena as any)[8],
    lastRoundBlock: (rawArena as any)[9],
    roundInterval: (rawArena as any)[10],
  } : undefined;

  return { arena, refetchArena };
}

export function useCreateArena() {
  const { writeContractAsync, data: hash, isPending } = useWriteContract();
  
  const { isLoading: isWaiting, isSuccess } = useWaitForTransactionReceipt({
    hash,
  });

  const create = async (stakeDot: string, gridSize: number, maxRounds: number) => {
    return writeContractAsync({
      address: ARENA_ADDRESS,
      abi: arenaAbi,
      functionName: 'createArena',
      args: [parseEther(stakeDot), BigInt(maxRounds), BigInt(gridSize), BigInt(5), BigInt(500), BigInt(10)],
      type: 'legacy',
    });
  };

  return { create, hash, isPending, isWaiting, isSuccess };
}

export function useJoinArena() {
  const { writeContractAsync, data: hash, isPending } = useWriteContract();
  
  const { isLoading: isWaiting, isSuccess } = useWaitForTransactionReceipt({
    hash,
  });

  const join = async (arenaId: bigint, stakeAmount: bigint) => {
    return writeContractAsync({
      address: ARENA_ADDRESS,
      abi: arenaAbi,
      functionName: 'joinArena',
      args: [arenaId],
      value: stakeAmount,
      type: 'legacy',
    });
  };

  return { join, hash, isPending, isWaiting, isSuccess };
}

export function useStartArena() {
  const { writeContractAsync, data: hash, isPending } = useWriteContract();

  const { isLoading: isWaiting, isSuccess } = useWaitForTransactionReceipt({
    hash,
  });

  const start = async (arenaId: bigint) => {
    return writeContractAsync({
      address: ARENA_ADDRESS,
      abi: arenaAbi,
      functionName: 'startArena',
      args: [arenaId],
      type: 'legacy',
    });
  };

  return { start, hash, isPending, isWaiting, isSuccess };
}

export function useRunRound() {
  const { writeContractAsync, data: hash, isPending } = useWriteContract();
  
  const { isLoading: isWaiting, isSuccess } = useWaitForTransactionReceipt({
    hash,
  });

  const run = async (arenaId: bigint) => {
    return writeContractAsync({
      address: ARENA_ADDRESS,
      abi: arenaAbi,
      functionName: 'runEvolutionRound',
      args: [arenaId],
      type: 'legacy',
    });
  };

  return { run, hash, isPending, isWaiting, isSuccess };
}

export function useTriggerDisaster() {
  const { writeContractAsync, data: hash, isPending } = useWriteContract();
  
  const { isLoading: isWaiting, isSuccess } = useWaitForTransactionReceipt({
    hash,
  });

  const trigger = async (arenaId: bigint, disasterType: number) => {
    return writeContractAsync({
      address: ARENA_ADDRESS,
      abi: arenaAbi,
      functionName: 'triggerDisaster',
      args: [arenaId, disasterType],
      type: 'legacy',
    });
  };

  return { trigger, hash, isPending, isWaiting, isSuccess };
}
