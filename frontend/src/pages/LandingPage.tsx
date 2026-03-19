import { Link } from 'react-router-dom';
import { Cpu, Dna, Trophy } from 'lucide-react';
import { ConnectButton } from '../components/ConnectButton';

export function LandingPage() {
  return (
    <div className="font-sans text-white antialiased min-h-screen">
      {/* BEGIN: Navigation */}
      <nav className="sticky top-0 z-50 border-b border-white/10 bg-background-dark/80 backdrop-blur-md">
        <div className="mx-auto flex h-20 max-w-7xl items-center justify-between px-6">
          <div className="flex items-center gap-2">
            <div className="h-8 w-8 bg-primary rounded-lg rotate-45 flex items-center justify-center">
              <div className="h-4 w-4 bg-background-dark rounded-sm"></div>
            </div>
            <span className="text-2xl font-bold tracking-tighter">
              EVO<span className="text-primary">POLKA</span>
            </span>
          </div>
          <div className="hidden md:flex items-center gap-8 text-sm font-medium">
            <Link to="/arena" className="hover:text-primary transition-colors">Arena</Link>
            <a className="hover:text-primary transition-colors cursor-pointer">Leaderboard</a>
            <a className="hover:text-primary transition-colors cursor-pointer">Docs</a>
            <ConnectButton />
          </div>
        </div>
      </nav>
      {/* END: Navigation */}

      <main>
        {/* BEGIN: Hero Section */}
        <section className="relative overflow-hidden py-24 lg:py-32">
          <div className="mx-auto max-w-7xl px-6 lg:grid lg:grid-cols-2 lg:gap-12 items-center">
            <div className="text-center lg:text-left">
              <div className="inline-flex items-center rounded-full px-3 py-1 text-xs font-semibold bg-primary/10 text-primary border border-primary/20 mb-6">
                <span className="mr-2 h-2 w-2 rounded-full bg-primary animate-pulse"></span>
                LIVE ON POLKADOT ASSET HUB
              </div>
              <h1 className="text-5xl font-extrabold tracking-tight sm:text-7xl mb-6 glow-text-pink leading-tight">
                Survival of the Fittest, <span className="text-accent-cyan">Verified.</span>
              </h1>
              <p className="text-lg text-slate-400 mb-10 max-w-xl mx-auto lg:mx-0">
                Deploy immutable DNA. Stake tokens. Let your cellular automaton fight for the prize pool in a deterministic, fully on-chain arena powered by the Polkadot Virtual Machine.
              </p>
              <div className="flex flex-col sm:flex-row gap-4 justify-center lg:justify-start">
                <Link to="/arena">
                  <button className="bg-primary hover:bg-pink-600 text-white font-bold py-4 px-8 rounded-lg glow-pink transition-all transform hover:scale-105 w-full sm:w-auto">
                    Enter Arena
                  </button>
                </Link>
                <button className="border border-accent-cyan/50 hover:border-accent-cyan text-accent-cyan font-bold py-4 px-8 rounded-lg transition-all w-full sm:w-auto">
                  Read Docs
                </button>
              </div>
            </div>

            {/* Visual Asset: Simulation Grid */}
            <div className="mt-16 lg:mt-0 flex justify-center lg:justify-end">
              <div className="relative w-full max-w-[450px] aspect-square p-4 glass-panel rounded-xl border-accent-cyan/20 animate-float">
                <div className="absolute inset-0 bg-accent-cyan/5 blur-3xl rounded-full"></div>
                {/* 10x10 Grid Simulation */}
                <div className="relative grid grid-cols-10 grid-rows-10 h-full w-full gap-1 p-2 bg-black/40 rounded-sm">
                  {Array.from({ length: 100 }).map((_, i) => {
                    // Place some glowing dots in specific cells to mimic the HTML
                    let content = null;
                    if (i === 11) content = <div className="h-2 w-2 bg-primary rounded-full animate-pulse shadow-[0_0_8px_#f4259d]"></div>;
                    if (i === 34) content = <div className="h-2 w-2 bg-accent-cyan rounded-full animate-bounce shadow-[0_0_8px_#00f5ff]"></div>;
                    if (i === 56) content = <div className="h-2 w-2 bg-accent-mint rounded-full animate-pulse shadow-[0_0_8px_#34d399]"></div>;
                    if (i === 72) content = <div className="h-2 w-2 bg-primary rounded-full animate-ping shadow-[0_0_8px_#f4259d]"></div>;
                    if (i === 97) content = <div className="h-2 w-2 bg-accent-cyan rounded-full animate-pulse shadow-[0_0_8px_#00f5ff]"></div>;

                    return (
                      <div key={i} className="border border-accent-cyan/10 flex items-center justify-center">
                        {content}
                      </div>
                    );
                  })}
                </div>
                {/* UI Overlay for visual depth */}
                <div className="absolute -bottom-6 -right-6 p-4 glass-panel rounded-xl border-primary/30 w-48 shadow-2xl">
                  <div className="text-[10px] text-primary font-mono mb-2 uppercase tracking-widest">Process Logic</div>
                  <div className="space-y-1">
                    <div className="h-1.5 w-full bg-white/10 rounded-full overflow-hidden">
                      <div className="h-full bg-primary w-2/3"></div>
                    </div>
                    <div className="h-1.5 w-full bg-white/10 rounded-full overflow-hidden">
                      <div className="h-full bg-accent-cyan w-1/2"></div>
                    </div>
                  </div>
                </div>
              </div>
            </div>
          </div>
        </section>
        {/* END: Hero Section */}

        {/* BEGIN: Features Grid */}
        <section className="py-24 bg-black/30 border-y border-white/5">
          <div className="mx-auto max-w-7xl px-6">
            <div className="mb-16 text-center">
              <h2 className="text-3xl font-bold tracking-tight sm:text-4xl">Core Protocol Modules</h2>
              <div className="mt-4 h-1 w-20 bg-primary mx-auto"></div>
            </div>
            <div className="grid grid-cols-1 md:grid-cols-3 gap-8">
              {/* Card 1 */}
              <div className="p-8 rounded-xl glass-panel border-white/5 hover:border-primary/50 transition-all group">
                <div className="mb-6 h-12 w-12 rounded-xl bg-primary/10 flex items-center justify-center text-primary group-hover:bg-primary group-hover:text-white transition-colors">
                  <Cpu className="w-6 h-6" />
                </div>
                <h3 className="text-xl font-bold mb-3">100% On-Chain Engine</h3>
                <p className="text-slate-400 leading-relaxed">
                  Every tick, movement, and collision is computed within a deterministic PVM state machine. Zero server-side bias, total decentralization.
                </p>
              </div>
              {/* Card 2 */}
              <div className="p-8 rounded-xl glass-panel border-white/5 hover:border-accent-cyan/50 transition-all group">
                <div className="mb-6 h-12 w-12 rounded-xl bg-accent-cyan/10 flex items-center justify-center text-accent-cyan group-hover:bg-accent-cyan group-hover:text-black transition-colors">
                  <Dna className="w-6 h-6" />
                </div>
                <h3 className="text-xl font-bold mb-3">DNA-based Combat</h3>
                <p className="text-slate-400 leading-relaxed">
                  Stats like Speed, Strength, and Intelligence are parsed directly from pseudo-random genome bytes stored on the ledger.
                </p>
              </div>
              {/* Card 3 */}
              <div className="p-8 rounded-xl glass-panel border-white/5 hover:border-accent-mint/50 transition-all group">
                <div className="mb-6 h-12 w-12 rounded-xl bg-accent-mint/10 flex items-center justify-center text-accent-mint group-hover:bg-accent-mint group-hover:text-black transition-colors">
                  <Trophy className="w-6 h-6" />
                </div>
                <h3 className="text-xl font-bold mb-3">Winner Takes All</h3>
                <p className="text-slate-400 leading-relaxed">
                  The last surviving organism inherits the staked DOT/DEV token pot automatically through a trustless smart contract execution.
                </p>
              </div>
            </div>
          </div>
        </section>
        {/* BEGIN: How It Works */}
        <section className="py-24 relative overflow-hidden">
          <div className="absolute top-1/2 left-1/2 -translate-x-1/2 -translate-y-1/2 w-[800px] h-[800px] bg-primary/5 blur-[120px] rounded-full pointer-events-none"></div>
          <div className="mx-auto max-w-7xl px-6 relative z-10">
            <div className="mb-16 text-center">
              <h2 className="text-3xl font-bold tracking-tight sm:text-4xl">How It Works</h2>
              <p className="mt-4 text-slate-400 max-w-2xl mx-auto">From DNA generation to claiming the prize pot, the entire lifecycle is verifiable on the Polkadot Virtual Machine.</p>
            </div>
            
            <div className="grid grid-cols-1 md:grid-cols-4 gap-8 relative">
              {/* Connecting Line */}
              <div className="hidden md:block absolute top-12 left-[12%] right-[12%] h-0.5 bg-gradient-to-r from-primary/10 via-accent-cyan/20 to-accent-mint/10 z-0"></div>
              
              {/* Step 1 */}
              <div className="relative z-10 text-center">
                <div className="w-24 h-24 mx-auto glass-panel rounded-full flex items-center justify-center text-3xl font-black text-white border-primary/30 shadow-[0_0_30px_rgba(244,37,157,0.15)] mb-6">1</div>
                <h3 className="text-xl font-bold mb-2 text-white">Stake & Spawn</h3>
                <p className="text-sm text-slate-400">Deposit PAS tokens into the smart contract to mint a creature with a randomized 256-bit genome.</p>
              </div>
              
              {/* Step 2 */}
              <div className="relative z-10 text-center md:mt-12">
                <div className="w-24 h-24 mx-auto glass-panel rounded-full flex items-center justify-center text-3xl font-black text-white border-accent-cyan/30 shadow-[0_0_30px_rgba(0,245,255,0.15)] mb-6">2</div>
                <h3 className="text-xl font-bold mb-2 text-white">Automata Engine</h3>
                <p className="text-sm text-slate-400">The game ticks block-by-block. Creatures move autonomously, forage for food, and attack weak neighbors based on their DNA stats.</p>
              </div>
              
              {/* Step 3 */}
              <div className="relative z-10 text-center">
                <div className="w-24 h-24 mx-auto glass-panel rounded-full flex items-center justify-center text-3xl font-black text-white border-purple-500/30 shadow-[0_0_30px_rgba(168,85,247,0.15)] mb-6">3</div>
                <h3 className="text-xl font-bold mb-2 text-white">Mutate & Breed</h3>
                <p className="text-sm text-slate-400">Top performers cross over their genes to spawn the next generation. A cryptographic hash provides entropy for mutations.</p>
              </div>
              
              {/* Step 4 */}
              <div className="relative z-10 text-center md:mt-12">
                <div className="w-24 h-24 mx-auto glass-panel rounded-full flex items-center justify-center text-3xl font-black text-white border-accent-mint/30 shadow-[0_0_30px_rgba(52,211,153,0.15)] mb-6">4</div>
                <h3 className="text-xl font-bold mb-2 text-white">Survival of the Fittest</h3>
                <p className="text-sm text-slate-400">The simulation ends after N rounds. Owners of surviving creatures pull their share of the aggregated token prize pool.</p>
              </div>
            </div>
          </div>
        </section>
        {/* END: How It Works */}

        {/* BEGIN: Call to Action */}
        <section className="py-24 relative">
          <div className="mx-auto max-w-4xl px-6">
            <div className="relative rounded-2xl bg-gradient-to-br from-primary/20 to-accent-cyan/20 p-12 overflow-hidden border border-white/10 text-center">
              <div className="absolute -top-24 -left-24 h-64 w-64 bg-primary/20 blur-[100px] rounded-full"></div>
              <div className="absolute -bottom-24 -right-24 h-64 w-64 bg-accent-cyan/20 blur-[100px] rounded-full"></div>
              <h2 className="text-4xl font-bold mb-6 relative z-10">Ready to Evolve?</h2>
              <p className="text-slate-300 mb-10 text-lg max-w-lg mx-auto relative z-10">
                Join the current epoch. Deposit 10 DOT to spawn your creature and compete against 100+ daily participants.
              </p>
              <div className="flex justify-center gap-6 relative z-10">
                <Link to="/arena">
                  <button className="bg-white text-background-dark font-bold px-10 py-4 rounded-xl hover:bg-slate-200 transition-colors">
                    Deploy Organism
                  </button>
                </Link>
              </div>
            </div>
          </div>
        </section>
        {/* END: Call to Action */}
      </main>

      {/* BEGIN: Footer */}
      <footer className="border-t border-white/5 py-12 bg-background-dark">
        <div className="mx-auto max-w-7xl px-6 flex flex-col md:flex-row justify-between items-center gap-8">
          <div className="flex items-center gap-2 grayscale opacity-70">
            <div className="h-6 w-6 bg-white rounded-lg rotate-45 flex items-center justify-center"></div>
            <span className="text-lg font-bold">EVOPOLKA</span>
          </div>
          <div className="flex gap-8 text-slate-500 text-sm">
            <a className="hover:text-white transition-colors cursor-pointer">Twitter</a>
            <a className="hover:text-white transition-colors cursor-pointer">Discord</a>
            <a className="hover:text-white transition-colors cursor-pointer">Github</a>
            <a className="hover:text-white transition-colors cursor-pointer">Polkadot.js</a>
          </div>
          <p className="text-slate-500 text-sm">
            © 2026 EvoPolka Lab. Fully Decentralized.
          </p>
        </div>
      </footer>
      {/* END: Footer */}
    </div>
  );
}
