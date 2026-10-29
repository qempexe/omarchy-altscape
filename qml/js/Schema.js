.pragma library

// every setting. the settings tab builds its rows from `groups`,
// resolve() turns the saved file into a full, checked config.
// kind: enum | int | bool | string | color | palette
// when: row is dimmed unless these keys have these values

// custom color swatches: backgrounds, text colors, accents
var swatches = [
  "#141414", "#1d1510", "#1a1b26", "#282a36", "#2e3440", "#2d353b", "#1f1f28", "#3b2a1f",
  "#e0e0e0", "#eadbc8", "#ffffff", "#c0caf5", "#d8dee9", "#dcd7ba", "#f8f8f2", "#e0def4",
  "#d4a35a", "#c8925a", "#7aa2f7", "#cba6f7", "#a7c080", "#88c0d0", "#fabd2f", "#ff6a1f"
];

var modes = [
  { key: "grid",     label: "Grid",      hint: "Windows in rows, a block per workspace." },
  { key: "strip",    label: "Strip",     hint: "One row of windows across the screen, split by workspace." },
  { key: "carousel", label: "Carousel",  hint: "The selected window up front, the others turning away." },
  { key: "ring",     label: "Ring",      hint: "Windows around a circle, the selection at the top." },
  { key: "list",     label: "List",      hint: "A column of small previews, the selection big beside it." },
  { key: "overview", label: "Overview",  hint: "Every workspace as a little screen, windows where they really are." },
  { key: "stack",    label: "Stack",     hint: "A deck of windows; the next ones wait behind the selection." },
  { key: "dock",     label: "Dock",      hint: "Small previews along the bottom, growing around the selection." },
  { key: "compact",  label: "Compact",   hint: "Every window the same size, close together in one panel, the title underneath. Like Windows and macOS." },
  { key: "spread",   label: "Spread",    hint: "Every window at its own shape, as big as fits, in rows that fill the screen." },
  { key: "columns",  label: "Columns",   hint: "A column per workspace, its windows stacked under its name." }
];

var modeKeys = modes.map(m => m.key);

var groups = [
  {
    title: "Switcher",
    items: [
      { key: "scope", label: "Show windows from", kind: "enum", fallback: "all", control: "tiles",
        options: ["all", "others", "monitor", "workspace"],
        labels: { all: "All workspaces", others: "Other workspaces", monitor: "This monitor", workspace: "This workspace" },
        hint: "All workspaces lists every open window. Other workspaces leaves out the one you are on, so you always land somewhere else. This monitor keeps to the screen you are on. This workspace only the windows in front of you." },
      { key: "order", label: "Order", kind: "enum", fallback: "workspace", control: "seg",
        options: ["workspace", "recent"],
        labels: { workspace: "By workspace", recent: "Most recent first" },
        hint: "By workspace groups windows under their workspace. Most recent first is the classic order, last used on top." },
      { key: "shortcut", label: "Shortcut", kind: "enum", fallback: "alt", control: "seg",
        options: ["alt", "super", "off"],
        labels: { alt: "Alt + Tab", super: "Super + Tab", off: "Off" },
        hint: "Written into ~/.config/hypr/bindings.lua. Super + Tab replaces Omarchy's next-workspace key. Shift goes backwards." },
      { key: "pickOnRelease", label: "Switch on release", kind: "bool", fallback: true,
        hint: "Let go of Alt (or Super) to jump to the selected window. Off keeps the switcher open until Enter or a click." },
      { key: "showSpecial", label: "Scratchpads", kind: "bool", fallback: false,
        hint: "Include windows parked on special workspaces." },
      { key: "showEmpty", label: "Empty workspaces", kind: "bool", fallback: false,
        hint: "Overview also draws workspaces that have no windows.",
        when: [{ key: "order", is: ["workspace"] }] }
    ]
  },
  {
    title: "Previews",
    items: [
      { key: "previews", label: "Window previews", kind: "enum", fallback: "live", control: "tiles",
        options: ["live", "still", "off"],
        labels: { live: "Live", still: "Snapshot", off: "Icons only" },
        hint: "Live keeps every preview moving while the switcher is open. Snapshot grabs one frame. Icons only is the lightest." },
      { key: "tileSize", label: "Preview size", kind: "int", fallback: 300, min: 120, max: 520, step: 10,
        hint: "How wide a window preview is, in pixels." },
      { key: "tileGap", label: "Space between windows", kind: "int", fallback: 12, min: 0, max: 48, step: 2,
        hint: "Pixels between the previews. 0 packs them edge to edge." },
      { key: "equalSizes", label: "Same size for every window", kind: "bool", fallback: false,
        hint: "Give every preview the same shape, with the window inside it, instead of each at its own shape. Compact always does." },
      { key: "iconSize", label: "Icon size", kind: "int", fallback: 40, min: 16, max: 96, step: 4,
        hint: "App icons on the previews (and instead of them when a preview is not ready)." },
      { key: "showTitles", label: "Window titles", kind: "bool", fallback: false,
        hint: "Write the window title under each window. Off shows only the windows." },
      { key: "attention", label: "Attention", kind: "enum", fallback: "pulse", control: "seg",
        options: ["pulse", "ring", "off"],
        labels: { pulse: "Pulse", ring: "Ring", off: "Off" },
        hint: "How a window that asks for attention stands out." }
    ]
  },
  {
    title: "Look",
    items: [
      { key: "colorMode", label: "Colors", kind: "enum", fallback: "theme", control: "scheme",
        options: ["theme", "custom", "monochrome", "category"],
        labels: { theme: "Follow theme", custom: "Custom", monochrome: "Monochrome", category: "By category" },
        hint: "Follow theme matches your Omarchy theme live. Custom lets you choose the background, text and accent. Monochrome removes every hue. By category gives every app its own color." },
      { key: "customColors", label: "Custom colors", kind: "palette",
        fallback: { customBg: "#141414", customFg: "#e0e0e0", accentColor: "#ff6a1f" },
        targets: [{ key: "customBg", label: "Background" }, { key: "customFg", label: "Text" }, { key: "accentColor", label: "Accent" }],
        presets: swatches,
        hint: "Choose Background, Text or Accent, then pick a swatch or type a hex.",
        when: [{ key: "colorMode", is: ["custom"] }] },
      { key: "cardStyle", label: "Card style", kind: "enum", fallback: "soft", control: "tiles",
        options: ["soft", "outline", "flat"],
        labels: { soft: "Soft", outline: "Outline", flat: "Flat" },
        hint: "The edge around each window: soft is a faint line, outline a clear one, flat none (the selection is always marked)." },
      { key: "density", label: "Spacing", kind: "enum", fallback: "comfortable", control: "tiles",
        options: ["compact", "comfortable", "spacious"],
        labels: { compact: "Compact", comfortable: "Comfortable", spacious: "Spacious" },
        hint: "How much air there is between things." },
      { key: "cornerRadius", label: "Roundness", kind: "int", fallback: 6, min: 0, max: 20, step: 2,
        hint: "0 is square, 20 is very round." },
      { key: "frame", label: "Window outline", kind: "bool", fallback: false,
        hint: "Draw the edge in the accent color instead of a plain neutral line." },
      { key: "fontScale", label: "Text size", kind: "int", fallback: 100, min: 80, max: 150, step: 5, divisor: 100, decimals: 2,
        hint: "1 is normal, 1.25 is a quarter bigger." },
      { key: "surfaceTint", label: "Window tint", kind: "int", fallback: 0, min: 0, max: 30, step: 1,
        hint: "How much of the accent color washes over the background. 0 keeps it plain." },
      { key: "opacity", label: "Opacity", kind: "int", fallback: 96, min: 50, max: 100, step: 2,
        hint: "Background of this panel. Window previews stay solid." }
    ]
  },
  {
    title: "Motion",
    items: [
      { key: "effect", label: "Opening effect", kind: "enum", fallback: "zoom", control: "effect",
        options: ["fade", "zoom", "slide", "rise", "pop", "drop", "unfold", "none"],
        labels: { fade: "Fade", zoom: "Zoom", slide: "Slide", rise: "Rise", pop: "Pop", drop: "Drop", unfold: "Unfold", none: "None" },
        hint: "How the switcher appears." },
      { key: "closeEffect", label: "Closing effect", kind: "enum", fallback: "fade", control: "effect",
        options: ["fade", "zoom", "slide", "rise", "pop", "drop", "unfold", "none"],
        labels: { fade: "Fade", zoom: "Zoom", slide: "Slide", rise: "Rise", pop: "Pop", drop: "Drop", unfold: "Unfold", none: "None" },
        hint: "How the switcher goes away once you pick a window (the window is focused straight away)." },
      { key: "selectEffect", label: "Changing windows", kind: "enum", fallback: "grow", control: "effect",
        options: ["grow", "lift", "glow", "spotlight", "bounce", "outline", "none"],
        labels: { grow: "Grow", lift: "Lift", glow: "Glow", spotlight: "Spotlight", bounce: "Bounce", outline: "Outline", none: "None" },
        hint: "How the window you move to stands out each time you press Tab." },
      { key: "speed", label: "Speed", kind: "int", fallback: 140, min: 40, max: 600, step: 20,
        hint: "Milliseconds the effects take." }
    ]
  },
  {
    title: "Backdrop",
    items: [
      { key: "backdrop", label: "Behind the switcher", kind: "enum", fallback: "clear", control: "tiles",
        options: ["clear", "dim", "blur"],
        labels: { clear: "Clear", dim: "Darken", blur: "Blur" },
        hint: "Clear leaves your desktop as it is. Darken shades it. Blur blurs everything behind the windows while you choose." },
      { key: "blurAmount", label: "Blur strength", kind: "int", fallback: 45, min: 5, max: 100, step: 5,
        hint: "How soft the desktop gets behind the switcher.",
        when: [{ key: "backdrop", is: ["blur"] }] },
      { key: "blurTint", label: "Blur color", kind: "enum", fallback: "clear", control: "seg",
        options: ["clear", "theme"],
        labels: { clear: "See-through", theme: "Theme color" },
        hint: "See-through only blurs. Theme color also washes the blur with your Colors choice (the theme, your custom background, grey, ...).",
        when: [{ key: "backdrop", is: ["blur"] }] },
      { key: "tintStrength", label: "Color intensity", kind: "int", fallback: 35, min: 0, max: 100, step: 5,
        hint: "How strongly the color covers the blur.",
        when: [{ key: "backdrop", is: ["blur"] }, { key: "blurTint", is: ["theme"] }] },
      { key: "backdropOpacity", label: "Backdrop opacity", kind: "int", fallback: 100, min: 10, max: 100, step: 5,
        hint: "How much of the blur (or how much darkening) you see. Lower lets the sharp desktop show through.",
        when: [{ key: "backdrop", is: ["dim", "blur"] }] }
    ]
  },
  {
    title: "Panel",
    items: [
      { key: "windowWidth", label: "Panel width", kind: "int", fallback: 600, min: 440, max: 1400, step: 20,
        hint: "How wide this panel opens." },
      { key: "windowHeight", label: "Panel height", kind: "int", fallback: 680, min: 440, max: 1100, step: 20,
        hint: "How tall this panel opens." },
      { key: "openAs", label: "Open as", kind: "enum", fallback: "panel", control: "tiles",
        options: ["panel", "window"],
        labels: { panel: "Bar panel", window: "Own window" },
        hint: "Where the bar button opens this panel. You can always pop it out or dock it back from the header." },
      { key: "barDisplay", label: "Bar button shows", kind: "enum", fallback: "icon", control: "seg",
        options: ["icon", "text", "both"],
        labels: { icon: "Icon", text: "Text", both: "Both" },
        hint: "What the button on the bar looks like." },
      { key: "barText", label: "Bar button text", kind: "string", fallback: "Windows", maxLength: 12,
        presets: ["Windows", "Switch", "Tabs"],
        hint: "Used when text is shown.",
        when: [{ key: "barDisplay", is: ["text", "both"] }] },
      { key: "showCount", label: "Window count", kind: "bool", fallback: false,
        hint: "Show how many windows are open next to the bar button." },
      { key: "middleClick", label: "Middle click", kind: "enum", fallback: "switcher", control: "seg",
        options: ["switcher", "none"],
        labels: { switcher: "Open the switcher", none: "Nothing" },
        hint: "What clicking the bar button with the middle mouse button does." }
    ]
  }
];

// palette rows store their target keys (customBg...), not their own key
var colorKeys = {};

var defaults = (() => {
  const d = { mode: "grid" };
  for (let g = 0; g < groups.length; g++)
    for (let i = 0; i < groups[g].items.length; i++) {
      const it = groups[g].items[i];
      if (it.kind === "palette") {
        for (let t = 0; t < it.targets.length; t++) {
          d[it.targets[t].key] = it.fallback[it.targets[t].key];
          colorKeys[it.targets[t].key] = it.fallback[it.targets[t].key];
        }
      } else d[it.key] = it.fallback;
    }
  return d;
})();

var itemByKey = (() => {
  const m = {};
  for (let g = 0; g < groups.length; g++)
    for (let i = 0; i < groups[g].items.length; i++)
      m[groups[g].items[i].key] = groups[g].items[i];
  return m;
})();

function validHex(s) { return /^#([0-9a-fA-F]{3}|[0-9a-fA-F]{6})$/.test(String(s)); }

// check one value against its schema. anything weird -> default,
// so a hand edited settings.json can't break anything
function clean(key, v) {
  if (key === "mode") return modeKeys.indexOf(String(v)) >= 0 ? String(v) : "grid";
  if (colorKeys[key] !== undefined) return validHex(v) ? String(v).toLowerCase() : colorKeys[key];
  if (key === "colorMode" && v === "mono") v = "monochrome";
  const it = itemByKey[key];
  if (!it) return v;
  if (v === null || v === undefined) return it.fallback;
  switch (it.kind) {
  case "enum":
    return it.options.indexOf(String(v)) >= 0 ? String(v) : it.fallback;
  case "int":
    const n = Number(v);
    if (!isFinite(n)) return it.fallback;
    return Math.max(it.min, Math.min(it.max, Math.round(n)));
  case "bool":
    if (v === true || v === "true") return true;
    if (v === false || v === "false") return false;
    return it.fallback;
  case "color":
    return validHex(v) ? String(v) : it.fallback;
  default:
    const s = String(v);
    return it.maxLength ? s.slice(0, it.maxLength) : s;
  }
}

function resolve(values) {
  const out = {};
  const src = values || {};
  for (const k in defaults) out[k] = clean(k, src[k]);
  // old setting: dim amount -> darken backdrop
  if (src.backdrop === undefined && Number(src.dim) > 0) {
    out.backdrop = "dim";
    out.backdropOpacity = clean("backdropOpacity", Math.round(Number(src.dim) / 0.9));
  }
  return out;
}

// stable hue per app name (by category colors)
function hueOf(name) {
  const t = String(name || "").toLowerCase();
  let h = 0;
  for (let k = 0; k < t.length; k++) h = (h * 31 + t.charCodeAt(k)) % 360;
  return h / 360;
}
