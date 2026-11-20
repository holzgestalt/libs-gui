#import <AppKit/AppKit.h>
#import "Testing.h"

/* A view whose state is one key path, and a restoration class that makes a
   window of its own, as an application's would. */
@interface RestorableTestView : NSView
{
  NSInteger mode;
}
@end

@implementation RestorableTestView
+ (NSArray *) restorableStateKeyPaths
{
  return [NSArray arrayWithObject: @"mode"];
}
- (NSInteger) mode { return mode; }
- (void) setMode: (NSInteger)m { mode = m; }
@end

static NSWindow *restoredWindow = nil;
static NSString *restoredIdentifier = nil;

@interface RestorationTestClass : NSObject <NSWindowRestoration>
@end

@implementation RestorationTestClass
+ (void) restoreWindowWithIdentifier: (NSUserInterfaceItemIdentifier)identifier
                               state: (NSCoder *)state
                   completionHandler: (GSWindowRestorationHandler)handler
{
  restoredIdentifier = [identifier copy];
  restoredWindow = [[NSWindow alloc]
    initWithContentRect: NSMakeRect(0, 0, 100, 100)
              styleMask: NSTitledWindowMask
                backing: NSBackingStoreBuffered
                  defer: YES];
  [restoredWindow setReleasedWhenClosed: NO];
  [restoredWindow setIdentifier: identifier];
  CALL_BLOCK(handler, restoredWindow, nil);
}
@end

static NSWindow *
makeWindow(NSRect frame)
{
  NSWindow *window = [[NSWindow alloc] initWithContentRect: frame
    styleMask: NSTitledWindowMask | NSResizableWindowMask
    backing: NSBackingStoreBuffered defer: YES];
  [window setReleasedWhenClosed: NO];
  return window;
}

int main(void)
{
  NSAutoreleasePool *pool = [NSAutoreleasePool new];
  NSWindow *window;
  NSWindow *copy;
  NSMutableString *identifier;
  RestorableTestView *view;
  RestorableTestView *copiedView;
  NSMutableData *data;
  NSKeyedArchiver *archiver;
  NSKeyedUnarchiver *unarchiver;

  START_SET("NSWindow restorable state")

  NS_DURING
    {
      [NSApplication sharedApplication];
    }
  NS_HANDLER
    {
      if ([[localException name] isEqualToString: NSInternalInconsistencyException])
        SKIP("It looks like GNUstep backend is not yet installed")
    }
  NS_ENDHANDLER

  window = makeWindow(NSMakeRect(100, 100, 300, 200));
  PASS([window isRestorable], "windows are restorable by default");
  PASS([window restorationClass] == Nil, "windows have no restoration class by default");
  PASS([window identifier] == nil, "windows have no identifier by default");

  identifier = [NSMutableString stringWithString: @"Main"];
  [window setIdentifier: identifier];
  [identifier appendString: @"Changed"];
  PASS([[window identifier] isEqual: @"Main"], "identifiers are copied");

  [window setRestorable: NO];
  PASS(![window isRestorable], "-setRestorable: NO is kept");
  [window setRestorable: YES];
  [window setRestorationClass: [RestorationTestClass class]];
  PASS([window restorationClass] == [RestorationTestClass class],
    "-setRestorationClass: is kept");

  view = [[RestorableTestView alloc] initWithFrame: NSMakeRect(0, 0, 10, 10)];
  [view setIdentifier: @"Sidebar"];
  [view setMode: 3];
  [[window contentView] addSubview: view];

  data = [NSMutableData data];
  archiver = [[NSKeyedArchiver alloc] initForWritingWithMutableData: data];
  [window encodeRestorableStateWithCoder: archiver];
  [archiver finishEncoding];
  [archiver release];
  PASS([data length] > 0, "a window encodes its restorable state");

  copy = makeWindow(NSMakeRect(0, 0, 50, 50));
  copiedView = [[RestorableTestView alloc] initWithFrame: NSMakeRect(0, 0, 10, 10)];
  [copiedView setIdentifier: @"Sidebar"];
  [[copy contentView] addSubview: copiedView];
  unarchiver = [[NSKeyedUnarchiver alloc] initForReadingWithData: data];
  [copy restoreStateWithCoder: unarchiver];
  [unarchiver finishDecoding];
  [unarchiver release];
  PASS(NSEqualRects([copy frame], [window frame]),
    "restoring the state restores the frame");
  PASS([copiedView mode] == 3,
    "views with an identifier restore their key paths");

  data = [NSMutableData data];
  archiver = [[NSKeyedArchiver alloc] initForWritingWithMutableData: data];
  [archiver encodeObject: @"RestorationTestClass" forKey: @"GSRestorationClass"];
  [window encodeRestorableStateWithCoder: archiver];
  [archiver finishEncoding];
  [archiver release];
  unarchiver = [[NSKeyedUnarchiver alloc] initForReadingWithData: data];
  PASS([NSApp restoreWindowWithIdentifier: @"Main" state: unarchiver
                        completionHandler: NULL],
    "the application finds the restoration class in the state");
  PASS([restoredIdentifier isEqual: @"Main"] && restoredWindow != nil,
    "the restoration class is asked for the window");
  [unarchiver finishDecoding];
  [unarchiver release];

  data = [NSMutableData data];
  archiver = [[NSKeyedArchiver alloc] initForWritingWithMutableData: data];
  [archiver encodeObject: @"NoSuchRestorationClass" forKey: @"GSRestorationClass"];
  [archiver finishEncoding];
  [archiver release];
  unarchiver = [[NSKeyedUnarchiver alloc] initForReadingWithData: data];
  PASS(![NSApp restoreWindowWithIdentifier: @"Main" state: unarchiver
                         completionHandler: NULL],
    "a missing restoration class is reported");
  [unarchiver finishDecoding];
  [unarchiver release];

  [view release];
  [copiedView release];
  [window release];
  [copy release];
  [restoredWindow release];

  END_SET("NSWindow restorable state")

  [pool drain];
  return 0;
}
