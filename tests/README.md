Run the pointer-selection regression tests with Qt 6's `qmltestrunner`:

```sh
QT_QPA_PLATFORM=offscreen QT_QPA_PLATFORMTHEME= QT_QUICK_BACKEND=software \
  qmltestrunner -input tests
```

On Arch Linux, the executable is `/usr/lib/qt6/bin/qmltestrunner`.
The tests use the real switch state and Qt mouse events, including moving a
preview beneath a stationary pointer. No running Hyprland session is required.
