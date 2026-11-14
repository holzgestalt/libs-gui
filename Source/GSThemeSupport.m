/* Theme-neutral window/menu access and panel allocation support. */
#import <AppKit/NSWindow.h>
#import <AppKit/NSPrintPanel.h>
#import <AppKit/NSPageLayout.h>
#import <GNUstepGUI/GSWindowDecorationView.h>
#import "GSThemePrivate.h"
@implementation NSWindow (Private)
- (GSWindowDecorationView *) windowView
{
  return _wv;
}

- (void) _setMenu: (NSMenu *)menu
{
  [super setMenu: menu];
}
@end

@implementation GSPrintPanel

+ (id) allocWithZone: (NSZone*)zone
{
  return NSAllocateObject(self, 0, zone);
}

@end

@implementation GSPageLayout

+ (id) allocWithZone: (NSZone*)zone
{
  return NSAllocateObject(self, 0, zone);
}

@end
