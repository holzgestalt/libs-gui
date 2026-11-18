# Default application theme

This provider is built and installed with GNUstep GUI from `Themes/Default`.
It was formerly named MacOS27. GNUstep Make's normal `application.make` selects
it automatically; its implementation remains in a separate archive from AppKit.

Direct compiler builds use `pkg-config --libs gnustep-theme-Default` in addition
to `gnustep-config --gui-libs`. See `../README.md` for provider build conventions.

Rounded neutral surfaces, blue default actions and selections, smooth focus rings,
vector check/radio marks, chevrons, switch thumbs, sliders, progress indicators,
menus, tabs, group borders, table headers and scrollbars replace the classic
beveled surfaces and bitmap control adornments. Layout, data sources, target/action,
text editing, explicit custom colors and application content remain AppKit's.
Vector images use NSCustomImageRep and are rendered at the destination resolution.
AppKit's shared GSDrawTiles helper and NSWindow menu bridge are reused;
no classic drawing category is installed on GSDefaultTheme.

This provider uses opaque light fills. Blur, refraction, vibrancy, dark appearance,
SF Symbols and proprietary Apple fonts are not implemented. It uses the installed
AppKit fonts. Native Open/Save and Print panels remain the standard AppKit panels.
Desktop title bars are still owned by the window manager when the backend handles
window decorations; the AppKit-drawn decoration path has a flat title bar and
vector traffic-light button artwork.

## Desktop scaling

The X11/XWayland backend adopts desktop UI scaling at startup independently of
the theme. It prefers `Gdk/WindowScalingFactor` from XSETTINGS, then `Xft.dpi`
(with 96 DPI corresponding to 1×). `GDK_SCALE` can override that desktop policy;
an explicit AppKit `GSScaleFactor` still takes precedence. Physical monitor DPI
is not used to guess a UI scale. This keeps Default independent of GTK libraries.

After installing an updated backend, restart the app to use the new detection.
Changing desktop scale while a Default app is running currently requires a restart.
Run `bash scripts/test-desktop-scale.sh` from the workspace root for automatic
1×/2× and fractional scaling, precedence, malformed-settings and window-geometry
checks against the Default provider.

## Preview and regression checks

After building and installing the Default provider, activate the GNUstep environment:

```sh
clang $(gnustep-config --objc-flags) native/Default/preview.m \
  -o /tmp/default-preview $(python3 scripts/theme-config.py Default --libs) $(gnustep-config --gui-libs)
xvfb-run -a /tmp/default-preview /tmp/default-preview.png
```

The gallery exercises real controls, menus, table selection, tabs and vector
symbols. It asserts distinct normal/pressed button pixels, valid top-tab content
geometry, a real transparent field editor, and custom-background fallback. Run
`Tests/gui/GSTheme/followsDefault.m` as well to verify that runtime defaults and
legacy selection APIs cannot replace this compiled provider.

Visual reference: [Apple's macOS 27 design kits](https://developer.apple.com/news/?id=e2lxw9l1).
This is an independent approximation, not Apple's renderer or artwork.
