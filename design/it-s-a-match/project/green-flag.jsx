// GreenFlag — a modern, modular waving flag built from animated SVG paths.
//
// The flag is a tessellated quad: 32 vertical slices. Top and bottom y of
// each slice oscillate on a sine wave whose amplitude grows with distance
// from the pole (attached edge is rigid). We pipe the slice points through
// a smooth quadratic spline so the silhouette stays liquid-smooth.
//
// Three sheen layers overlay the base: a soft white highlight strip that
// drifts across, a darker fold band that traces the wave trough, and a
// subtle horizontal weave gradient. Together they read as silk, not card.
//
// Props:
//   t        — time in seconds since unfurl began (drives the wave)
//   unfurl   — 0→1 reveal progress (clip-path scaleX from the pole)
//   variant  — 'silk' | 'pennant' | 'banner'
//   amp      — wave amplitude multiplier (default 1)

const TREMBLE_GREEN = '#2D9B6F';
const TREMBLE_GREEN_DARK = '#1E6B4D';
const TREMBLE_GREEN_LIGHT = '#5BBF93';

function GreenFlag({ t = 0, unfurl = 1, variant = 'silk', amp = 1 }) {
  // Geometry — viewBox is 240×180; pole on the left at x=20.
  const POLE_X = 22;
  const FLAG_X = POLE_X;
  const FLAG_W = variant === 'pennant' ? 200 : 188;
  const FLAG_H = variant === 'banner' ? 64 : variant === 'pennant' ? 96 : 110;
  const FLAG_TOP = 32;
  const SEGS = 36;

  // Build top & bottom edge points for the flag silhouette.
  const top = [];
  const bot = [];
  for (let i = 0; i <= SEGS; i++) {
    const u = i / SEGS;                                  // 0..1 along width
    const x = FLAG_X + u * FLAG_W;
    const ampScale = Math.min(1, Math.pow(u, 0.85) * 1.25); // grows w/ distance
    // Two layered sine waves at different frequencies — feels less mechanical
    const wave =
      (Math.sin(u * Math.PI * 2.6 - t * 3.4) * 7 +
       Math.sin(u * Math.PI * 4.1 - t * 5.1) * 2.4) * ampScale * amp;
    // Gravity droop on free edge
    const droop = ampScale * 6;
    // Pennant tapers — bottom moves up toward right
    const taper = variant === 'pennant' ? Math.pow(u, 1.2) * FLAG_H * 0.42 : 0;
    top.push({ x, y: FLAG_TOP + wave });
    bot.push({ x, y: FLAG_TOP + FLAG_H + wave - taper + droop * 0.18 });
  }

  // Smooth a list of points into a "L x,y T x,y T x,y..." path string.
  // Using Catmull-Rom-ish quadratic smoothing (T command reflects previous control).
  const toPath = (pts, reverse = false) => {
    const ordered = reverse ? [...pts].reverse() : pts;
    let d = `${reverse ? 'L' : 'M'} ${ordered[0].x.toFixed(2)} ${ordered[0].y.toFixed(2)}`;
    for (let i = 1; i < ordered.length - 1; i++) {
      const p = ordered[i];
      const n = ordered[i + 1];
      const xc = (p.x + n.x) / 2;
      const yc = (p.y + n.y) / 2;
      d += ` Q ${p.x.toFixed(2)} ${p.y.toFixed(2)} ${xc.toFixed(2)} ${yc.toFixed(2)}`;
    }
    const last = ordered[ordered.length - 1];
    d += ` L ${last.x.toFixed(2)} ${last.y.toFixed(2)}`;
    return d;
  };

  const flagPath = `${toPath(top)} ${toPath(bot, true)} Z`;

  // A mid-line that tracks the wave at half-height — used for fold shading.
  const mid = top.map((p, i) => ({
    x: p.x,
    y: (p.y + bot[i].y) / 2,
  }));

  // Compute shear angle from the wave at three sample points → used for sheen tilt.
  const sheenStripes = [];
  for (let s = 0; s < 5; s++) {
    const u = 0.15 + s * 0.18;
    const idx = Math.round(u * SEGS);
    const slope = bot[idx].y - top[idx].y;
    const xOff = Math.sin(u * Math.PI * 2.6 - t * 3.4) * 6;
    sheenStripes.push({
      x: FLAG_X + u * FLAG_W + xOff,
      yTop: top[idx].y,
      yBot: bot[idx].y,
      h: slope,
      opacity: 0.04 + 0.06 * (0.5 + 0.5 * Math.sin(u * 7 - t * 2.3)),
    });
  }

  // Reveal clip: as `unfurl` grows from 0→1, the flag width emerges from the pole.
  const clipW = Math.max(0.001, unfurl) * (FLAG_W + 20);

  return (
    <svg
      viewBox="0 0 240 200"
      width="100%"
      height="100%"
      style={{ overflow: 'visible', display: 'block' }}
    >
      <defs>
        {/* Base green gradient */}
        <linearGradient id="gf-base" x1="0" y1="0" x2="1" y2="1">
          <stop offset="0%"  stopColor={TREMBLE_GREEN_LIGHT}/>
          <stop offset="55%" stopColor={TREMBLE_GREEN}/>
          <stop offset="100%" stopColor={TREMBLE_GREEN_DARK}/>
        </linearGradient>
        {/* Vertical weave/fold tint */}
        <linearGradient id="gf-weave" x1="0" y1="0" x2="1" y2="0">
          <stop offset="0%"  stopColor="rgba(0,0,0,0.20)"/>
          <stop offset="14%" stopColor="rgba(0,0,0,0.00)"/>
          <stop offset="100%" stopColor="rgba(0,0,0,0.10)"/>
        </linearGradient>
        {/* Soft outer glow */}
        <radialGradient id="gf-glow" cx="0.5" cy="0.55" r="0.7">
          <stop offset="0%" stopColor="rgba(45,155,111,0.55)"/>
          <stop offset="60%" stopColor="rgba(45,155,111,0.10)"/>
          <stop offset="100%" stopColor="rgba(45,155,111,0)"/>
        </radialGradient>
        {/* Pole gradient — brushed steel */}
        <linearGradient id="gf-pole" x1="0" y1="0" x2="1" y2="0">
          <stop offset="0%"  stopColor="#2A2A28"/>
          <stop offset="50%" stopColor="#8A8A82"/>
          <stop offset="100%" stopColor="#2A2A28"/>
        </linearGradient>
        {/* Reveal mask */}
        <clipPath id="gf-reveal">
          <rect x={POLE_X - 2} y="0" width={clipW} height="200"/>
        </clipPath>
        {/* Inner soft mask so sheen fades at edges */}
        <linearGradient id="gf-sheen" x1="0" y1="0" x2="1" y2="0">
          <stop offset="0%"  stopColor="rgba(255,255,255,0)"/>
          <stop offset="50%" stopColor="rgba(255,255,255,0.5)"/>
          <stop offset="100%" stopColor="rgba(255,255,255,0)"/>
        </linearGradient>
      </defs>

      {/* Soft bloom behind flag */}
      <ellipse cx="130" cy="92" rx="120" ry="80" fill="url(#gf-glow)" opacity={unfurl}/>

      {/* Pole shadow on ground */}
      <ellipse cx={POLE_X} cy="186" rx="14" ry="3" fill="rgba(0,0,0,0.35)"/>

      {/* Pole */}
      <rect x={POLE_X - 2.2} y="14" width="4.4" height="172" rx="2.2" fill="url(#gf-pole)"/>
      {/* Pole finial — small sphere */}
      <circle cx={POLE_X} cy="14" r="4.5" fill="#C9C9C2"/>
      <circle cx={POLE_X - 1.2} cy="12.6" r="1.6" fill="rgba(255,255,255,0.6)"/>

      {/* Flag — everything clipped by unfurl reveal */}
      <g clipPath="url(#gf-reveal)">
        {/* Base shape */}
        <path d={flagPath} fill="url(#gf-base)"/>

        {/* Wave-trough shading: a darker band tracing the mid wave */}
        <path
          d={toPath(mid.map(p => ({ x: p.x, y: p.y - 6 })))
             + ' '
             + toPath(mid.map(p => ({ x: p.x, y: p.y + 6 })).reverse(), false)
             + ' Z'}
          fill="rgba(0,0,0,0.12)"
          style={{ mixBlendMode: 'multiply' }}
        />

        {/* Weave fold gradient */}
        <path d={flagPath} fill="url(#gf-weave)" opacity="0.85"/>

        {/* Sheen stripes — vertical bands following wave slope */}
        {sheenStripes.map((s, i) => (
          <rect
            key={i}
            x={s.x - 3}
            y={s.yTop - 4}
            width="6"
            height={s.h + 8}
            fill="url(#gf-sheen)"
            opacity={s.opacity}
            style={{ mixBlendMode: 'screen' }}
          />
        ))}

        {/* Hoist (attached edge) reinforcement — subtle darker strip */}
        <rect
          x={FLAG_X}
          y={FLAG_TOP - 2}
          width="5"
          height={FLAG_H + 4}
          fill="rgba(0,0,0,0.22)"
        />

        {/* Center glyph — a heart-radar mark, half opacity, riding the wave */}
        {variant !== 'pennant' && (() => {
          const cIdx = Math.round(SEGS * 0.55);
          const cx = top[cIdx].x;
          const cy = (top[cIdx].y + bot[cIdx].y) / 2;
          const dy = bot[cIdx].y - top[cIdx].y;
          const scale = dy / FLAG_H;
          // Small heart-pulse mark
          return (
            <g transform={`translate(${cx}, ${cy}) scale(${0.9 * scale})`} opacity="0.75">
              {/* Left heart half outline */}
              <path
                d="M 0 -10 C -6 -16 -16 -12 -16 -4 C -16 4 -8 10 0 16"
                stroke="rgba(255,255,255,0.85)"
                strokeWidth="2.4"
                fill="none"
                strokeLinecap="round"
              />
              {/* Right signal arcs */}
              <path d="M 4 -6 A 6 6 0 0 1 4 6" stroke="rgba(255,255,255,0.85)" strokeWidth="2.2" fill="none" strokeLinecap="round"/>
              <path d="M 10 -10 A 10 10 0 0 1 10 10" stroke="rgba(255,255,255,0.6)" strokeWidth="2.0" fill="none" strokeLinecap="round"/>
              <path d="M 16 -14 A 14 14 0 0 1 16 14" stroke="rgba(255,255,255,0.4)" strokeWidth="1.8" fill="none" strokeLinecap="round"/>
            </g>
          );
        })()}
      </g>

      {/* Outer flag outline — crisp edge */}
      <g clipPath="url(#gf-reveal)" opacity="0.5">
        <path d={flagPath} fill="none" stroke="rgba(255,255,255,0.18)" strokeWidth="0.75"/>
      </g>
    </svg>
  );
}

Object.assign(window, { GreenFlag, TREMBLE_GREEN, TREMBLE_GREEN_DARK, TREMBLE_GREEN_LIGHT });
