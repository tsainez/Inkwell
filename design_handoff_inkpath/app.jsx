// app.jsx — root: routing, tweaks, progress
const { useState: useStateA } = React;

const TWEAK_DEFAULTS = /*EDITMODE-BEGIN*/{
  "accent": "#c8492f",
  "grid": "rice",
  "outline": true,
  "hints": true,
  "strict": false,
  "speed": 1,
  "paper": "#f7f4ee"
}/*EDITMODE-END*/;

function App() {
  const [t, setTweak] = useTweaks(TWEAK_DEFAULTS);
  const [route, setRoute] = useStateA({ name: "library" });
  const [progress, setProgress] = useStateA({}); // deckId -> [chars]
  const [session, setSession] = useStateA(null);

  const tweaks = {
    accent: t.accent, grid: t.grid, outline: t.outline,
    hints: t.hints, strict: t.strict, speed: t.speed,
  };

  const startDeck = (deck) => setRoute({ name: "practice", deck });
  const finish = (s) => {
    setSession(s);
    setProgress((p) => ({ ...p, [s.deck.id]: s.results.map((r) => r.c) }));
    setRoute({ name: "complete" });
  };

  return (
    <div className="app" style={{ "--accent": t.accent, "--paper": t.paper }}>
      <IpadFrame>
        {route.name === "library" && <Library onStart={startDeck} progress={progress} />}
        {route.name === "practice" && (
          <Practice
            deck={route.deck}
            tweaks={tweaks}
            onExit={() => setRoute({ name: "library" })}
            onFinish={finish}
          />
        )}
        {route.name === "complete" && session && (
          <Complete
            session={session}
            onHome={() => setRoute({ name: "library" })}
            onAgain={() => setRoute({ name: "practice", deck: session.deck })}
          />
        )}
      </IpadFrame>

      <TweaksPanel>
        <TweakSection label="Practice grid" />
        <TweakRadio label="Guide lines" value={t.grid} options={["rice", "field", "blank"]}
          onChange={(v) => setTweak("grid", v)} />
        <TweakToggle label="Faint character guide" value={t.outline}
          onChange={(v) => setTweak("outline", v)} />
        <TweakSection label="Difficulty" />
        <TweakToggle label="Stroke hints" value={t.hints}
          onChange={(v) => setTweak("hints", v)} />
        <TweakToggle label="Strict grading" value={t.strict}
          onChange={(v) => setTweak("strict", v)} />
        <TweakSlider label="Demo speed" value={t.speed} min={0.5} max={2.5} step={0.5} unit="×"
          onChange={(v) => setTweak("speed", v)} />
        <TweakSection label="Theme" />
        <TweakColor label="Accent" value={t.accent}
          options={["#c8492f", "#1f6f6b", "#9a6a2f", "#2b2925"]}
          onChange={(v) => setTweak("accent", v)} />
        <TweakColor label="Paper" value={t.paper}
          options={["#f7f4ee", "#f4f1ea", "#efece3", "#faf8f4"]}
          onChange={(v) => setTweak("paper", v)} />
      </TweaksPanel>
    </div>
  );
}

ReactDOM.createRoot(document.getElementById("root")).render(<App />);
