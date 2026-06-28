// complete.jsx — session summary
function Complete({ session, onHome, onAgain }) {
  const { deck, results } = session;
  const n = results.length;
  const perfect = results.filter((r) => r.mistakes === 0 && !r.skipped).length;
  const skipped = results.filter((r) => r.skipped).length;
  const totalMistakes = results.reduce((a, r) => a + r.mistakes, 0);
  const accuracy = n ? Math.round((perfect / n) * 100) : 0;

  return (
    <div className="complete">
      <div className="cmp-card">
        <Seal size={40} />
        <div className="cmp-eyebrow">Session complete</div>
        <h1 className="cmp-title">{deck.title}</h1>

        <div className="cmp-glyphs">
          {results.map((r, i) => (
            <div key={i} className={"cmp-glyph" + (r.skipped ? " skipped" : r.mistakes === 0 ? " perfect" : "")}>
              <span>{r.c}</span>
              {!r.skipped && r.mistakes === 0 && <i className="cmp-tick"><Icon name="check" size={12} /></i>}
            </div>
          ))}
        </div>

        <div className="cmp-stats">
          <div className="cmp-stat">
            <div className="cmp-num">{n}</div>
            <div className="cmp-lbl">written</div>
          </div>
          <div className="cmp-stat">
            <div className="cmp-num">{perfect}</div>
            <div className="cmp-lbl">flawless</div>
          </div>
          <div className="cmp-stat">
            <div className="cmp-num">{accuracy}<span className="pct">%</span></div>
            <div className="cmp-lbl">first-try</div>
          </div>
          <div className="cmp-stat">
            <div className="cmp-num">{totalMistakes}</div>
            <div className="cmp-lbl">corrections</div>
          </div>
        </div>

        <div className="cmp-streak">
          <Icon name="flame" size={18} /> Streak extended to <b>5 days</b>
        </div>

        <div className="cmp-actions">
          <button className="cmp-btn primary" onClick={onAgain}>Practice again</button>
          <button className="cmp-btn" onClick={onHome}><Icon name="home" size={17} /> Library</button>
        </div>
      </div>
    </div>
  );
}
Object.assign(window, { Complete });
