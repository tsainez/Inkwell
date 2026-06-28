// practice.jsx — the core writing loop (Hanzi Writer quiz)
const { useState: useStateP, useEffect: useEffectP, useRef: useRefP } = React;

const DATA_VERSION = "2.0.1";
function charLoader(char) {
  return fetch(`https://cdn.jsdelivr.net/npm/hanzi-writer-data@${DATA_VERSION}/${encodeURIComponent(char)}.json`)
    .then((r) => { if (!r.ok) throw new Error("no data"); return r.json(); });
}

// ---- Practice grid background ----
function PadGrid({ kind, size }) {
  const c = "rgba(200,73,47,0.22)";
  const dash = "5 6";
  return (
    <svg className="pad-grid" width={size} height={size} viewBox={`0 0 ${size} ${size}`}>
      <rect x="1" y="1" width={size - 2} height={size - 2} rx="6" fill="none" stroke="rgba(200,73,47,0.35)" strokeWidth="1.5" />
      {kind !== "blank" && (
        <g stroke={c} strokeWidth="1" strokeDasharray={dash}>
          <line x1={size / 2} y1="0" x2={size / 2} y2={size} />
          <line x1="0" y1={size / 2} x2={size} y2={size / 2} />
        </g>
      )}
      {kind === "rice" && (
        <g stroke={c} strokeWidth="1" strokeDasharray={dash}>
          <line x1="0" y1="0" x2={size} y2={size} />
          <line x1={size} y1="0" x2="0" y2={size} />
        </g>
      )}
    </svg>
  );
}

// ---- WritingPad: one character, quiz mode ----
function WritingPad({ char, tweaks, padRef, onCorrectStroke, onMistake, onComplete }) {
  const target = useRefP(null);
  const writerRef = useRefP(null);
  const [loading, setLoading] = useStateP(true);
  const [failed, setFailed] = useStateP(false);
  const SIZE = 460;

  useEffectP(() => {
    if (!target.current || !window.HanziWriter) return;
    target.current.innerHTML = "";
    setLoading(true); setFailed(false);
    let cancelled = false;

    const writer = HanziWriter.create(target.current, char, {
      width: SIZE, height: SIZE, padding: 18,
      showCharacter: false,
      showOutline: tweaks.outline,
      strokeColor: "#2b2925",
      radicalColor: "#2b2925",
      outlineColor: "#d8d2c6",
      drawingColor: tweaks.accent,
      highlightColor: tweaks.accent,
      highlightOnComplete: true,
      highlightCompleteColor: tweaks.accent,
      drawingWidth: 26,
      strokeAnimationSpeed: tweaks.speed,
      delayBetweenStrokes: 240,
      charDataLoader: (c, onDone) => charLoader(c),
      onLoadCharDataSuccess: () => { if (!cancelled) setLoading(false); },
      onLoadCharDataError: () => { if (!cancelled) { setLoading(false); setFailed(true); } },
    });
    writerRef.current = writer;

    const startQuiz = () => writer.quiz({
      leniency: tweaks.strict ? 1.0 : 1.6,
      showHintAfterMisses: tweaks.hints ? 3 : false,
      onCorrectStroke: (d) => onCorrectStroke(d.strokesRemaining),
      onMistake: () => onMistake(),
      onComplete: (s) => onComplete(s.totalMistakes),
    });
    startQuiz();

    // expose imperative controls
    padRef.current = {
      demo: () => {
        writer.cancelQuiz();
        writer.showOutline();
        writer.animateCharacter({
          onComplete: () => { writer.hideCharacter(); startQuiz(); },
        });
      },
      restart: () => { writer.cancelQuiz(); writer.hideCharacter(); startQuiz(); },
    };

    return () => { cancelled = true; try { writer.cancelQuiz(); } catch (e) {} target.current && (target.current.innerHTML = ""); };
  }, [char, tweaks.outline, tweaks.accent, tweaks.strict, tweaks.hints, tweaks.speed]);

  return (
    <div className="pad-wrap" style={{ width: SIZE, height: SIZE }}>
      <PadGrid kind={tweaks.grid} size={SIZE} />
      <div ref={target} className="pad-target" />
      {loading && <div className="pad-loading"><span className="spinner" />loading strokes…</div>}
      {failed && <div className="pad-loading">stroke data unavailable</div>}
    </div>
  );
}

// ---- Practice screen ----
function Practice({ deck, tweaks, onExit, onFinish }) {
  const [idx, setIdx] = useStateP(0);
  const [done, setDone] = useStateP(false);
  const [skipped, setSkipped] = useStateP(false);
  const [strokesLeft, setStrokesLeft] = useStateP(null);
  const [mistakes, setMistakes] = useStateP(0);
  const [results, setResults] = useStateP([]); // {c, mistakes, skipped}
  const padRef = useRefP({});
  const ch = deck.chars[idx];

  const handleComplete = (m) => {
    setDone(true);
    setResults((r) => [...r, { c: ch.c, mistakes: m, skipped: false }]);
  };

  const handleSkip = () => {
    setSkipped(true); setDone(true);
    setResults((r) => [...r, { c: ch.c, mistakes: 0, skipped: true }]);
  };

  const next = () => {
    if (idx + 1 >= deck.chars.length) {
      onFinish({ deck, results: [...results] });
      return;
    }
    setIdx(idx + 1); setDone(false); setSkipped(false); setStrokesLeft(null); setMistakes(0);
  };

  // Auto-advance in custom/phrase mode so you never lift the pencil to tap Next.
  useEffectP(() => {
    if (!done || skipped || !deck.custom) return;
    const t = setTimeout(() => next(), 1050);
    return () => clearTimeout(t);
  }, [done, skipped, idx]);

  return (
    <div className="practice">
      <header className="pr-top">
        <button className="icon-btn" onClick={onExit} aria-label="Exit"><Icon name="back" size={22} /></button>
        <div className="pr-top-mid">
          <div className="pr-deck">{deck.script} · {deck.title}</div>
          <ProgressTrack total={deck.chars.length} index={idx} />
        </div>
        <div className="pr-count">{idx + 1} <span>/ {deck.chars.length}</span></div>
      </header>

      <div className="pr-main">
        <div className="pr-left">
          <div className={"pad-card" + (done ? " is-done" : "")}>
            <WritingPad
              key={deck.id + "-" + idx}
              char={ch.c}
              tweaks={tweaks}
              padRef={padRef}
              onCorrectStroke={(rem) => setStrokesLeft(rem)}
              onMistake={() => setMistakes((m) => m + 1)}
              onComplete={handleComplete}
            />
            {done && (
              <div className={"done-veil" + (skipped ? " skipped" : "")}>
                <div className="done-badge"><Icon name={skipped ? "arrowRight" : "check"} size={26} /></div>
                <div className="done-word">{skipped ? "Skipped" : mistakes === 0 ? "Perfect" : "Well written"}</div>
                <div className="done-sub">{skipped ? "come back to this one" : mistakes === 0 ? "clean stroke order" : `${mistakes} stroke ${mistakes === 1 ? "correction" : "corrections"}`}</div>
              </div>
            )}
          </div>
          <div className="pad-controls">
            <button className="ctl" onClick={() => padRef.current.demo && padRef.current.demo()} disabled={done}>
              <Icon name="play" size={16} /> Show stroke order
            </button>
            <button className="ctl" onClick={() => padRef.current.restart && (setMistakes(0), setStrokesLeft(null), padRef.current.restart())} disabled={done}>
              <Icon name="refresh" size={16} /> Redo
            </button>
            <button className="ctl ghost" onClick={done ? next : handleSkip}>
              <Icon name="skip" size={16} /> {done ? "Next" : "Skip"}
            </button>
          </div>
        </div>

        <div className="pr-right">
          {deck.phrase && (
            <div className="phrase-strip">
              <div className="phrase-eyebrow">Phrase · character {idx + 1} of {deck.chars.length}</div>
              <div className="phrase-row">
                {deck.chars.map((pc, i) => (
                  <span key={i} className={"phrase-ch" + (i === idx ? " current" : i < idx ? " written" : "")}>{pc.c}</span>
                ))}
              </div>
            </div>
          )}
          <div className="prompt">
            {deck.custom ? (
              <>
                <div className="prompt-eyebrow">{deck.phrase ? "Write this character" : "Reference"}</div>
                <div className="prompt-ref">{ch.c}</div>
                <div className="prompt-reading">Trace it in the box, in stroke order.</div>
                <div className="prompt-meta">
                  <div className="meta-pill subtle">Custom practice</div>
                </div>
              </>
            ) : (
              <>
                <div className="prompt-eyebrow">Write this character</div>
                <div className="prompt-meaning">{ch.meaning}</div>
                <div className="prompt-reading">{ch.reading}</div>
                <div className="prompt-meta">
                  <div className="meta-pill"><Icon name="sound" size={15} /> Audio</div>
                  <div className="meta-pill subtle">{deck.lang === "zh" ? "Simplified" : deck.lang === "ja" ? "Japanese" : "CJK"}</div>
                </div>
              </>
            )}
          </div>

          <div className="hint-card">
            {!done ? (
              <>
                <div className="hint-row">
                  <span className="hint-k">Strokes left</span>
                  <span className="hint-v">{strokesLeft === null ? "—" : strokesLeft}</span>
                </div>
                <div className="hint-row">
                  <span className="hint-k">Corrections</span>
                  <span className="hint-v">{mistakes}</span>
                </div>
                <p className="hint-tip">Draw each stroke in order. {tweaks.hints ? "After a few misses the next stroke is highlighted." : "Hints are off — trust your memory."}</p>
              </>
            ) : (
              <>
                <div className="big-glyph">{ch.c}</div>
                <button className="next-btn" onClick={next}>
                  {idx + 1 >= deck.chars.length ? "Finish session" : "Next character"} <Icon name="arrowRight" size={18} />
                </button>
                {deck.custom && !skipped && idx + 1 < deck.chars.length && (
                  <div className="auto-next"><span className="auto-next-bar" /> moving on automatically…</div>
                )}
              </>
            )}
          </div>
        </div>
      </div>
    </div>
  );
}
Object.assign(window, { Practice });
