// components.jsx — shared UI for Inkpath
const { useState, useEffect, useRef } = React;

// ---- Seal mark (vermilion square with 書) ----
function Seal({ size = 34 }) {
  return (
    <div className="seal" style={{ width: size, height: size, fontSize: size * 0.6 }}>書</div>
  );
}

// ---- Minimal stroke icons (built from simple primitives, no hand-drawn art) ----
function Icon({ name, size = 22, stroke = 1.6 }) {
  const common = { width: size, height: size, viewBox: "0 0 24 24", fill: "none", stroke: "currentColor", strokeWidth: stroke, strokeLinecap: "round", strokeLinejoin: "round" };
  const paths = {
    back: <path d="M15 5l-7 7 7 7" />,
    play: <path d="M8 5l11 7-11 7z" fill="currentColor" stroke="none" />,
    check: <path d="M5 13l4 4 10-11" />,
    skip: <g><path d="M6 5l8 7-8 7z" /><path d="M18 5v14" /></g>,
    refresh: <g><path d="M4 12a8 8 0 0 1 14-5l2 2" /><path d="M20 5v4h-4" /><path d="M20 12a8 8 0 0 1-14 5l-2-2" /><path d="M4 19v-4h4" /></g>,
    eye: <g><path d="M2 12s4-7 10-7 10 7 10 7-4 7-10 7-10-7-10-7z" /><circle cx="12" cy="12" r="2.6" /></g>,
    flame: <path d="M12 3c1 3 4 4 4 8a4 4 0 0 1-8 0c0-1.5.6-2.4 1.3-3.2C10 9 11 7 12 3z" />,
    grid: <g><rect x="3.5" y="3.5" width="17" height="17" rx="1" /><path d="M12 3.5v17M3.5 12h17" /></g>,
    sound: <g><path d="M4 9v6h4l5 4V5L8 9z" /><path d="M16 9a4 4 0 0 1 0 6" /></g>,
    arrowRight: <path d="M5 12h14M13 6l6 6-6 6" />,
    home: <path d="M4 11l8-7 8 7M6 10v9h12v-9" />,
    star: <path d="M12 3l2.6 5.6 6.1.8-4.5 4.2 1.2 6L12 16.8 6.6 19.6l1.2-6L3.3 9.4l6.1-.8z" />,
  };
  return <svg {...common}>{paths[name]}</svg>;
}

// ---- iPad landscape frame (simple rounded bezel) ----
function IpadFrame({ children }) {
  const W = 1194, H = 834, BEZEL = 16;
  const [scale, setScale] = useState(1);
  useEffect(() => {
    const fit = () => {
      const ow = W + BEZEL * 2, oh = H + BEZEL * 2;
      const s = Math.min(window.innerWidth / (ow + 48), window.innerHeight / (oh + 48), 1.1);
      setScale(s);
    };
    fit();
    window.addEventListener("resize", fit);
    return () => window.removeEventListener("resize", fit);
  }, []);
  return (
    <div className="stage">
      <div className="ipad" style={{ width: W + BEZEL * 2, height: H + BEZEL * 2, padding: BEZEL, transform: `scale(${scale})` }}>
        <div className="ipad-screen" style={{ width: W, height: H }}>
          {children}
        </div>
      </div>
    </div>
  );
}

// ---- Progress dots ----
function ProgressTrack({ total, index }) {
  return (
    <div className="prog-track">
      {Array.from({ length: total }).map((_, i) => (
        <span key={i} className={"prog-dot" + (i < index ? " done" : i === index ? " active" : "")} />
      ))}
    </div>
  );
}

Object.assign(window, { Seal, Icon, IpadFrame, ProgressTrack });
