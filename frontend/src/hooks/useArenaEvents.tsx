import React, { useState, useCallback } from 'react';
import { useWatchContractEvent } from 'wagmi';
import { arenaAbi } from '../config/abi';
import { ARENA_ADDRESS } from './useArena';

export interface ArenaLogEvent {
  id: string;
  timestamp: Date;
  type: 'born' | 'combat' | 'died' | 'global';
  message: React.ReactNode;
}

export function useArenaEvents(arenaId: bigint) {
  const [logs, setLogs] = useState<ArenaLogEvent[]>([]);

  const addLog = useCallback((log: Omit<ArenaLogEvent, 'id' | 'timestamp'>) => {
    setLogs(prev => [
      {
        ...log,
        id: Math.random().toString(36).substring(7),
        timestamp: new Date()
      },
      ...prev
    ].slice(0, 50)); // Keep last 50 logs
  }, []);

  useWatchContractEvent({
    address: ARENA_ADDRESS,
    abi: arenaAbi,
    eventName: 'CreatureBorn',
    onLogs(contractLogs: any[]) {
      contractLogs.forEach(log => {
        if (log.args.arenaId !== arenaId) return;
        addLog({
          type: 'born',
          message: <><span className="text-primary">#{log.args.creatureId?.toString()}</span> was born via genome <span className="text-slate-400">{log.args.genome?.toString().slice(0, 10)}...</span></>
        });
      });
    },
  });

  useWatchContractEvent({
    address: ARENA_ADDRESS,
    abi: arenaAbi,
    eventName: 'CreatureDied',
    onLogs(contractLogs: any[]) {
      contractLogs.forEach(log => {
        if (log.args.arenaId !== arenaId) return;
        addLog({
          type: 'died',
          message: <><span className="text-slate-400">#{log.args.creatureId?.toString()}</span> perished at round {log.args.round?.toString()}</>
        });
      });
    },
  });

  useWatchContractEvent({
    address: ARENA_ADDRESS,
    abi: arenaAbi,
    eventName: 'CombatOccurred',
    onLogs(contractLogs: any[]) {
      contractLogs.forEach(log => {
        if (log.args.arenaId !== arenaId) return;
        addLog({
          type: 'combat',
          message: <><span className="text-primary">#{log.args.attackerId?.toString()}</span> attacked <span className="text-accent-cyan">#{log.args.defenderId?.toString()}</span> (dmg: {log.args.damageDealt?.toString()})</>
        });
      });
    },
  });

  return { logs, addLog };
}
