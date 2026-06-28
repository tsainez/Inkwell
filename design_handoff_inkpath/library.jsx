// library.jsx — home / deck picker
const { useState: useStateL } = React;

// Build an ad-hoc deck from typed input. Keeps only CJK ideographs.
function buildCustomDeck(raw) {
  const cjk = [...raw].filter((ch) => /[\u3400-\u9FFF\uF900-\uFAFF]/.test(ch));
  if (!cjk.length) return null;
  const phrase = [...raw].filter((ch) => /\S/.test(ch)).join("");
  const isPhrase = cjk.length > 1;
  return {
    id: "custom",
    lang: "custom",
    script: "Custom",
    level: "Your input",
    title: isPhrase ? "Phrase practice" : "Custom character",
    custom: true,
    phrase: isPhrase ? phrase : null,
    chars: cjk.map((c) => ({ c, meaning: "", reading: "" })),
  };
}

function CustomPanel({ onStart }) {
  const [text, setText] = useStateL("");
  const deck = buildCustomDeck(text);
  const count = deck ? deck.chars.length : 0;
  const suggestions = ["愛", "夢", "桜", "山川", "一期一会", "謝謝"];

  const go = () => { if (deck) onStart(deck); };

  return (
    <div className="custom-panel">
      <div className="cp-eyebrow"><Icon name="grid" size={14} /> Practice anything</div>
      <p className="cp-lead">Search a single character, or paste a word or sentence to write it out — one character at a time.</p>
      <div className="cp-field">
        <input
          className="cp-input"
          value={text}
          onChange={(e) => setText(e.target.value)}
          onKeyDown={(e) => { if (e.key === "Enter") go(); }}
          placeholder="Type or paste 漢字…"
          spellCheck="false"
        />
        <button className="cp-go" onClick={go} disabled={!deck} aria-label="Start practice">
          <Icon name="arrowRight" size={20} />
        </button>
      </div>
      <div className="cp-meta">
        {deck ? (
          <span className="cp-count">{count} character{count === 1 ? "" : "s"}{deck.phrase ? " · phrase mode" : ""}</span>
        ) : (
          <span className="cp-hint">Tries:</span>
        )}
        <div className="cp-chips">
          {suggestions.map((s) => (
            <button key={s} className="cp-chip" onClick={() => setText(s)}>{s}</button>
          ))}
        </div>
      </div>
    </div>
  );
}

function Library({ onStart, progress }) {
  const totalLearned = Object.values(progress).reduce((a, b) => a + (b ? b.length : 0), 0);
  return (
    <div className="lib">
      <header className="lib-head">
        <div className="brand">
          <Seal size={34} />
          <div>
            <div className="wordmark">Inkpath</div>
            <div className="tagline">stroke order, by hand</div>
          </div>
        </div>
        <div className="streak">
          <Icon name="flame" size={18} />
          <span><b>4</b> day streak</span>
        </div>
      </header>

      <div className="lib-hero">
        <div className="hero-left">
          <div className="hero-eyebrow">Good evening</div>
          <h1 className="hero-title">What will you write today?</h1>
          <div className="hero-stats">
            <div className="stat"><div className="stat-num">{totalLearned}</div><div className="stat-lbl">characters practiced</div></div>
            <div className="stat-div" />
            <div className="stat"><div className="stat-num">3</div><div className="stat-lbl">decks available</div></div>
            <div className="stat-div" />
            <div className="stat"><div className="stat-num">92<span className="pct">%</span></div><div className="stat-lbl">avg. accuracy</div></div>
          </div>
        </div>
        <CustomPanel onStart={onStart} />
      </div>

      <div className="deck-grid">
        {DECKS.map((d) => {
          const done = (progress[d.id] || []).length;
          const pct = Math.round((done / d.chars.length) * 100);
          return (
            <button key={d.id} className={"deck-card accent-" + d.accent} onClick={() => onStart(d)}>
              <div className="deck-card-top">
                <div className="deck-tag">{d.script} · {d.level}</div>
                <div className="deck-glyphs">
                  {d.chars.slice(0, 3).map((ch) => (
                    <span key={ch.c} className="deck-glyph">{ch.c}</span>
                  ))}
                </div>
              </div>
              <div className="deck-card-body">
                <h2 className="deck-title">{d.title}</h2>
                <p className="deck-blurb">{d.blurb}</p>
              </div>
              <div className="deck-card-foot">
                <div className="deck-prog">
                  <div className="deck-prog-bar"><span style={{ width: pct + "%" }} /></div>
                  <span className="deck-prog-lbl">{done}/{d.chars.length}</span>
                </div>
                <span className="deck-go"><Icon name="arrowRight" size={20} /></span>
              </div>
            </button>
          );
        })}
      </div>
    </div>
  );
}
Object.assign(window, { Library, buildCustomDeck });
