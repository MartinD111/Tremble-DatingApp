// MatchReveal — full-screen celebration moment.
//
// Choreography (≈ 4.4 s active, holds at the end):
//   0.00 s — dark bg + green bloom fade in
//   0.20 s — avatar enters from below the screen, spinning on its Y axis
//   1.40 s — avatar lands centered; spin stops face-forward
//   1.55 s — green flag (sitting up top) unfurls
//   2.10 s — "We have a match" headline springs in
//   2.45 s — pep-talk message fades in
//   2.75 s — small note fades in (if present)
//   then  — animation HOLDS.

function MatchReveal({ partner, headline, message, note, speed = 1 }) {
  const [t, setT] = React.useState(0);
  const startRef = React.useRef(performance.now());

  React.useEffect(() => {
    let raf;
    const tick = (now) => {
      setT((now - startRef.current) / 1000);
      raf = requestAnimationFrame(tick);
    };
    raf = requestAnimationFrame(tick);
    return () => cancelAnimationFrame(raf);
  }, []);

  const e = t * speed;

  // ── Avatar entrance: rise from bottom + Y-axis spin ────────────────
  const riseStart = 0.20;
  const riseDur = 1.20;
  const riseRaw = Math.max(0, Math.min(1, (e - riseStart) / riseDur));
  const rise = 1 - Math.pow(1 - riseRaw, 3); // ease-out cubic
  const avatarY = (1 - rise) * 130;          // viewport-percent units

  // 2 full turns so the photo lands face-forward (rotateY at multiples of 360°).
  const spinTurns = 2;
  const spinDeg = riseRaw < 1 ? rise * spinTurns * 360 : spinTurns * 360;
  const avatarOp = Math.min(1, riseRaw * 4);

  // ── Flag removed — "We have a match" now sits where the flag used to. ─────
  // (Headline springs in at 2.10 s; no other geometry needed.)

  // ── Text stages ────────────────────────────────────────────────────
  // Picture lands at 1.40 s — words follow immediately afterwards.
  const titleIn = e >= 1.45;
  const msgIn   = e >= 1.70;
  const noteIn  = e >= 1.95;
  const bgIn    = Math.min(1, e / 0.6);

  // Longer messages get a smaller font so they still fit one phone width.
  const msgLen = (message || '').length;
  const msgSize = msgLen > 70 ? 18 : msgLen > 50 ? 21 : msgLen > 30 ? 24 : 28;

  return (
    <div style={{
      position: 'absolute', inset: 0, overflow: 'hidden', isolation: 'isolate',
      pointerEvents: 'none',
    }}>
      {/* Backdrop — graphite with green bloom */}
      <div style={{
        position: 'absolute', inset: 0,
        background: `
          radial-gradient(circle at 50% 46%, rgba(45,155,111,${0.55 * bgIn}), rgba(14,14,12,0) 58%),
          radial-gradient(circle at 50% 100%, rgba(91,191,147,${0.18 * bgIn}), rgba(14,14,12,0) 50%),
          linear-gradient(180deg, #0B0B09 0%, #13130F 50%, #0E0E0C 100%)
        `,
        opacity: bgIn,
      }}/>

      {/* "We have a match" — anchored near the top of the device, where the flag used to sit */}
      <div style={{
        position: 'absolute',
        top: 148,
        left: 0, right: 0,
        padding: '0 28px',
        textAlign: 'center',
        opacity: titleIn ? 1 : 0,
        transform: titleIn ? 'translateY(0) scale(1)' : 'translateY(20px) scale(0.92)',
        transition: 'opacity 460ms var(--ease-out), transform 620ms cubic-bezier(0.2, 1.4, 0.4, 1)',
      }}>
        <div style={{
          fontFamily: 'var(--font-display)',
          fontWeight: 900,
          fontSize: 40,
          lineHeight: 1.0,
          letterSpacing: '-0.035em',
          color: '#FAFAF7',
          textShadow: '0 8px 32px rgba(0,0,0,0.4)',
        }}>
          {headline}
        </div>
        {(partner.name || partner.age) && (
          <div style={{
            marginTop: 14,
            fontFamily: 'var(--font-display)',
            fontStyle: 'italic',
            fontWeight: 600,
            fontSize: 32,
            lineHeight: 1.1,
            letterSpacing: '-0.015em',
            color: 'rgba(250,250,247,0.92)',
            textShadow: '0 6px 22px rgba(0,0,0,0.4)',
          }}>
            {partner.name}{partner.age ? `, ${partner.age}` : ''}
          </div>
        )}
      </div>

      {/* Centered avatar + message column */}
      <div style={{
        position: 'absolute', inset: 0,
        display: 'flex', flexDirection: 'column',
        alignItems: 'center', justifyContent: 'center',
      }}>
        {/* Avatar — Y-axis spin */}
        <div style={{
          position: 'relative',
          width: 188, height: 188,
          opacity: avatarOp,
          transform: `translateY(${avatarY}vh)`,
          perspective: '1200px',
          willChange: 'transform',
        }}>
          {/* Photo well — face */}
          <div style={{
            position: 'absolute', inset: 0,
            borderRadius: '50%', overflow: 'hidden',
            background: `linear-gradient(135deg, ${TREMBLE_GREEN_LIGHT} 0%, ${TREMBLE_GREEN_DARK} 100%)`,
            display: 'flex', alignItems: 'center', justifyContent: 'center',
            transform: `rotateY(${spinDeg}deg)`,
            transformStyle: 'preserve-3d',
            backfaceVisibility: 'hidden',
            willChange: 'transform',
          }}>
            {partner.photoUrl ? (
              <img src={partner.photoUrl} alt={partner.name}
                style={{ width: '100%', height: '100%', objectFit: 'cover' }}/>
            ) : (
              <div style={{
                fontFamily: 'var(--font-display)',
                fontWeight: 900, color: 'white',
                fontSize: 92, lineHeight: 1,
                textShadow: '0 4px 14px rgba(0,0,0,0.25)',
              }}>{partner.name?.[0] || '?'}</div>
            )}
            <div style={{
              position: 'absolute', inset: 0, borderRadius: '50%',
              background: 'radial-gradient(circle at 35% 25%, rgba(255,255,255,0.22), rgba(255,255,255,0) 50%)',
              pointerEvents: 'none',
            }}/>
          </div>

          {/* Back face */}
          <div style={{
            position: 'absolute', inset: 0,
            borderRadius: '50%', overflow: 'hidden',
            background: `linear-gradient(135deg, ${TREMBLE_GREEN_DARK} 0%, ${TREMBLE_GREEN_LIGHT} 100%)`,
            transform: `rotateY(${spinDeg + 180}deg)`,
            backfaceVisibility: 'hidden',
            willChange: 'transform',
          }}/>
        </div>

        {/* Text stack — cycling message + optional note */}
        <div style={{
          marginTop: 28,
          padding: '0 28px',
          textAlign: 'center',
          maxWidth: 340,
        }}>
          {/* Cycling pep-talk message */}
          <div style={{
            fontFamily: 'var(--font-ui)',
            fontWeight: 600,
            fontSize: msgSize,
            lineHeight: 1.3,
            letterSpacing: '-0.005em',
            color: TREMBLE_GREEN_LIGHT,
            textWrap: 'balance',
            opacity: msgIn ? 1 : 0,
            transform: msgIn ? 'translateY(0)' : 'translateY(10px)',
            transition: 'opacity 420ms var(--ease-out), transform 520ms var(--ease-out)',
          }}>
            {message}
          </div>

          {/* Small note (optional) */}
          {note && (
            <div style={{
              marginTop: 14,
              fontFamily: 'var(--font-mono)',
              fontWeight: 400,
              fontSize: 10.5,
              lineHeight: 1.5,
              letterSpacing: '0.04em',
              color: 'rgba(250,250,247,0.42)',
              fontStyle: 'italic',
              textWrap: 'balance',
              opacity: noteIn ? 1 : 0,
              transform: noteIn ? 'translateY(0)' : 'translateY(6px)',
              transition: 'opacity 360ms var(--ease-out), transform 420ms var(--ease-out)',
            }}>
              {note}
            </div>
          )}
        </div>
      </div>
    </div>
  );
}

Object.assign(window, { MatchReveal });
