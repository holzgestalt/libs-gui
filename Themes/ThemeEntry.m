/* Linked into the application, never into the shared AppKit library. */
#import <Foundation/NSObject.h>
#ifndef GS_THEME_PROVIDER
#error GS_THEME_PROVIDER must name the selected provider factory
#endif
extern Class GS_THEME_PROVIDER(void);
__attribute__((visibility("default")))
Class GSApplicationThemeClass(void)
{
  return GS_THEME_PROVIDER();
}

#ifdef _WIN32
/* libgnustep-gui is a DLL and can't see the executable's symbols, so the
   entry point is handed to it instead (Source/GSTheme.m). */
extern void GSRegisterApplicationThemeClass(Class (*entry)(void));

static void __attribute__((constructor))
GSRegisterThisApplicationTheme(void)
{
  GSRegisterApplicationThemeClass(GSApplicationThemeClass);
}
#endif
