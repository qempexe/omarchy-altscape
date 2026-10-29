Run the pointer-selection, selection-refresh and focus-request regression tests with Qt 6's
`qmltestrunner`:

```sh
QT_QPA_PLATFORM=offscreen QT_QPA_PLATFORMTHEME= QT_QUICK_BACKEND=software \
  qmltestrunner -input tests
```

On Arch Linux, the executable is `/usr/lib/qt6/bin/qmltestrunner`.
The tests use the real switch state and Qt mouse events, including moving a
preview beneath a stationary pointer. Focus tests check retries until the target
is acknowledged, replacement and cancellation of pending requests, and bounded
retries for unavailable windows. They also check recovery when overlay teardown
restores the old floating window just after a transient focus acknowledgement.
Acknowledgement also raises the selected window, including a window that already
has keyboard focus but is behind other floating windows. Cancelled, replaced and
unavailable targets must not trigger a raise.
Selection-refresh tests keep the highlighted window through focus-history
changes while the switcher is open, including before any explicit navigation.
No running Hyprland session is required.

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
reverse cycling, modifier release after other keys, animated closing, both
modifier/Tab release orders, duplicate releases, manual opening and disabling
switch on release. No application window is focused or closed, but the test
overlay briefly appears. F33–F35 must be unused. The release-order cases also
use Ctrl+Tab and Control_L when those bindings are unused; otherwise those cases
are skipped. The tests temporarily enable `input:resolve_binds_by_sym` for
wtype's generated keymap and
restore its previous value and remove the test bindings on completion.

When testing an installed plugin, run `omarchy restart shell` before checking
desktop behavior. On Omarchy 4.5.0rc1, rescanning plugins alone can keep cached
nested QML components, leaving the previous code running.

Also verify actual focus with at least two application windows: tap the configured
shortcut with 1–10 ms holds and check `hyprctl -j activewindow` after each tap.
For floating windows, also check that the selected address is at the top of its
workspace's stack in `hyprctl -j clients`, including an already-focused window
covered by another float. Keyboard focus alone does not confirm a raise.
Also hold the modifier for 150–350 ms before releasing it to catch focus-history
updates changing the initial selection while the switcher is still open.
Test releasing Tab first and releasing the modifier first, with closing effects
enabled. The live shortcut fixture records the selected address without focusing
an application, so it cannot detect a focus request rejected while the overlay
still holds its keyboard grab.
