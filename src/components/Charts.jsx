import { useState } from 'react';

/**
 * Tiny dependency-free SVG charts. Responsive via viewBox; styling via CSS vars.
 * Both charts ship a hover/tap layer (tooltip on nearest mark) and keep text
 * unstretched by scaling proportionally instead of preserveAspectRatio="none".
 */

function Tooltip({ x, y, W, lines }) {
  const width = Math.max(...lines.map(l => l.length)) * 6.2 + 14;
  const height = lines.length * 14 + 10;
  const tx = Math.min(Math.max(x - width / 2, 2), W - width - 2);
  const ty = y - height - 10 < 2 ? y + 12 : y - height - 10;
  return (
    <g pointerEvents="none">
      <rect x={tx} y={ty} width={width} height={height} rx="5"
        fill="var(--bg-elevated)" stroke="var(--border-default)" strokeWidth="1" />
      {lines.map((line, i) => (
        <text key={i} x={tx + width / 2} y={ty + 15 + i * 14} textAnchor="middle"
          fontSize="10" fontWeight={i === lines.length - 1 ? 700 : 400}
          fill={i === lines.length - 1 ? 'var(--text-primary)' : 'var(--text-secondary)'}>
          {line}
        </text>
      ))}
    </g>
  );
}

function formatShortDate(dateStr) {
  if (!dateStr) return '';
  const d = new Date(dateStr + 'T00:00:00');
  return isNaN(d) ? dateStr : d.toLocaleDateString('en-US', { month: 'short', day: 'numeric' });
}

export function LineChart({ data = [], height = 160, stroke = 'var(--accent-primary)', fill = 'var(--accent-primary-glow)', unit = '' }) {
  const [hover, setHover] = useState(null); // index of hovered point

  if (!data || data.length === 0) {
    return <div className="chart-empty">No data yet</div>;
  }
  const W = 320;
  const H = height;
  const padX = 8;
  const padY = 14;
  const values = data.map(d => d.value);
  const min = Math.min(...values);
  const max = Math.max(...values);
  const range = max - min || 1;
  const n = data.length;

  const x = (i) => padX + (n === 1 ? (W - 2 * padX) / 2 : (i / (n - 1)) * (W - 2 * padX));
  const y = (v) => padY + (1 - (v - min) / range) * (H - 2 * padY);

  const linePts = data.map((d, i) => `${x(i)},${y(d.value)}`).join(' ');
  const areaPts = `${x(0)},${H - padY} ${linePts} ${x(n - 1)},${H - padY}`;
  const last = data[data.length - 1];

  // Hover state can outlive a shrinking data prop (e.g. the exercise <select>
  // swaps in a shorter series while a touch-hover is stuck) — clamp it.
  const hi = hover !== null && hover < n ? hover : null;

  const handleMove = (e) => {
    const rect = e.currentTarget.getBoundingClientRect();
    const px = ((e.clientX - rect.left) / rect.width) * W;
    // Points are evenly spaced, so the nearest index is the inverse of x(i).
    const step = n === 1 ? 1 : (W - 2 * padX) / (n - 1);
    setHover(Math.max(0, Math.min(n - 1, Math.round((px - padX) / step))));
  };

  return (
    <svg viewBox={`0 0 ${W} ${H}`} width="100%" style={{ height: 'auto', display: 'block', touchAction: 'pan-y' }} role="img"
      onPointerMove={handleMove} onPointerLeave={() => setHover(null)} onPointerCancel={() => setHover(null)}>
      {/* recessive gridlines */}
      {[0.25, 0.5, 0.75].map(t => (
        <line key={t} x1={padX} x2={W - padX} y1={padY + t * (H - 2 * padY)} y2={padY + t * (H - 2 * padY)}
          stroke="var(--border-subtle)" strokeWidth="1" />
      ))}
      <polyline points={areaPts} fill={fill} stroke="none" />
      <polyline points={linePts} fill="none" stroke={stroke} strokeWidth="2" strokeLinejoin="round" strokeLinecap="round" />
      {data.map((d, i) => (
        <circle key={i} cx={x(i)} cy={y(d.value)} r={i === hi ? 5 : (i === n - 1 ? 3.5 : 2)}
          fill={i === hi ? 'var(--bg-card)' : stroke}
          stroke={stroke} strokeWidth={i === hi ? 2 : 0} />
      ))}
      {hi === null && (
        <text x={W - padX} y={Math.max(12, y(last.value) - 8)} textAnchor="end" fontSize="11" fill="var(--text-secondary)">
          {Math.round(last.value).toLocaleString()}{unit}
        </text>
      )}
      {hi !== null && (
        <>
          <line x1={x(hi)} x2={x(hi)} y1={padY} y2={H - padY} stroke="var(--border-default)" strokeWidth="1" strokeDasharray="3 3" />
          <Tooltip
            x={x(hi)} y={y(data[hi].value)} W={W}
            lines={[formatShortDate(data[hi].date), `${Math.round(data[hi].value).toLocaleString()}${unit}`]}
          />
        </>
      )}
    </svg>
  );
}

export function BarChart({ data = [], height = 140, color = 'var(--accent-primary)', unit = '' }) {
  const [hover, setHover] = useState(null);

  if (!data || data.length === 0) {
    return <div className="chart-empty">No data yet</div>;
  }
  const W = 320;
  const H = height;
  const padY = 16;
  const n = data.length;
  const gap = 4;
  const barW = (W / n) - gap;
  const max = Math.max(...data.map(d => d.value)) || 1;
  const hi = hover !== null && hover < n ? hover : null; // clamp stale hover on data change

  return (
    <svg viewBox={`0 0 ${W} ${H}`} width="100%" style={{ height: 'auto', display: 'block', touchAction: 'pan-y' }} role="img"
      onPointerLeave={() => setHover(null)} onPointerCancel={() => setHover(null)}>
      {data.map((d, i) => {
        const h = (d.value / max) * (H - 2 * padY);
        const xPos = i * (barW + gap) + gap / 2;
        const isActive = i === hi || (hi === null && i === n - 1);
        return (
          <g key={i}>
            <rect
              x={xPos}
              y={H - padY - h}
              width={barW}
              height={Math.max(h, d.value > 0 ? 2 : 0)}
              rx="3"
              fill={color}
              opacity={isActive ? 1 : 0.55}
            />
            {/* full-height hit target so thin bars are easy to hover/tap */}
            <rect x={xPos - gap / 2} y={0} width={barW + gap} height={H} fill="transparent"
              onPointerEnter={() => setHover(i)} onPointerDown={() => setHover(i)} />
            {d.label && (
              <text x={xPos + barW / 2} y={H - 4} textAnchor="middle" fontSize="9" fill="var(--text-tertiary)" pointerEvents="none">
                {d.label}
              </text>
            )}
          </g>
        );
      })}
      {hi !== null && (
        <Tooltip
          x={hi * (barW + gap) + gap / 2 + barW / 2}
          y={H - padY - (data[hi].value / max) * (H - 2 * padY)}
          W={W}
          lines={[
            ...(data[hi].date ? [formatShortDate(data[hi].date)] : []),
            `${Math.round(data[hi].value).toLocaleString()}${unit}`,
          ]}
        />
      )}
    </svg>
  );
}
