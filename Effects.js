.pragma library

// open/close effects. used by the switcher and by the little tiles in settings.
// t: 0 = shown, 1 = gone (can overshoot a bit on springy easings)
// dist: how far slide/rise/drop travel, px
//
// returns opacity, scale, yScale (unfold), dx, dy
function state(effect, t, dist) {
  var c = Math.max(0, Math.min(1, t));
  var s = { opacity: 1, scale: 1, yScale: 1, dx: 0, dy: 0 };
  switch (effect) {
  case "fade":
    s.opacity = 1 - c;
    break;
  case "zoom":
    s.scale = Math.max(0.01, 1 - 0.1 * t);
    s.opacity = 1 - c;
    break;
  case "slide":
    s.dx = t * dist;
    s.opacity = 1 - c;
    break;
  case "rise":
    s.dy = t * dist;
    s.opacity = 1 - c;
    break;
  case "drop":
    s.dy = -t * dist;
    s.opacity = 1 - c;
    break;
  case "pop":
    s.scale = Math.max(0.01, 1 - 0.35 * t);
    s.opacity = 1 - c;
    break;
  case "unfold":
    s.yScale = Math.max(0.01, 1 - t);
    s.opacity = 1 - 0.6 * c;
    break;
  default:          // none
    break;
  }
  return s;
}

// easings that overshoot
function springy(effect) { return effect === "pop"; }

// "changing windows" effects. w goes 0 -> 1 as a window gets selected.
// returns scale, lift (px), glow, dimOthers, edge (border width)
function selection(effect, w) {
  var s = { scale: 1, lift: 0, glow: 0, dimOthers: 0.18, edge: 2 };
  switch (effect) {
  case "grow":
    s.scale = 1 + 0.07 * w;
    break;
  case "lift":
    s.lift = 10 * w;
    s.scale = 1 + 0.02 * w;
    break;
  case "glow":
    s.glow = w;
    break;
  case "spotlight":
    s.dimOthers = 0.55;
    s.scale = 1 + 0.03 * w;
    break;
  case "bounce":
    s.scale = 1 + 0.05 * w;
    break;
  case "outline":
    s.edge = 3;
    s.dimOthers = 0.1;
    break;
  default:          // none
    s.dimOthers = 0.12;
    break;
  }
  return s;
}
