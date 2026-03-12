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

export function useArenaEvents(
  arenaId: bigint,
  creaturesData: any[],
  spawnFn: ((x: number, y: number, type: 'spark' | 'birth' | 'death') => void) | null
) {
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
        
        // Spawn birth particle if we know where the parent/child is
        // We'll just guess from liveCreatures array for visual sake, or default to center
        const c = creaturesData.find(cr => cr.id.toString() === log.args.creatureId?.toString());
        if (c && spawnFn) spawnFn(c.x, c.y, 'birth');
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
        
        const c = creaturesData.find(cr => cr.id.toString() === log.args.creatureId?.toString());
        if (c && spawnFn) spawnFn(c.x, c.y, 'death');
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
        
        // Spawn sparks at the defender's location
        const defender = creaturesData.find(cr => cr.id.toString() === log.args.defenderId?.toString());
        if (defender && spawnFn) spawnFn(defender.x, defender.y, 'spark');
      });
    },
  });

  useWatchContractEvent({
    address: ARENA_ADDRESS,
    abi: arenaAbi,
    eventName: 'DisasterTriggered',
    onLogs(contractLogs: any[]) {
      contractLogs.forEach(log => {
        if (log.args.arenaId !== arenaId) return;
        const types = ['ASTEROID STRIKE', 'PLAGUE', 'ICE AGE', 'MUTATION STORM'];
        const pType = log.args.disasterType !== undefined ? Number(log.args.disasterType) : 0;
        const typeName = types[pType] || 'UNKNOWN DISASTER';
        
        addLog({
          type: 'global',
          message: <><span className="text-white font-black bg-red-600 px-2 py-0.5 rounded">⚠️ DISASTER: {typeName}</span></>
        });
        
        // Trigger a huge burst of particles from the center to simulate the disaster
        if (spawnFn) spawnFn(10, 10, pType === 2 ? 'ice' : 'disaster' as any);
      });
    },
  });

  return { logs, addLog };
}
