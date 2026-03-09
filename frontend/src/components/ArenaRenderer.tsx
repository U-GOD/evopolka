import { useRef, useEffect } from 'react';
import { useCreatures } from '../hooks/useCreatures';

// Types mapping what we get from the contract
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

interface ArenaRendererProps {
  arenaId: bigint;
  gridSize: number;
}

export function ArenaRenderer({ arenaId, gridSize }: ArenaRendererProps) {
  const canvasRef = useRef<HTMLCanvasElement>(null);
  const containerRef = useRef<HTMLDivElement>(null);
  const animationRef = useRef<number>(0);
  
  // Real-time creatures from chain (polling)
  const { creatures } = useCreatures(arenaId);
  const creaturesData = (creatures as unknown as Creature[]) || [];

  useEffect(() => {
    const canvas = canvasRef.current;
    const container = containerRef.current;
    if (!canvas || !container) return;

    const ctx = canvas.getContext('2d');
    if (!ctx) return;

    // Handle high DPI displays for sharp rendering
    const updateSize = () => {
      const rect = container.getBoundingClientRect();
      const dpr = window.devicePixelRatio || 1;
      canvas.width = rect.width * dpr;
      canvas.height = rect.height * dpr;
      ctx.scale(dpr, dpr);
      canvas.style.width = `${rect.width}px`;
      canvas.style.height = `${rect.height}px`;
    };

    updateSize();
    window.addEventListener('resize', updateSize);

    // Render loop
    const render = () => {
      // Clear canvas
      ctx.clearRect(0, 0, canvas.width, canvas.height);
      
      const rect = container.getBoundingClientRect();
      const w = rect.width;
      const h = rect.height;
      const cellSize = Math.min(w, h) / gridSize;
      const ox = (w - cellSize * gridSize) / 2;
      const oy = (h - cellSize * gridSize) / 2;

      // 1. Draw Grid
      ctx.strokeStyle = 'rgba(255, 255, 255, 0.05)';
      ctx.lineWidth = 1;
      
      // Vertical lines
      for (let i = 0; i <= gridSize; i++) {
        ctx.beginPath();
        ctx.moveTo(ox + i * cellSize, oy);
        ctx.lineTo(ox + i * cellSize, oy + gridSize * cellSize);
        ctx.stroke();
      }
      // Horizontal lines
      for (let i = 0; i <= gridSize; i++) {
        ctx.beginPath();
        ctx.moveTo(ox, oy + i * cellSize);
        ctx.lineTo(ox + gridSize * cellSize, oy + i * cellSize);
        ctx.stroke();
      }

      // 2. Draw Creatures
      for (const creature of creaturesData) {
        if (!creature.alive) continue;
        
        const cx = ox + creature.x * cellSize + cellSize / 2;
        const cy = oy + creature.y * cellSize + cellSize / 2;
        
        // Derive color from aggression/intelligence for now
        // High aggression = red/pink, High int = blue/cyan, High defense = green
        const r = Math.min(255, creature.aggression * 2.5);
        const g = Math.min(255, creature.defense * 2.5);
        const b = Math.min(255, creature.intelligence * 2.5);
        
        ctx.fillStyle = `rgb(${r}, ${g}, ${b})`;
        
        // Size proportional to HP
        const radius = (cellSize / 2) * (Number(creature.hp) / 100) * 0.8;
        
        ctx.beginPath();
        ctx.arc(cx, cy, Math.max(radius, 2), 0, Math.PI * 2);
        ctx.fill();
        
        // Glow effect
        ctx.shadowColor = ctx.fillStyle;
        ctx.shadowBlur = 10;
        ctx.fill();
        ctx.shadowBlur = 0;
      }

      animationRef.current = requestAnimationFrame(render);
    };

    render();

    return () => {
      window.removeEventListener('resize', updateSize);
      if (animationRef.current) cancelAnimationFrame(animationRef.current);
    };
  }, [gridSize, creaturesData]);

  return (
    <div ref={containerRef} className="w-full h-full absolute inset-0">
      <canvas ref={canvasRef} className="block" />
    </div>
  );
}
