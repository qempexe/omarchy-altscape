# Changelog

All notable changes to Altscape. The format follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and versions follow
[Semantic Versioning](https://semver.org/).

## [1.1.0] - 2026-10-29

### Added

- Four new layouts, twelve in all:
  - **Compact**: every window the same size, close together in one panel, with the
    selected window's title underneath, the way Windows and macOS do it. It shrinks the
    previews until every window fits. Thanks to rodrigoGA for the idea (#1).
  - **Spread**: every window at its own shape, as big as the screen allows, in rows
    that fill it.
  - **Columns**: a column per workspace, its windows stacked under its name.
  - **Fan**: the windows spread like a hand of cards, the selected one pulled up.
- **Space between windows** (0 to 48 pixels) and **Same size for every window**, in
  Settings › Previews, for every layout that lines windows up.
- A search box above the settings that looks through every tab.
- A logo, in the panel header too, and an **About** tab with the version and a link to
  more plugins.
- The keybind block also turns off Hyprland's own layer animation for the switcher, so
  only Altscape's effects play. Thanks to PeterHennesey for the tip (#2).
- Qt tests for the pointer, the selection and focusing (`qmltestrunner -input tests`),
  binding upgrade tests and live shortcut tests. Thanks to rugobal.
- A changelog, a contributing guide and a code of conduct.

### Changed

- The managed Alt/Super+Tab binds use Hyprland global shortcuts, so a fast tap and the
  modifier release reach the switcher in order. Thanks to rugobal (#6).
- The settings tabs share the width evenly, with About as the last one.
- The JavaScript is written in ES6: `const` and `let`, and arrow functions.
- The README follows a new layout, with new screenshots and a new preview.

### Fixed

- Closing the switcher no longer flashes its last frame back on screen. Thanks to
  PeterHennesey for the report (#2).
- Custom colors show as they are picked: your text color is no longer swapped for black
  or white when it is close to the background, chips use it too, and text on the
  accent is your background or text color, whichever reads better.
- With no window to switch to (none open, or none in the chosen scope), letting go of
  Alt or pressing Enter closes the switcher instead of leaving it up empty.
- A mouse resting over the switcher no longer takes the selection away from the
  keyboard when previews move underneath it. Thanks to rugobal (#5).
- The picked window gets focus even while the switcher still holds the keyboard, by
  trying again until Hyprland confirms it. Thanks to rugobal (#7).
- Holding the shortcut keeps the window it opened on, and floating windows keep their
  focus. Thanks to rugobal (#8).
- A floating window that was picked is raised above the other floating windows, also
  when it already had focus. Thanks to rugobal (#9).

## [1.0.2] - 2026-10-15

### Added

- **Super+Alt+Shift+S** opens the settings from anywhere, and a `settings` command does
  the same.

## [1.0.1] - 2026-10-15

### Changed

- The QML lives in folders: `core/`, `js/`, `switcher/`, `panel/` and `controls/`.

## [1.0.0] - 2026-10-15

### Added

- An Alt+Tab window switcher for Omarchy with live previews in eight layouts: grid,
  strip, carousel, ring, list, overview, stack and dock.
- Opening, closing and changing-windows effects, a blurred or darkened backdrop, and
  colors that follow the theme.
- A bar panel to pick the layout and tune every setting, and a managed Alt+Tab bind.

[1.1.0]: https://github.com/qempexe/omarchy-altscape/compare/v1.0.2...v1.1.0
[1.0.2]: https://github.com/qempexe/omarchy-altscape/compare/v1.0.1...v1.0.2
[1.0.1]: https://github.com/qempexe/omarchy-altscape/compare/v1.0.0...v1.0.1
[1.0.0]: https://github.com/qempexe/omarchy-altscape/releases/tag/v1.0.0
