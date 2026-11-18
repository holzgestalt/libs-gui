# Application appearance providers

GNUstep GUI builds and installs two appearance providers:

- `Default`: the standard opaque, rounded appearance, formerly named MacOS27.
- `Classic`: the traditional GNUstep appearance and a base for other providers.

Both are built by the normal top-level `make` and installed by `make install`.
Their source files live here, while their implementation archives remain
separate from the shared AppKit library. AppKit supplies the theme interface,
models, controls and graphics support without containing a concrete provider.

With GNUstep Make's application-theme support installed, an ordinary application
needs only the standard `common.make` and `application.make` includes. The GUI
configuration selects `Default` automatically. Override the selection with:

```
make GNUSTEP_APPLICATION_THEME=Classic
```

An independently installed provider can be selected by its registered name in
the same way. No workspace path or custom application makefile include is needed.
Provider changes and archive updates relink the executable. Libraries and bundles
do not link an application appearance.

GUI tools declare `NEEDS_GUI = yes` (or a target-specific `NAME_NEEDS_GUI = yes`)
and receive the same default and override support. Foundation-only tools do not
link a provider. `Tests/test.sh` exercises installed-only builds in a temporary
directory, theme switching, archive dependencies, GUI tools and host-only bundles.

Direct compiler builds can obtain the full link flags using
`pkg-config --libs gnustep-theme-Default`, in addition to the normal
`gnustep-config --gui-libs` flags. Each provider installs a separate entry archive
which exports `GSApplicationThemeClass` for the application. Its implementation
archive exports `GSThemeProvider_NAME` and can be used as a fallback without
bringing in a second application entry point.

`ThemeSupport/provider.make`, installed in GNUstep Make's support directory,
builds provider archives, optional public headers and pkg-config metadata.
External providers supply their own sources, dependencies and extra link flags.
Classic's public `GNUstepGUI/GSClassicTheme.h` supports subclassing without a
dependency on the GUI source tree for that interface.

The shared library intentionally rejects direct compiler builds that omit an
application provider. `GNUSTEP_APPLICATION_THEME=none` is available for tests
which verify that error or supply their own entry point.
