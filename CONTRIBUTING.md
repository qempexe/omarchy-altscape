# Contributing

Altscape is small: one list of settings, one file that turns Hyprland's windows into
what the switcher draws, one keybind helper, and the QML that shows them. Most changes
touch one or two files.

```
qml/Service.qml              the windows from Hyprland, focusing and closing, settings, ipc
qml/Switcher.qml             the overlay: opening, closing, keys, effects, the backdrop
qml/BarWidget.qml            the bar button and its panel
qml/core/SwitchState.qml     what a layout draws and how the selection moves
qml/core/FocusRequest.qml    focusing the picked window, and raising it, until Hyprland agrees
qml/core/SwitcherShortcuts.qml  the Hyprland global shortcuts
qml/core/UiState.qml         colors, sizes and the open tab (`ui.*`)
qml/switcher/Viz*.qml        one file per layout, all drawing WindowCard
qml/panel/                   the panel: Visualisers, Settings (SettingRow, TileArt), About
qml/js/Schema.js             every setting and every layout, in the order the panel shows them
qml/js/Model.js              pure logic: windows, workspaces, order and grouping
qml/js/Effects.js            the opening, closing and changing-windows effects
bin/altscape-binds           writes, checks and removes the keybind block
```

## A new setting

1. Add it to a group in `qml/js/Schema.js`: a `key` that never changes once released, a
   `kind` (`bool`, `int`, `enum`, `string`, `color` or `palette`), a `label`, a `fallback`
   and a one-sentence `hint`. An `int` takes `min`, `max` and `step`; an `enum` takes
   `options` and `labels`, and `control: "tiles"` to draw it as tiles (add its picture
   to `qml/panel/TileArt.qml`). `when` dims it unless another setting has one of the
   given values.
2. Read it as `cfg.<key>` (`svc.cfg`, `sw.cfg` in a layout). The value is already clean
   (`Schema.resolve`).

## A new layout

1. Add it to `modes` in `qml/js/Schema.js`, with a `label` and a one-sentence `hint`.
2. Write `qml/switcher/Viz<Name>.qml`: it gets `sw` (the switch state) and `k` (the
   scale, small in the panel's preview), and draws `sw.items` with `WindowCard`. Set
   `sw.navCols` so Up and Down move by a row, and `sw.hoverSelects` to false if the
   selection moves windows under the mouse.
3. Add it to `qml/switcher/SwitchView.qml` and draw its tile in `qml/panel/ModeArt.qml`.

## Rules

- `qml/js/Model.js`, `Schema.js` and `Effects.js` stay pure: no Qt.
- Hyprland is driven through its dispatchers with an address it gave us, never with
  text from a window title.
- Commands are argument arrays, never a shell line with values pasted in.
- `bin/altscape-binds` only writes between its own markers, backs the file up once, and
  reloads Hyprland only when something changed.
- Screen captures stay in memory: nothing is written to disk, nothing goes to the network.
- Text goes through `controls/Txt.qml`, which is plain text only.
- ES6 JavaScript: `const` and `let`, and arrow functions for callbacks.

## Tests

```bash
QT_QPA_PLATFORM=offscreen QT_QPA_PLATFORMTHEME= QT_QUICK_BACKEND=software \
  /usr/lib/qt6/bin/qmltestrunner -input tests
python3 tests/test_bindings.py -v
python3 tests/test_shortcuts.py -v   # in a live Omarchy session, see tests/README.md
```

The Qt tests check the pointer, the selection while windows change, and focusing and
raising the picked window, with no Hyprland running. `test_bindings.py` checks the
keybind block in Lua and classic configs. [tests/README.md](tests/README.md) has the
details, and what to check by hand on a real desktop.

After installing a changed copy, run `omarchy restart shell`: the shell keeps the old
QML loaded otherwise.

Everyone taking part is expected to follow the [code of conduct](CODE_OF_CONDUCT.md).
