import { useRef, useEffect, useCallback } from 'react';
import { useCreatures } from '../hooks/useCreatures';

// ─── Types ---------------------------------------------------------------

interface Creature {
  id: bigint;
  owner: string;
  speed: number;
  strength: number;
  intelligence: number;
  aggression: number;
  reproRate: number;
  defense: number;
  energy: number;
  hp: number;
  x: number;
  y: number;
  generation: number;
  alive: boolean;
  genome: string;
}

interface Particle {
  x: number;
  y: number;
  vx: number;
  vy: number;
  alpha: number;
  color: string;
  size: number;
  type: 'spark' | 'birth' | 'death';
}

interface ArenaRendererProps {
  arenaId: bigint;
  gridSize: number;
  /** Pass combat / birth events so we can spawn particles */
  onEventSpawn?: (spawnParticle: (x: number, y: number, type: Particle['type']) => void) => void;
}

// ─── Colour helpers -------------------------------------------------------

/** Derive a vibrant RGB string from on-chain genome bytes */
function genomeToColor(genome: string, hp: number): string {
  // Use the first 3 bytes of genome string as hue seed
  const seed = parseInt(genome?.slice(2, 8) || 'a1b2c3', 16);
  const hue = seed % 360;
  // Shift saturation/lightness based on hp — dimmer as they die
  const sat = 70 + (hp / 100) * 30;
  const lit = 40 + (hp / 100) * 25;
  return `hsl(${hue}, ${sat}%, ${lit}%)`;
}

/** Brighter version for the glow shadow */
function genomeToGlow(genome: string): string {
  const seed = parseInt(genome?.slice(2, 8) || 'a1b2c3', 16);
  const hue = seed % 360;
  return `hsl(${hue}, 100%, 70%)`;
}

// ─── Component -----------------------------------------------------------

export function ArenaRenderer({ arenaId, gridSize, onEventSpawn }: ArenaRendererProps) {
  const canvasRef = useRef<HTMLCanvasElement>(null);
  const containerRef = useRef<HTMLDivElement>(null);
  const animationRef = useRef<number>(0);
  const particlesRef = useRef<Particle[]>([]);

  const { creatures } = useCreatures(arenaId);
  const creaturesData = (creatures as unknown as Creature[]) || [];

  // ─── Particle spawner (exposed to parent via callback) ──────────────────
  const spawnParticles = useCallback(
    (worldX: number, worldY: number, type: Particle['type']) => {
      const canvas = canvasRef.current;
      const container = containerRef.current;
      if (!canvas || !container) return;

      const rect = container.getBoundingClientRect();
      const cellSize = Math.min(rect.width, rect.height) / gridSize;
      const ox = (rect.width - cellSize * gridSize) / 2;
      const oy = (rect.height - cellSize * gridSize) / 2;
      const cx = ox + worldX * cellSize + cellSize / 2;
      const cy = oy + worldY * cellSize + cellSize / 2;

      const count = type === 'spark' ? 12 : type === 'death' ? 20 : 8;
      const color = type === 'spark' ? '#f4259d' : type === 'death' ? '#ff4444' : '#00f5ff';

      for (let i = 0; i < count; i++) {
        const angle = (Math.PI * 2 * i) / count + Math.random() * 0.5;
        const speed = (Math.random() + 0.5) * (type === 'death' ? 3.5 : 2.0);
        particlesRef.current.push({
          x: cx,
          y: cy,
          vx: Math.cos(angle) * speed,
          vy: Math.sin(angle) * speed,
          alpha: 1.0,
          color,
          size: Math.random() * 3 + 1.5,
          type,
        });
      }
    },
    [gridSize]
  );

  // Expose spawner to parent
  useEffect(() => {
    onEventSpawn?.(spawnParticles);
  }, [onEventSpawn, spawnParticles]);

  // ─── Main render loop ──────────────────────────────────────────────────
  useEffect(() => {
    const canvas = canvasRef.current;
    const container = containerRef.current;
    if (!canvas || !container) return;

    const ctx = canvas.getContext('2d');
    if (!ctx) return;

    // Hi-DPI setup
    const updateSize = () => {
      const r = container.getBoundingClientRect();
      const dpr = window.devicePixelRatio || 1;
      canvas.width = r.width * dpr;
      canvas.height = r.height * dpr;
      canvas.style.width = `${r.width}px`;
      canvas.style.height = `${r.height}px`;
      ctx.scale(dpr, dpr);
    };
    updateSize();
    window.addEventListener('resize', updateSize);

    const render = () => {
      const r = container.getBoundingClientRect();
      const w = r.width;
      const h = r.height;
      const cellSize = Math.min(w, h) / gridSize;
      const ox = (w - cellSize * gridSize) / 2;
      const oy = (h - cellSize * gridSize) / 2;

      // Clear with slight fade trail for motion blur feel
      ctx.fillStyle = 'rgba(10, 10, 18, 0.6)';
      ctx.fillRect(0, 0, w, h);

      // 1 ── Grid ──────────────────────────────────────────────────────────
      ctx.strokeStyle = 'rgba(255, 255, 255, 0.04)';
      ctx.lineWidth = 0.5;
      for (let i = 0; i <= gridSize; i++) {
        ctx.beginPath();
        ctx.moveTo(ox + i * cellSize, oy);
        ctx.lineTo(ox + i * cellSize, oy + gridSize * cellSize);
        ctx.stroke();
        ctx.beginPath();
        ctx.moveTo(ox, oy + i * cellSize);
        ctx.lineTo(ox + gridSize * cellSize, oy + i * cellSize);
        ctx.stroke();
      }

      // 2 ── Creatures ─────────────────────────────────────────────────────
      for (const c of creaturesData) {
        if (!c.alive) continue;

        const cx = ox + c.x * cellSize + cellSize / 2;
        const cy = oy + c.y * cellSize + cellSize / 2;
        const hpNorm = Math.max(0, Math.min(1, Number(c.hp) / 100));
        const radius = (cellSize / 2) * hpNorm * 0.75 + 2;
        const color = genomeToColor(c.genome, Number(c.hp));
        const glow = genomeToGlow(c.genome);

        // Outer glow ring (HP)
        ctx.save();
        ctx.shadowColor = glow;
        ctx.shadowBlur = 14 * hpNorm;
        ctx.fillStyle = color;
        ctx.beginPath();
        ctx.arc(cx, cy, radius, 0, Math.PI * 2);
        ctx.fill();
        ctx.restore();

        // Energy Display (White Dashed Ring)
        const energyNorm = Math.max(0, Math.min(1, Number(c.energy) / 100));
        if (energyNorm > 0) {
            ctx.save();
            ctx.strokeStyle = 'rgba(255, 255, 255, 0.6)';
            ctx.lineWidth = 1.5;
            ctx.setLineDash([3, 4]); // dashed ring for energy
            ctx.beginPath();
            ctx.arc(cx, cy, radius + 4, 0, Math.PI * 2 * energyNorm);
            ctx.stroke();
            ctx.restore();
        }

        // Inner bright core
        ctx.save();
        ctx.globalAlpha = 0.6 + 0.4 * hpNorm;
        ctx.fillStyle = glow;
        ctx.beginPath();
        ctx.arc(cx, cy, radius * 0.35, 0, Math.PI * 2);
        ctx.fill();
        ctx.restore();
      }

      // 3 ── Particles ─────────────────────────────────────────────────────
      particlesRef.current = particlesRef.current.filter(p => p.alpha > 0.02);
      for (const p of particlesRef.current) {
        ctx.save();
        ctx.globalAlpha = p.alpha;
        ctx.shadowColor = p.color;
        ctx.shadowBlur = 6;
        ctx.fillStyle = p.color;
        ctx.beginPath();
        ctx.arc(p.x, p.y, p.size, 0, Math.PI * 2);
        ctx.fill();
        ctx.restore();

        // Physics
        p.x += p.vx;
        p.y += p.vy;
        p.vx *= 0.92;
        p.vy *= 0.92;
        p.alpha -= p.type === 'death' ? 0.028 : 0.04;
        p.size *= 0.97;
      }

      animationRef.current = requestAnimationFrame(render);
    };

    render();

    return () => {
      window.removeEventListener('resize', updateSize);
      cancelAnimationFrame(animationRef.current);
    };
  }, [gridSize, creaturesData]);

  return (
    <div ref={containerRef} className="w-full h-full absolute inset-0">
      <canvas ref={canvasRef} className="block" />
    </div>
  );
}
