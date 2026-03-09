import { useReadContract } from 'wagmi';
import { arenaAbi } from '../config/abi';
import { ARENA_ADDRESS } from './useArena';

export function useCreatures(arenaId: bigint) {
  const { data: creatures, refetch: refetchCreatures } = useReadContract({
    address: ARENA_ADDRESS,
    abi: arenaAbi,
    functionName: 'getAllCreatures',
    args: [arenaId],
    query: {
      enabled: arenaId > 0n,
      refetchInterval: 6000,
    }
  });

  return { creatures, refetchCreatures };
}
