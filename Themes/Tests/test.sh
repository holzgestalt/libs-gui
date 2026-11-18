#!/usr/bin/env bash
# Run after installing GNUstep Make and GNUstep GUI, with their environment active.
set -eo pipefail
unset GNUSTEP_APPLICATION_THEME GNUSTEP_THEME_BUILD_ROOT
fixtures=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
probe=$(mktemp -d "${TMPDIR:-/tmp}/gnustep-installed-theme.XXXXXX")
trap 'status=$?; if [[ $status != 0 ]]; then cat "$probe"/*.log; fi; rm -rf "$probe"; exit "$status"' EXIT
cp "$fixtures/GNUmakefile" "$fixtures/GNUmakefile.tools" "$fixtures/"*.m "$probe/"
themes=(Default Classic Default)
if [[ -n "${GNUSTEP_TEST_EXTERNAL_THEME:-}" ]]; then themes+=("$GNUSTEP_TEST_EXTERNAL_THEME" Default); fi
for theme in "${themes[@]}"; do
  if [[ "$theme" == Default ]]; then
    make -C "$probe" > "$probe/build.log" 2>&1
  else
    make -C "$probe" GNUSTEP_APPLICATION_THEME="$theme" > "$probe/build.log" 2>&1
  fi
  timeout 15s xvfb-run -a "$probe/ThemeSelection.app/ThemeSelection" "$theme"
done
before=$(stat -c %Y "$probe/ThemeSelection.app/ThemeSelection")
make -C "$probe" > "$probe/repeat.log" 2>&1
[[ "$before" == "$(stat -c %Y "$probe/ThemeSelection.app/ThemeSelection")" ]]
! grep -q 'Linking app' "$probe/repeat.log"
archive=$(pkg-config --variable=archives gnustep-theme-Default | awk '{print $1}')
make -C "$probe" -W "$archive" GNUSTEP_INSTANCE=ThemeSelection GNUSTEP_TYPE=app internal-app-compile > "$probe/archive.log" 2>&1
grep -q 'Linking app' "$probe/archive.log"
make -C "$probe" -f GNUmakefile.tools MAKEFILE_NAME=GNUmakefile.tools > "$probe/tools.log" 2>&1
timeout 15s xvfb-run -a "$probe/obj/GuiThemeTool" Default
"$probe/obj/FoundationTool"
nm "$probe/obj/FoundationTool" > "$probe/foundation-symbols.log"
! grep -q 'GSApplicationThemeClass' "$probe/foundation-symbols.log"
nm "$probe/ProviderHostOnly.bundle/ProviderHostOnly" > "$probe/bundle-symbols.log"
! grep -q 'GSApplicationThemeClass' "$probe/bundle-symbols.log"
make -C "$probe" GNUSTEP_APPLICATION_THEME=none > "$probe/none.log" 2>&1
"$probe/ThemeSelection.app/ThemeSelection" missing
make -C "$probe" > "$probe/restore.log" 2>&1
if make -C "$probe" GNUSTEP_APPLICATION_THEME=MissingProvider > "$probe/missing.log" 2>&1; then exit 1; fi
grep -q 'not installed' "$probe/missing.log"
make -C "$probe" clean GNUSTEP_APPLICATION_THEME=MissingProvider > "$probe/clean.log" 2>&1
printf 'PASS installed-only make: automatic Default, overrides and switch-back, archive dependencies, no redundant relink, GUI tools, host-only bundles, missing-provider error and clean\n'
