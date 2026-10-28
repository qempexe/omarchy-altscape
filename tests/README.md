Run the pointer-selection regression tests with Qt 6's `qmltestrunner`:

```sh
QT_QPA_PLATFORM=offscreen QT_QPA_PLATFORMTHEME= QT_QUICK_BACKEND=software \
  qmltestrunner -input tests
```

On Arch Linux, the executable is `/usr/lib/qt6/bin/qmltestrunner`.
The tests use the real switch state and Qt mouse events, including moving a
preview beneath a stationary pointer. No running Hyprland session is required.

When testing an installed plugin, run `omarchy restart shell` before checking
desktop behavior. On Omarchy 4.5.0rc1, rescanning plugins alone can keep cached
nested QML components, leaving the previous code running.
