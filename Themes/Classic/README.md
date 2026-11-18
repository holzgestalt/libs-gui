# Classic GNUstep appearance

This provider preserves the traditional GNUstep appearance. It is built and
installed with GNUstep GUI, alongside the standard Default provider.

Select it for an application with `make GNUSTEP_APPLICATION_THEME=Classic`.
Direct compiler builds can use `pkg-config --libs gnustep-theme-Classic` in
addition to `gnustep-config --gui-libs`.

`GNUstepGUI/GSClassicTheme.h` is installed for providers which subclass Classic.
The implementation archive can be linked without the separate entry archive
when Classic is used only as a fallback. See `../README.md` for details.
