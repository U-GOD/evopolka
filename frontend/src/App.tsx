import { useState, useRef, useCallback } from 'react';
import { Link } from 'react-router-dom';
import { ConnectButton } from './components/ConnectButton';
import { ArenaRenderer } from './components/ArenaRenderer';
import { useArena, useCreateArena, useJoinArena, useStartArena, useRunRound, useTriggerDisaster } from './hooks/useArena';
import { useCreatures } from './hooks/useCreatures';
import { useArenaEvents } from './hooks/useArenaEvents';
import { useAccount, useBlockNumber } from 'wagmi';
function App() {
  const [arenaIdInput, setArenaIdInput] = useState('1');
  const [stakeInput, setStakeInput] = useState('0.1');
  
  const currentArenaId = BigInt(arenaIdInput || '0');
  
  const { address } = useAccount();
  const { arena } = useArena(currentArenaId);
  const { creatures } = useCreatures(currentArenaId);

  // Particle spawner ref
  const spawnParticleRef = useRef<((x: number, y: number, type: 'spark' | 'birth' | 'death') => void) | null>(null);
  const handleEventSpawn = useCallback((fn: (x: number, y: number, type: 'spark' | 'birth' | 'death') => void) => {
    spawnParticleRef.current = fn;
  }, []);

  const liveCreatures = (creatures as any[]) || [];
  const aliveCreatures = liveCreatures.filter((c) => c.alive);
  
  const { logs } = useArenaEvents(currentArenaId, liveCreatures, spawnParticleRef.current);
  
  const { create, isPending: isCreating } = useCreateArena();
  const { join, isPending: isJoining } = useJoinArena();
  const { start, isPending: isStarting } = useStartArena();
  const { run, isPending: isRunning } = useRunRound();
  const { trigger, isPending: isTriggering } = useTriggerDisaster();

  const ARENA_STATES = ['LOBBY', 'ACTIVE', 'EVOLVING', 'FINISHED'];
  const arenaState = arena ? Number(arena.state) : -1;

  const { data: currentBlockData } = useBlockNumber({ watch: true });
  const currentBlock = currentBlockData || 0n;
  const blocksUntilNext = arena ? (BigInt(arena.lastRoundBlock) + BigInt(arena.roundInterval)) - currentBlock : 0n;
  const isCooldown = blocksUntilNext > 0n;

  const handleCreateArena = async () => {
    try {
      if (!stakeInput) return;
      await create(stakeInput, 20, 100);
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

  const handleStartArena = async () => {
    try {
      await start(currentArenaId);
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
      {/* Left Sidebar */}
      <aside className="w-80 flex flex-col border-r border-border-muted bg-surface/50 p-6 gap-4 overflow-y-auto terminal-scroll">
        <Link to="/" className="flex items-center gap-2 hover:opacity-80 transition-opacity">
          <div className="w-8 h-8 rounded-lg bg-primary rotate-45 flex items-center justify-center shadow-[0_0_15px_rgba(244,37,157,0.5)]">
            <div className="w-3 h-3 bg-background-dark rounded-sm"></div>
          </div>
          <h1 className="text-2xl font-black tracking-tight text-white mt-1">
            EVO<span className="text-primary">POLKA</span>
          </h1>
        </Link>
        
        <ConnectButton />

        {/* Arena Management */}
        <div className="glass-panel p-5 rounded-xl flex flex-col gap-4">
          <h3 className="text-xs uppercase tracking-widest text-slate-500 font-bold">Arena Management</h3>
          
          <div className="flex gap-2">
            <div className="flex flex-col gap-1 w-1/3">
              <label className="text-xs font-medium text-slate-400">ID</label>
              <input value={arenaIdInput} onChange={e => setArenaIdInput(e.target.value)} className="w-full bg-background-dark border border-border-muted rounded-lg py-2 px-3 text-white text-center text-sm" placeholder="1" type="number" />
            </div>
            <div className="flex flex-col gap-1 w-2/3">
              <label className="text-xs font-medium text-slate-400">Stake (PAS)</label>
              <input value={stakeInput} onChange={e => setStakeInput(e.target.value)} className="w-full bg-background-dark border border-border-muted rounded-lg py-2 px-3 text-white text-sm" placeholder="0.1" type="number" />
            </div>
          </div>
          
          {/* Contextual action button based on arena state */}
          {!arena || arenaState === -1 ? (
            <button disabled={isCreating || !address} onClick={handleCreateArena} className="w-full bg-surface hover:bg-surface/80 border border-primary text-primary disabled:opacity-50 font-bold py-3 rounded-lg transition-all">
              {isCreating ? 'Creating...' : 'Create New Arena'}
            </button>
          ) : arenaState === 0 ? (
            <div className="flex flex-col gap-2">
              <button disabled={isJoining || !address} onClick={handleJoinArena} className="w-full bg-primary hover:bg-primary/90 disabled:opacity-50 text-white font-bold py-3 rounded-lg transition-all">
                {isJoining ? 'Joining...' : '⚔️ Join Arena'}
              </button>
              <button disabled={isStarting || !address} onClick={handleStartArena} className="w-full bg-accent-cyan/10 hover:bg-accent-cyan/20 border border-accent-cyan/30 text-accent-cyan disabled:opacity-50 font-bold py-2.5 rounded-lg transition-all text-sm">
                {isStarting ? 'Starting...' : '🚀 Start Arena (need ≥2 players)'}
              </button>
            </div>
          ) : (
            <button disabled={isCreating || !address} onClick={handleCreateArena} className="w-full bg-surface hover:bg-surface/80 border border-primary text-primary disabled:opacity-50 font-bold py-3 rounded-lg transition-all">
              {isCreating ? 'Creating...' : 'Create New Arena'}
            </button>
          )}
        </div>

        {/* Arena Status */}
        <div className="glass-panel p-5 rounded-xl flex flex-col gap-3">
          <h3 className="text-xs uppercase tracking-widest text-slate-500 font-bold">Arena Status</h3>
          {arena ? (
            <div className="flex flex-col gap-2 text-sm">
              <div className="flex justify-between items-center">
                <span className="text-slate-400">State</span>
                <span className={`font-bold px-2 py-0.5 rounded text-xs ${
                  arenaState === 0 ? 'bg-yellow-500/20 text-yellow-400' :
                  arenaState === 1 ? 'bg-green-500/20 text-green-400' :
                  arenaState === 2 ? 'bg-purple-500/20 text-purple-400' :
                  'bg-slate-500/20 text-slate-400'
                }`}>
                  {ARENA_STATES[arenaState] || 'UNKNOWN'}
                </span>
              </div>
              <div className="flex justify-between">
                <span className="text-slate-400">Pot</span>
                <span className="text-white font-mono">{(Number(arena.totalPot) / 1e18).toFixed(4)} PAS</span>
              </div>
              <div className="flex justify-between">
                <span className="text-slate-400">Grid</span>
                <span className="text-white font-mono">{Number(arena.gridSize)}×{Number(arena.gridSize)}</span>
              </div>
              <div className="flex justify-between">
                <span className="text-slate-400">Round</span>
                <span className="text-white font-mono">{Number(arena.roundNumber)} / {Number(arena.maxRounds)}</span>
              </div>
              <div className="flex justify-between">
                <span className="text-slate-400">Alive</span>
                <span className="text-primary font-bold font-mono">{aliveCreatures.length}</span>
              </div>
            </div>
          ) : (
            <div className="text-slate-500 italic text-center py-4 text-sm">No arena found. Create one above.</div>
          )}
        </div>

        {/* Run Round */}
        <button disabled={isRunning || !arena || arenaState !== 1 || isCooldown} onClick={handleRunRound} className="w-full bg-accent-cyan/10 hover:bg-accent-cyan/20 disabled:opacity-30 text-accent-cyan border border-accent-cyan/30 font-bold py-4 rounded-xl flex items-center justify-center gap-2 transition-all uppercase tracking-wider text-sm">
          🚀 {isRunning ? 'Processing...' : isCooldown ? `Wait ${blocksUntilNext} blocks...` : 'Run Evolution Round'}
        </button>

        {/* Disaster Controls */}
        <div className="flex flex-col gap-2">
          <h3 className="text-[10px] uppercase tracking-widest text-slate-500 font-bold mb-1">Trigger Disaster</h3>
          <div className="grid grid-cols-2 gap-2">
            <button disabled={isTriggering || !arena || arenaState !== 1 || isCooldown} onClick={() => trigger(currentArenaId, 0)} className="bg-red-500/10 hover:bg-red-500/20 text-red-400 border border-red-500/20 text-xs font-bold py-2 rounded-lg disabled:opacity-30 transition-all">
              ☄️ Asteroid
            </button>
            <button disabled={isTriggering || !arena || arenaState !== 1 || isCooldown} onClick={() => trigger(currentArenaId, 1)} className="bg-green-500/10 hover:bg-green-500/20 text-green-400 border border-green-500/20 text-xs font-bold py-2 rounded-lg disabled:opacity-30 transition-all">
              ☣️ Plague
            </button>
            <button disabled={isTriggering || !arena || arenaState !== 1 || isCooldown} onClick={() => trigger(currentArenaId, 2)} className="bg-blue-500/10 hover:bg-blue-500/20 text-blue-400 border border-blue-500/20 text-xs font-bold py-2 rounded-lg disabled:opacity-30 transition-all">
              ❄️ Ice Age
            </button>
            <button disabled={isTriggering || !arena || arenaState !== 1 || isCooldown} onClick={() => trigger(currentArenaId, 3)} className="bg-purple-500/10 hover:bg-purple-500/20 text-purple-400 border border-purple-500/20 text-xs font-bold py-2 rounded-lg disabled:opacity-30 transition-all">
              🧬 Mut. Storm
            </button>
          </div>
        </div>
      </aside>

      {/* Center Main View */}
      <main className="flex-1 flex flex-col bg-background-dark relative p-8">
        {/* Stats Bar — live data from contract */}
        <div className="flex items-center justify-between mb-6 bg-surface/40 p-4 rounded-xl border border-border-muted">
          <div className="flex gap-8">
            <div className="flex flex-col">
              <span className="text-[10px] uppercase text-slate-500 font-bold">Round</span>
              <span className="text-xl font-bold text-white tracking-tight">
                {arena ? Number(arena.roundNumber) : 0}
                <span className="text-slate-600"> / {arena ? Number(arena.maxRounds) : '—'}</span>
              </span>
            </div>
            
            <div className="flex flex-col border-l border-border-muted pl-8">
              <span className="text-[10px] uppercase text-slate-500 font-bold">Total Alive</span>
              <span className="text-xl font-bold text-primary">{aliveCreatures.length}</span>
            </div>
            
            <div className="flex flex-col border-l border-border-muted pl-8">
              <span className="text-[10px] uppercase text-slate-500 font-bold">Total Creatures</span>
              <span className="text-xl font-bold text-accent-cyan">{liveCreatures.length}</span>
            </div>

            <div className="flex flex-col border-l border-border-muted pl-8">
              <span className="text-[10px] uppercase text-slate-500 font-bold">Prize Pot</span>
              <span className="text-xl font-bold text-emerald-400">{arena ? (Number(arena.totalPot) / 1e18).toFixed(2) : '0'} PAS</span>
            </div>
          </div>
          
          <div className="flex items-center gap-2">
            <span className={`px-3 py-1 rounded-full text-xs font-bold ${
              arenaState === 1 ? 'bg-green-500/20 text-green-400 animate-pulse' :
              arenaState === 0 ? 'bg-yellow-500/20 text-yellow-400' : 
              'bg-slate-500/20 text-slate-400'
            }`}>
              {arena ? ARENA_STATES[arenaState] || 'UNKNOWN' : 'NO ARENA'}
            </span>
          </div>
        </div>

        {/* Simulation Grid */}
        <div className="flex-1 flex items-center justify-center">
          <div className="aspect-square h-full max-h-[700px] border border-border-muted bg-surface/20 rounded-xl relative grid-bg p-4 shadow-[0_0_50px_rgba(0,245,255,0.05)] overflow-hidden">
            <ArenaRenderer 
              arenaId={currentArenaId} 
              gridSize={arena ? Number(arena.gridSize) : 20} 
              onEventSpawn={handleEventSpawn}
            />
          </div>
        </div>

        {/* Legend */}
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
        {/* Leaderboard */}
        <div className="flex-1 flex flex-col p-6 min-h-0 border-b border-border-muted">
          <h3 className="text-xs uppercase tracking-widest text-slate-500 font-bold mb-4">Leaderboard</h3>
          <div className="overflow-y-auto terminal-scroll pr-2">
            {aliveCreatures.length === 0 ? (
              <p className="text-slate-500 italic text-center mt-4 text-sm">No creatures yet...</p>
            ) : (
              <table className="w-full text-left">
                <thead>
                  <tr className="text-[10px] uppercase text-slate-500 border-b border-border-muted">
                    <th className="pb-2 font-bold">ID</th>
                    <th className="pb-2 font-bold">Owner</th>
                    <th className="pb-2 font-bold text-right">Stat</th>
                  </tr>
                </thead>
                <tbody className="text-sm">
                  {aliveCreatures.sort((a: any, b: any) => Number(b.hp) - Number(a.hp)).slice(0, 10).map((c: any) => (
                    <tr key={c.id.toString()} className="border-b border-white/5 hover:bg-white/5 transition-colors">
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
            )}
          </div>
        </div>

        {/* Event Log */}
        <div className="flex-1 flex flex-col p-6 min-h-0 bg-background-dark/30">
          <div className="flex items-center justify-between mb-4">
            <h3 className="text-xs uppercase tracking-widest text-slate-500 font-bold">Evolution Log</h3>
            <span className="w-2 h-2 rounded-full bg-accent-cyan animate-pulse"></span>
          </div>
          <div className="overflow-y-auto terminal-scroll text-xs font-mono space-y-1">
            {logs.length === 0 ? (
              <p className="text-slate-500 italic text-center mt-4">No events yet...</p>
            ) : (
              logs.map((log) => (
                <p key={log.id} className="text-slate-300">
                  <span className="text-slate-600">
                    [{log.timestamp.toLocaleTimeString([], { hour12: false })}]
                  </span>{' '}
                  {log.message}
                </p>
              ))
            )}
          </div>
        </div>
      </aside>
    </div>
  );
}

export default App;
