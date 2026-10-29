.pragma library

// hyprctl json in, ordered window list out. no qml in here on purpose,
// all the ordering rules are in this one file

function norm(addr) {
  return String(addr || "").toLowerCase().replace(/^0x/, "");
}

function isSpecial(ws) {
  return Number(ws.id) < 0 || String(ws.name || "").indexOf("special") === 0;
}

// hyprland gives pixels, windows use scaled coords, and rotated monitors swap w/h
function monitorBox(m) {
  const scale = Number(m.scale) > 0 ? Number(m.scale) : 1;
  let w = Number(m.width) / scale;
  let h = Number(m.height) / scale;
  const t = Number(m.transform) || 0;
  if (t % 2 === 1) { const s = w; w = h; h = s; }
  return { x: Number(m.x) || 0, y: Number(m.y) || 0, w: Math.max(1, w), h: Math.max(1, h) };
}

function wsLabel(id, name) {
  const n = String(name || "");
  if (Number(id) < 0) return "Scratchpad" + (n.indexOf("special:") === 0 && n.length > 8 ? " " + n.slice(8) : "");
  if (n === "" || n === String(id)) return "Workspace " + id;
  return n;
}

// snapshot = { clients, workspaces, monitors } from hyprctl -j
function parseSnapshot(snap) {
  const mons = Array.isArray(snap.monitors) ? snap.monitors : [];
  const monById = {};
  let focusedMon = null;
  for (let i = 0; i < mons.length; i++) {
    monById[mons[i].id] = mons[i];
    if (mons[i].focused === true) focusedMon = mons[i];
  }
  if (!focusedMon && mons.length > 0) focusedMon = mons[0];

  const wsList = Array.isArray(snap.workspaces) ? snap.workspaces : [];
  const wsInfo = {};
  for (let j = 0; j < wsList.length; j++) wsInfo[wsList[j].id] = wsList[j];

  const out = [];
  const clients = Array.isArray(snap.clients) ? snap.clients : [];
  for (let k = 0; k < clients.length; k++) {
    const c = clients[k];
    if (!c || c.mapped === false || !c.address) continue;
    const ws = c.workspace || { id: 0, name: "" };
    if (Number(ws.id) === 0 && String(ws.name || "") === "") continue;   // not on any workspace yet
    const mon = monById[c.monitor] || focusedMon || { x: 0, y: 0, width: 1920, height: 1080, scale: 1, transform: 0, name: "" };
    const box = monitorBox(mon);
    const at = Array.isArray(c.at) ? c.at : [0, 0];
    const size = Array.isArray(c.size) ? c.size : [box.w, box.h];
    const cls = String(c["class"] || c.initialClass || "");
    out.push({
      address: String(c.address),
      key: norm(c.address),
      title: String(c.title || c.initialTitle || cls || "Window"),
      cls: cls,
      ws: Number(ws.id),
      wsName: String(ws.name || ""),
      wsLabel: wsLabel(ws.id, ws.name),
      special: isSpecial(ws),
      monitor: String(mon.name || ""),
      focusId: Number(c.focusHistoryID) >= 0 ? Number(c.focusHistoryID) : 999,
      floating: c.floating === true,
      fullscreen: c.fullscreen === true || Number(c.fullscreen) > 0,
      rx: Math.max(0, Math.min(1, (Number(at[0]) - box.x) / box.w)),
      ry: Math.max(0, Math.min(1, (Number(at[1]) - box.y) / box.h)),
      rw: Math.max(0.02, Math.min(1, Number(size[0]) / box.w)),
      rh: Math.max(0.02, Math.min(1, Number(size[1]) / box.h)),
      aspect: box.w / box.h
    });
  }

  const workspaces = [];
  for (let w = 0; w < wsList.length; w++) {
    const wi = wsList[w];
    let wm = null;
    for (let q = 0; q < mons.length; q++) if (mons[q].name === wi.monitor) wm = mons[q];
    const b = monitorBox(wm || focusedMon || { width: 1920, height: 1080 });
    workspaces.push({ id: Number(wi.id), name: String(wi.name || ""), label: wsLabel(wi.id, wi.name),
                      monitor: String(wi.monitor || ""), special: isSpecial(wi), aspect: b.w / b.h });
  }

  const activeByMonitor = {};
  for (let a = 0; a < mons.length; a++)
    if (mons[a].activeWorkspace) activeByMonitor[mons[a].name] = Number(mons[a].activeWorkspace.id);

  return {
    windows: out,
    workspaces: workspaces,
    focusedMonitor: focusedMon ? String(focusedMon.name || "") : "",
    activeWorkspace: focusedMon && focusedMon.activeWorkspace ? Number(focusedMon.activeWorkspace.id) : 1,
    activeByMonitor: activeByMonitor
  };
}

// what the switcher shows, in the order you move through it.
// items: flat list, every layout walks it in this order
// groups: one per workspace (empty in "recent" order)
// current/next/prev: focused window and the alt+tab targets
function build(state, cfg) {
  const scope = cfg.scope;
  const items = [];
  const src = state && state.windows ? state.windows : [];
  for (let i = 0; i < src.length; i++) {
    const w = src[i];
    if (w.special && (cfg.showSpecial !== true || scope === "workspace")) continue;
    if (scope === "monitor" && w.monitor !== state.focusedMonitor) continue;
    if (scope === "workspace" && w.ws !== state.activeWorkspace) continue;
    if (scope === "others" && w.ws === state.activeWorkspace) continue;
    items.push(w);
  }

  const activeIds = {};
  for (const m in state.activeByMonitor || {}) activeIds[state.activeByMonitor[m]] = true;

  const groups = [];
  if (cfg.order === "recent") {
    items.sort((a, b) => a.focusId - b.focusId);
  } else {
    items.sort((a, b) => {
      if (a.special !== b.special) return a.special ? 1 : -1;
      if (a.ws !== b.ws) return a.ws - b.ws;
      return a.focusId - b.focusId;
    });
    const byId = {};
    for (let k = 0; k < items.length; k++) {
      const it = items[k];
      if (!byId[it.ws]) {
        byId[it.ws] = { id: it.ws, label: it.wsLabel, monitor: it.monitor, special: it.special,
                        active: activeIds[it.ws] === true, aspect: it.aspect, start: k, count: 0 };
        groups.push(byId[it.ws]);
      }
      byId[it.ws].count++;
    }
    // empty workspaces only make sense where workspaces are drawn as places
    if (cfg.showEmpty === true && scope !== "workspace") {
      const ws = state.workspaces || [];
      for (let e = 0; e < ws.length; e++) {
        const x = ws[e];
        if (byId[x.id] || x.special) continue;
        if (scope === "others" && x.id === state.activeWorkspace) continue;
        if (scope === "monitor" && x.monitor !== state.focusedMonitor) continue;
        groups.push({ id: x.id, label: x.label, monitor: x.monitor, special: false,
                      active: activeIds[x.id] === true, aspect: x.aspect, start: items.length, count: 0 });
      }
      groups.sort((a, b) => {
        if (a.special !== b.special) return a.special ? 1 : -1;
        return a.id - b.id;
      });
    }
  }

  // alt+tab starts on the previous window, shift on the oldest
  let current = 0, next = 0, prev = 0;
  if (items.length > 0) {
    const ranked = items.map((x, idx) => ({
      f: x.focusId,
      i: idx
    }));
    ranked.sort((a, b) => a.f - b.f);
    current = ranked[0].i;
    // "other workspaces": focused window isn't in the list, so the newest one is the target
    next = scope === "others" || ranked.length < 2 ? ranked[0].i : ranked[1].i;
    prev = ranked[ranked.length - 1].i;
  }
  return { items: items, groups: groups, current: current, next: next, prev: prev };
}

function indexOfKey(items, key) {
  for (let i = 0; i < items.length; i++) if (items[i].key === key) return i;
  return -1;
}

// biggest cols x rows grid for n boxes of aspect ar in w x h (head = label height)
function bestGrid(n, ar, w, h, gap, head) {
  let best = { cols: 1, rows: 1, bw: 0, bh: 0 };
  if (n <= 0) return best;
  for (let cols = 1; cols <= n; cols++) {
    const rows = Math.ceil(n / cols);
    let bw = (w - gap * (cols - 1)) / cols;
    let bh = (h - gap * (rows - 1)) / rows - head;
    if (bw <= 0 || bh <= 0) continue;
    if (bw / bh > ar) bw = bh * ar; else bh = bw / ar;
    if (bw > best.bw) best = { cols: cols, rows: rows, bw: bw, bh: bh };
  }
  return best;
}

// spread: rows of windows at their own shape, as big as fits in w x h.
// ars = width / height of each window. returns the row height and, per window,
// x, y, w, h, with every row centered and the whole block centered.
function spread(ars, w, h, gap, maxH) {
  const n = ars.length;
  if (n <= 0 || w <= 0 || h <= 0) return { rowH: 0, boxes: [] };
  const rowsFor = rh => {
    const rows = [];
    let row = [], used = 0;
    for (let i = 0; i < n; i++) {
      const bw = rh * ars[i];
      if (row.length > 0 && used + gap + bw > w) { rows.push(row); row = []; used = 0; }
      used += (row.length > 0 ? gap : 0) + bw;
      row.push(i);
    }
    if (row.length > 0) rows.push(row);
    return rows;
  };
  const fits = rh => {
    const rows = rowsFor(rh);
    if (rows.length * rh + (rows.length - 1) * gap > h) return false;
    for (const r of rows) if (r.length === 1 && rh * ars[r[0]] > w) return false;
    return true;
  };
  let lo = 4, hi = Math.min(h, maxH > 0 ? maxH : h);
  if (!fits(lo)) lo = 1;
  for (let k = 0; k < 30; k++) {
    const mid = (lo + hi) / 2;
    if (fits(mid)) lo = mid; else hi = mid;
  }
  const rh = Math.floor(lo);
  const rows = rowsFor(rh);
  const boxes = new Array(n);
  const total = rows.length * rh + (rows.length - 1) * gap;
  let y = (h - total) / 2;
  for (const r of rows) {
    let rw = (r.length - 1) * gap;
    for (const i of r) rw += Math.min(w, rh * ars[i]);
    let x = (w - rw) / 2;
    for (const i of r) {
      const bw = Math.min(w, rh * ars[i]);
      boxes[i] = { x: Math.round(x), y: Math.round(y), w: Math.round(bw), h: rh };
      x += bw + gap;
    }
    y += rh + gap;
  }
  return { rowH: rh, boxes: boxes };
}
