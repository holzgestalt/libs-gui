#import "Testing.h"
#import <AppKit/AppKit.h>
#import <GNUstepGUI/GSTheme.h>

/* A theme without native support must keep the existing tracking path. */
@interface TrackingView : NSMenuView
{
@public
  BOOL appKitTracked;
}
@end
@implementation TrackingView
- (BOOL) _trackWithEvent: (NSEvent *)event startingMenuView: (NSMenuView *)view
{
  appKitTracked = YES;
  return YES;
}
@end

@interface NativeTrackingTheme : GSTheme
{
@public
  BOOL accepts;
  int calls;
}
@end
@implementation NativeTrackingTheme
- (BOOL) trackMenuView: (NSMenuView *)view withEvent: (NSEvent *)event
{
  calls++;
  return accepts;
}
@end

@interface TrackingObserver : NSObject
{
@public
  int begins;
  int ends;
}
- (void) began: (NSNotification *)note;
- (void) ended: (NSNotification *)note;
@end
@implementation TrackingObserver
- (void) began: (NSNotification *)note { begins++; }
- (void) ended: (NSNotification *)note { ends++; }
@end

int main(void)
{
  START_SET("Optional native menu tracking")
  [NSApplication sharedApplication];
  GSTheme *saved = RETAIN([GSTheme theme]);
  GSTheme *stock = AUTORELEASE([[GSTheme alloc] initWithBundle: nil]);
  TrackingView *view = AUTORELEASE([[TrackingView alloc] initWithFrame: NSZeroRect]);
  NSMenu *menu = AUTORELEASE([[NSMenu alloc] initWithTitle: @"Test"]);
  [view setMenu: menu];
  [GSTheme setTheme: stock];
  PASS(![stock trackMenuView: view withEvent: nil], "base theme declines native tracking");
  PASS(![stock displayNativePopUpMenu: menu atScreenRect: NSZeroRect forWindow: nil],
       "base theme declines native positioned menus");
  PASS([view trackWithEvent: nil] && view->appKitTracked, "base theme retains AppKit tracking");

  NativeTrackingTheme *native = AUTORELEASE([[NativeTrackingTheme alloc] initWithBundle: nil]);
  [GSTheme setTheme: native];
  view->appKitTracked = NO;
  PASS([view trackWithEvent: nil] && view->appKitTracked && native->calls == 1,
       "a declining custom theme retains AppKit tracking");

  TrackingObserver *observer = AUTORELEASE([TrackingObserver new]);
  NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
  [center addObserver: observer selector: @selector(began:) name: NSMenuDidBeginTrackingNotification object: menu];
  [center addObserver: observer selector: @selector(ended:) name: NSMenuDidEndTrackingNotification object: menu];
  native->accepts = YES;
  view->appKitTracked = NO;
  PASS([view trackWithEvent: nil] && !view->appKitTracked && native->calls == 2,
       "an accepting theme owns tracking");
  PASS(observer->begins == 1 && observer->ends == 1, "native tracking posts one balanced notification pair");
  [center removeObserver: observer];
  [GSTheme setTheme: saved];
  RELEASE(saved);
  END_SET("Optional native menu tracking")
  return 0;
}
