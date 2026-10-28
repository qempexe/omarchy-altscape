Run the pointer-selection regression tests with Qt 6's `qmltestrunner`:

```sh
QT_QPA_PLATFORM=offscreen QT_QPA_PLATFORMTHEME= QT_QUICK_BACKEND=software \
  qmltestrunner -input tests
```

On Arch Linux, the executable is `/usr/lib/qt6/bin/qmltestrunner`.
The tests use the real switch state and Qt mouse events, including moving a
preview beneath a stationary pointer. No running Hyprland session is required.

Check managed binding upgrades for Alt and Super, in Lua and classic configs:

```sh
python3 tests/test_bindings.py -v
```

Run the live global-shortcut regression tests in an unlocked Omarchy session
with Hyprland's Lua API, Quickshell and `wtype` installed:

```sh
python3 tests/test_shortcuts.py -v
```

These tests use the real shortcut component and switcher with three dummy
windows. They check rapid taps (including 50 consecutive taps), held cycling,
reverse cycling, modifier release after other keys, duplicate releases, manual
opening and disabling switch on release. No application window is focused or
closed, but the test overlay briefly appears. F33–F35 must be unused. The tests
temporarily enable `input:resolve_binds_by_sym` for wtype's generated keymap and
restore its previous value and remove the test bindings on completion.

When testing an installed plugin, run `omarchy restart shell` before checking
desktop behavior. On Omarchy 4.5.0rc1, rescanning plugins alone can keep cached
nested QML components, leaving the previous code running.
