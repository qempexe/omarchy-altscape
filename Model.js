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
  var scale = Number(m.scale) > 0 ? Number(m.scale) : 1;
  var w = Number(m.width) / scale;
  var h = Number(m.height) / scale;
  var t = Number(m.transform) || 0;
  if (t % 2 === 1) { var s = w; w = h; h = s; }
  return { x: Number(m.x) || 0, y: Number(m.y) || 0, w: Math.max(1, w), h: Math.max(1, h) };
}

function wsLabel(id, name) {
  var n = String(name || "");
  if (Number(id) < 0) return "Scratchpad" + (n.indexOf("special:") === 0 && n.length > 8 ? " " + n.slice(8) : "");
  if (n === "" || n === String(id)) return "Workspace " + id;
  return n;
}

// snapshot = { clients, workspaces, monitors } from hyprctl -j
function parseSnapshot(snap) {
  var mons = Array.isArray(snap.monitors) ? snap.monitors : [];
  var monById = {};
  var focusedMon = null;
  for (var i = 0; i < mons.length; i++) {
    monById[mons[i].id] = mons[i];
    if (mons[i].focused === true) focusedMon = mons[i];
  }
  if (!focusedMon && mons.length > 0) focusedMon = mons[0];

  var wsList = Array.isArray(snap.workspaces) ? snap.workspaces : [];
  var wsInfo = {};
  for (var j = 0; j < wsList.length; j++) wsInfo[wsList[j].id] = wsList[j];

  var out = [];
  var clients = Array.isArray(snap.clients) ? snap.clients : [];
  for (var k = 0; k < clients.length; k++) {
    var c = clients[k];
    if (!c || c.mapped === false || !c.address) continue;
    var ws = c.workspace || { id: 0, name: "" };
    if (Number(ws.id) === 0 && String(ws.name || "") === "") continue;   // not on any workspace yet
    var mon = monById[c.monitor] || focusedMon || { x: 0, y: 0, width: 1920, height: 1080, scale: 1, transform: 0, name: "" };
    var box = monitorBox(mon);
    var at = Array.isArray(c.at) ? c.at : [0, 0];
    var size = Array.isArray(c.size) ? c.size : [box.w, box.h];
    var cls = String(c["class"] || c.initialClass || "");
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

  var workspaces = [];
  for (var w = 0; w < wsList.length; w++) {
    var wi = wsList[w];
    var wm = null;
    for (var q = 0; q < mons.length; q++) if (mons[q].name === wi.monitor) wm = mons[q];
    var b = monitorBox(wm || focusedMon || { width: 1920, height: 1080 });
    workspaces.push({ id: Number(wi.id), name: String(wi.name || ""), label: wsLabel(wi.id, wi.name),
                      monitor: String(wi.monitor || ""), special: isSpecial(wi), aspect: b.w / b.h });
  }

  var activeByMonitor = {};
  for (var a = 0; a < mons.length; a++)
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
  var scope = cfg.scope;
  var items = [];
  var src = state && state.windows ? state.windows : [];
  for (var i = 0; i < src.length; i++) {
    var w = src[i];
    if (w.special && (cfg.showSpecial !== true || scope === "workspace")) continue;
    if (scope === "monitor" && w.monitor !== state.focusedMonitor) continue;
    if (scope === "workspace" && w.ws !== state.activeWorkspace) continue;
    if (scope === "others" && w.ws === state.activeWorkspace) continue;
    items.push(w);
  }

  var activeIds = {};
  for (var m in state.activeByMonitor || {}) activeIds[state.activeByMonitor[m]] = true;

  var groups = [];
  if (cfg.order === "recent") {
    items.sort(function(a, b) { return a.focusId - b.focusId; });
  } else {
    items.sort(function(a, b) {
      if (a.special !== b.special) return a.special ? 1 : -1;
      if (a.ws !== b.ws) return a.ws - b.ws;
      return a.focusId - b.focusId;
    });
    var byId = {};
    for (var k = 0; k < items.length; k++) {
      var it = items[k];
      if (!byId[it.ws]) {
        byId[it.ws] = { id: it.ws, label: it.wsLabel, monitor: it.monitor, special: it.special,
                        active: activeIds[it.ws] === true, aspect: it.aspect, start: k, count: 0 };
        groups.push(byId[it.ws]);
      }
      byId[it.ws].count++;
    }
    // empty workspaces only make sense where workspaces are drawn as places
    if (cfg.showEmpty === true && scope !== "workspace") {
      var ws = state.workspaces || [];
      for (var e = 0; e < ws.length; e++) {
        var x = ws[e];
        if (byId[x.id] || x.special) continue;
        if (scope === "others" && x.id === state.activeWorkspace) continue;
        if (scope === "monitor" && x.monitor !== state.focusedMonitor) continue;
        groups.push({ id: x.id, label: x.label, monitor: x.monitor, special: false,
                      active: activeIds[x.id] === true, aspect: x.aspect, start: items.length, count: 0 });
      }
      groups.sort(function(a, b) {
        if (a.special !== b.special) return a.special ? 1 : -1;
        return a.id - b.id;
      });
    }
  }

  // alt+tab starts on the previous window, shift on the oldest
  var current = 0, next = 0, prev = 0;
  if (items.length > 0) {
    var ranked = items.map(function(x, idx) { return { f: x.focusId, i: idx }; });
    ranked.sort(function(a, b) { return a.f - b.f; });
    current = ranked[0].i;
    // "other workspaces": focused window isn't in the list, so the newest one is the target
    next = scope === "others" || ranked.length < 2 ? ranked[0].i : ranked[1].i;
    prev = ranked[ranked.length - 1].i;
  }
  return { items: items, groups: groups, current: current, next: next, prev: prev };
}

function indexOfKey(items, key) {
  for (var i = 0; i < items.length; i++) if (items[i].key === key) return i;
  return -1;
}

// biggest cols x rows grid for n boxes of aspect ar in w x h (head = label height)
function bestGrid(n, ar, w, h, gap, head) {
  var best = { cols: 1, rows: 1, bw: 0, bh: 0 };
  if (n <= 0) return best;
  for (var cols = 1; cols <= n; cols++) {
    var rows = Math.ceil(n / cols);
    var bw = (w - gap * (cols - 1)) / cols;
    var bh = (h - gap * (rows - 1)) / rows - head;
    if (bw <= 0 || bh <= 0) continue;
    if (bw / bh > ar) bw = bh * ar; else bh = bw / ar;
    if (bw > best.bw) best = { cols: cols, rows: rows, bw: bw, bh: bh };
  }
  return best;
}
