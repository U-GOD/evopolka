import React, { useState, useRef, useCallback } from 'react';
import { Link } from 'react-router-dom';
import { ConnectButton } from './components/ConnectButton';
import { ArenaRenderer } from './components/ArenaRenderer';
import { useArena, useCreateArena, useJoinArena, useRunRound } from './hooks/useArena';
import { useCreatures } from './hooks/useCreatures';
import { useArenaEvents } from './hooks/useArenaEvents';
import { useAccount } from 'wagmi';
import { parseEther } from 'viem';

function App() {
  const [arenaIdInput, setArenaIdInput] = useState('1');
  const [stakeInput, setStakeInput] = useState('0.1');
  
  const currentArenaId = BigInt(arenaIdInput || '0');
  
  const { address } = useAccount();
  const { arena } = useArena(currentArenaId);
  const { creatures } = useCreatures(currentArenaId);

  // Particle spawner ref — the ArenaRenderer registers its spawnParticles fn here
  const spawnParticleRef = useRef<((x: number, y: number, type: 'spark' | 'birth' | 'death') => void) | null>(null);
  const handleEventSpawn = useCallback((fn: (x: number, y: number, type: 'spark' | 'birth' | 'death') => void) => {
    spawnParticleRef.current = fn;
  }, []);

  const liveCreatures = (creatures as any[]) || [];
  
  const { logs } = useArenaEvents(currentArenaId, liveCreatures, spawnParticleRef.current);
  
  const { create, isPending: isCreating } = useCreateArena();
  const { join, isPending: isJoining } = useJoinArena();
  const { run, isPending: isRunning } = useRunRound();

  const handleCreateArena = async () => {
    try {
      if (!stakeInput) return;
      await create(stakeInput, 20, 100); // 20x20 grid, 100 rounds max
    } catch (e) {
      console.error(e);
    }
  };

  const handleJoinArena = async () => {
    try {
      if (!arena) return;
      await join(currentArenaId, arena.stakePerPlayer);
    } catch (e) {
      console.error(e);
    }
  };

  const handleRunRound = async () => {
    try {
      await run(currentArenaId);
    } catch (e) {
      console.error(e);
    }
  };

  return (
    <div className="flex h-screen w-full bg-background-dark text-slate-100 font-display overflow-hidden">
      {/* Left Sidebar: Lobby & Controls */}
      <aside className="w-80 flex flex-col border-r border-border-muted bg-surface/50 p-6 gap-6">
        <Link to="/" className="flex items-center gap-2 hover:opacity-80 transition-opacity">
          <div className="w-8 h-8 rounded-lg bg-primary rotate-45 flex items-center justify-center shadow-[0_0_15px_rgba(244,37,157,0.5)]">
            <div className="w-3 h-3 bg-background-dark rounded-sm"></div>
          </div>
          <h1 className="text-2xl font-black tracking-tight text-white mt-1">
            EVO<span className="text-primary">POLKA</span>
          </h1>
        </Link>
        
        <ConnectButton />

        <div className="glass-panel p-5 rounded-xl flex flex-col gap-4">
          <h3 className="text-xs uppercase tracking-widest text-slate-500 font-bold">Arena Management</h3>
          
          <div className="flex gap-2">
            <div className="flex flex-col gap-2 w-1/3">
              <label className="text-sm font-medium text-slate-300">ID</label>
              <input value={arenaIdInput} onChange={e => setArenaIdInput(e.target.value)} className="w-full bg-background-dark border-border-muted rounded-lg py-2.5 px-4 text-white focus:ring-primary focus:border-primary transition-all text-center" placeholder="1" type="number" />
            </div>
            <div className="flex flex-col gap-2 w-2/3">
              <label className="text-sm font-medium text-slate-300">Stake (DOT)</label>
              <div className="relative">
                <input value={stakeInput} onChange={e => setStakeInput(e.target.value)} className="w-full bg-background-dark border-border-muted rounded-lg py-2.5 px-4 text-white focus:ring-primary focus:border-primary transition-all" placeholder="0.1" type="number" />
              </div>
            </div>
          </div>
          
          {arena && arena.state === 0 ? (
            <button disabled={isJoining || !address} onClick={handleJoinArena} className="w-full bg-primary hover:bg-primary/90 disabled:opacity-50 text-white font-bold py-3 rounded-lg flex items-center justify-center gap-2 transition-all">
              <svg xmlns="http://www.w3.org/2000/svg" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><polyline points="14.5 17.5 3 6 3 3 6 3 17.5 14.5"/><line x1="13" y1="19" x2="19" y2="13"/><line x1="16" y1="16" x2="20" y2="20"/><line x1="19" y1="21" x2="21" y2="19"/><polyline points="14.5 6.5 18 3 21 3 21 6 17.5 9.5"/><line x1="5" y1="14" x2="9" y2="19"/><line x1="9" y1="13" x2="11" y2="15"/></svg>
              {isJoining ? 'Joining...' : 'Join Arena'}
            </button>
          ) : (
            <button disabled={isCreating || !address} onClick={handleCreateArena} className="w-full bg-surface hover:bg-surface/80 border border-primary text-primary disabled:opacity-50 font-bold py-3 rounded-lg flex items-center justify-center gap-2 transition-all">
              {isCreating ? 'Creating...' : 'Create New Arena'}
            </button>
          )}
        </div>

        <div className="flex-1 flex flex-col gap-4 min-h-0">
          <h3 className="text-xs uppercase tracking-widest text-slate-500 font-bold">Arena Status</h3>
          <div className="flex flex-col gap-3 overflow-y-auto terminal-scroll p-2 text-sm text-slate-300">
            {arena ? (
              <>
                <div className="flex justify-between"><span>State:</span> <span className="text-accent-cyan font-bold">{['LOBBY', 'ACTIVE', 'EVOLVING', 'FINISHED'][arena.state]}</span></div>
                <div className="flex justify-between"><span>Pot:</span> <span>{Number(arena.totalPot) / 1e18} DOT</span></div>
                <div className="flex justify-between"><span>Grid:</span> <span>{Number(arena.gridSize)}x{Number(arena.gridSize)}</span></div>
              </>
            ) : (
              <div className="text-slate-500 italic text-center py-4">Arena not found</div>
            )}
          </div>
        </div>

        <button disabled={isRunning || !arena || arena.state !== 1} onClick={handleRunRound} className="w-full bg-accent-cyan/10 hover:bg-accent-cyan/20 disabled:opacity-30 text-accent-cyan border border-accent-cyan/30 font-bold py-4 rounded-xl flex items-center justify-center gap-2 transition-all uppercase tracking-tighter">
          <svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="M4.5 16.5c-1.5 1.26-2 5-2 5s3.74-.5 5-2c.71-.84.7-2.13-.09-2.91a2.18 2.18 0 0 0-2.91-.09z"/><path d="m12 15-3-3a22 22 0 0 1 2-3.95A12.88 12.88 0 0 1 22 2c0 2.72-.78 7.5-6 11a22.35 22.35 0 0 1-4 2z"/><path d="M9 12H4s.55-3.03 2-4c1.62-1.08 5 0 5 0"/><path d="M12 15v5s3.03-.55 4-2c1.08-1.62 0-5 0-5"/></svg>
          {isRunning ? 'Processing...' : 'Run Round'}
        </button>
      </aside>

      {/* Center Main View: Evolution Grid */}
      <main className="flex-1 flex flex-col bg-background-dark relative p-8">
        {/* Stats Bar */}
        <div className="flex items-center justify-between mb-8 bg-surface/40 p-4 rounded-xl border border-border-muted">
          <div className="flex gap-8">
            <div className="flex flex-col">
              <span className="text-[10px] uppercase text-slate-500 font-bold">Evolution Round</span>
              <span className="text-xl font-bold text-white tracking-tight">14 <span className="text-slate-600">/ 100</span></span>
            </div>
            
            <div className="flex flex-col border-l border-border-muted pl-8">
              <span className="text-[10px] uppercase text-slate-500 font-bold">Total Alive</span>
              <span className="text-xl font-bold text-primary">42</span>
            </div>
            
            <div className="flex flex-col border-l border-border-muted pl-8">
              <span className="text-[10px] uppercase text-slate-500 font-bold">Gas (Gwei)</span>
              <span className="text-xl font-bold text-accent-cyan">1.2</span>
            </div>
          </div>
          
          <div className="flex items-center gap-3">
            <button className="p-2 rounded-lg bg-white/5 hover:bg-white/10 text-white transition-all">
              <svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="M12.22 2h-.44a2 2 0 0 0-2 2v.18a2 2 0 0 1-1 1.73l-.43.25a2 2 0 0 1-2 0l-.15-.08a2 2 0 0 0-2.73.73l-.22.38a2 2 0 0 0 .73 2.73l.15.1a2 2 0 0 1 1 1.72v.51a2 2 0 0 1-1 1.74l-.15.09a2 2 0 0 0-.73 2.73l.22.38a2 2 0 0 0 2.73.73l.15-.08a2 2 0 0 1 2 0l.43.25a2 2 0 0 1 1 1.73V20a2 2 0 0 0 2 2h.44a2 2 0 0 0 2-2v-.18a2 2 0 0 1 1-1.73l.43-.25a2 2 0 0 1 2 0l.15.08a2 2 0 0 0 2.73-.73l.22-.39a2 2 0 0 0-.73-2.73l-.15-.08a2 2 0 0 1-1-1.74v-.5a2 2 0 0 1 1-1.74l.15-.09a2 2 0 0 0 .73-2.73l-.22-.38a2 2 0 0 0-2.73-.73l-.15.08a2 2 0 0 1-2 0l-.43-.25a2 2 0 0 1-1-1.73V4a2 2 0 0 0-2-2z"/><circle cx="12" cy="12" r="3"/></svg>
            </button>
            <div className="h-8 w-px bg-border-muted mx-2"></div>
            <button className="flex items-center gap-2 px-6 py-2 rounded-lg bg-white text-background-dark font-bold transition-all hover:bg-slate-200">
              <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><rect x="6" y="4" width="4" height="16"/><rect x="14" y="4" width="4" height="16"/></svg>
              Pause Evolution
            </button>
          </div>
        </div>

        {/* Simulation Grid Container */}
        <div className="flex-1 flex items-center justify-center">
          <div className="aspect-square h-full max-h-[700px] border border-border-muted bg-surface/20 rounded-xl relative grid-bg p-4 shadow-[0_0_50px_rgba(0,245,255,0.05)] overflow-hidden">
            <ArenaRenderer 
              arenaId={currentArenaId} 
              gridSize={arena ? Number(arena.gridSize) : 20} 
              onEventSpawn={handleEventSpawn}
            />
          </div>
        </div>

        {/* Legend Overlay */}
        <div className="absolute bottom-12 left-1/2 -translate-x-1/2 glass-panel px-6 py-2 rounded-full flex gap-6 border border-white/10">
          <div className="flex items-center gap-2">
            <div className="w-2 h-2 rounded-full bg-primary"></div>
            <span className="text-xs font-bold text-slate-400">Aggressor</span>
          </div>
          <div className="flex items-center gap-2">
            <div className="w-2 h-2 rounded-full bg-accent-cyan"></div>
            <span className="text-xs font-bold text-slate-400">Defender</span>
          </div>
          <div className="flex items-center gap-2">
            <div className="w-2 h-2 rounded-full bg-emerald-400"></div>
            <span className="text-xs font-bold text-slate-400">Producer</span>
          </div>
          <div className="flex items-center gap-2">
            <div className="w-1.5 h-1.5 rotate-45 bg-yellow-400"></div>
            <span className="text-xs font-bold text-slate-400">Food</span>
          </div>
        </div>
      </main>

      {/* Right Sidebar: Leaderboard & Logs */}
      <aside className="w-96 flex flex-col border-l border-border-muted bg-surface/50 overflow-hidden">
        {/* Top half: Leaderboard */}
        <div className="flex-1 flex flex-col p-6 min-h-0 border-b border-border-muted">
          <h3 className="text-xs uppercase tracking-widest text-slate-500 font-bold mb-4">Leaderboard</h3>
          <div className="overflow-y-auto terminal-scroll pr-2">
            <table className="w-full text-left">
              <thead>
                <tr className="text-[10px] uppercase text-slate-500 border-b border-border-muted">
                  <th className="pb-2 font-bold">ID</th>
                  <th className="pb-2 font-bold">Owner</th>
                  <th className="pb-2 font-bold text-right">Stat</th>
                </tr>
              </thead>
              <tbody className="text-sm">
                {liveCreatures.sort((a, b) => Number(b.hp) - Number(a.hp)).slice(0, 10).map((c) => (
                  <tr key={c.id.toString()} className="border-b border-white/5 hover:bg-white/5 transition-colors group">
                    <td className="py-3 font-mono text-slate-400">#{c.id.toString().padStart(3, '0')}</td>
                    <td className="py-3 font-medium text-white">{c.owner.slice(0, 6)}..{c.owner.slice(-4)}</td>
                    <td className="py-3 text-right">
                      <span className="bg-primary/20 text-primary px-2 py-0.5 rounded text-[10px] font-bold uppercase">
                        HP: {c.hp.toString()}
                      </span>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </div>

        {/* Bottom half: Event Log */}
        <div className="flex-1 flex flex-col p-6 min-h-0 bg-background-dark/30">
          <div className="flex items-center justify-between mb-4">
            <h3 className="text-xs uppercase tracking-widest text-slate-500 font-bold">Evolution Log</h3>
            <span className="w-2 h-2 rounded-full bg-accent-cyan animate-pulse"></span>
          </div>
            {logs.length === 0 ? (
              <p className="text-slate-500 italic text-center mt-4">No events yet...</p>
            ) : (
              logs.map((log) => (
                <p key={log.id}>
                  <span className="text-slate-600">
                    [{log.timestamp.toLocaleTimeString([], { hour12: false })}]
                  </span>{' '}
                  {log.message}
                </p>
              ))
            )}
        </div>
      </aside>
    </div>
  );
}

export default App;
