/* Runtime defaults and the legacy switching API must not replace the build's
 * provider, including before AppKit creates its first window. */
#include "Testing.h"
#import <AppKit/AppKit.h>
#import <GNUstepGUI/GSTheme.h>

int main(void)
{
  NSAutoreleasePool *pool = [NSAutoreleasePool new];
  NSUserDefaults *defs = [NSUserDefaults standardUserDefaults];
  [defs setVolatileDomain: @{ @"GSTheme": @"MissingRuntimeTheme" }
    forName: NSArgumentDomain];
  GSTheme *builtIn = [GSTheme theme];
  PASS(builtIn != nil, "a provider is compiled in");
  const char *expected = getenv("EXPECT_BUILTIN_THEME");
  if (expected)
    PASS([[builtIn name] isEqualToString: [NSString stringWithUTF8String: expected]],
      "the selected build provider is active");
  [NSApplication sharedApplication];
  NSWindow *window = [[NSWindow alloc] initWithContentRect: NSMakeRect(0,0,240,100)
    styleMask: NSTitledWindowMask backing: NSBackingStoreBuffered defer: NO];
  NSButton *button = [[NSButton alloc] initWithFrame: NSMakeRect(20,20,180,40)];
  [button setTitle: @"Built-in appearance"];
  [[window contentView] addSubview: button];
  [window display];
  PASS([button superview] == [window contentView], "the provider draws a window and button");
  [button release];
  [window release];
  PASS([GSTheme loadThemeNamed: [builtIn name]] == builtIn,
    "the selected name resolves to the compiled provider");
  PASS([GSTheme loadThemeNamed: @"/tmp/Untrusted.theme"] == nil,
    "runtime theme paths are not loaded");
  [defs removeVolatileDomainForName: NSArgumentDomain];
  [defs setVolatileDomain: @{ @"GSTheme": @"AnotherTheme" }
    forName: NSArgumentDomain];
  [[NSNotificationCenter defaultCenter]
    postNotificationName: NSUserDefaultsDidChangeNotification object: defs];
  [[NSNotificationCenter defaultCenter]
    postNotificationName: @"GSThemePreferenceDidChangeNotification" object: nil];
  GSTheme *other = [[GSTheme alloc] initWithBundle: nil];
  [GSTheme setTheme: other];
  PASS([GSTheme theme] == builtIn, "explicit switching is ignored");
  [GSTheme setTheme: nil];
  PASS([GSTheme theme] == builtIn, "defaults and reset retain the provider");
  [other release];
  [pool drain];
  return 0;
}
