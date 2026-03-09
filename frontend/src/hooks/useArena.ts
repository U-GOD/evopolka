import { useReadContract, useWriteContract, useWaitForTransactionReceipt } from 'wagmi';
import { arenaAbi } from '../config/abi';
import { parseEther } from 'viem';

// TODO: Replace with deployed address on Polkadot testnet
export const ARENA_ADDRESS = '0x0000000000000000000000000000000000000000';

export function useArena(arenaId: bigint) {
  const { data: arena, refetch: refetchArena } = useReadContract({
    address: ARENA_ADDRESS,
    abi: arenaAbi,
    functionName: 'getArena',
    args: [arenaId],
    query: {
      enabled: arenaId > 0n,
      refetchInterval: 6000, // Poll every 6 seconds
    }
  });

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
      args: [parseEther(stakeDot), BigInt(gridSize), BigInt(maxRounds)],
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
    });
  };

  return { join, hash, isPending, isWaiting, isSuccess };
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
    });
  };

  return { run, hash, isPending, isWaiting, isSuccess };
}
