#import "Testing.h"
#import <AppKit/AppKit.h>
static NSSplitViewItem *item(void)
{
  NSViewController *vc = AUTORELEASE([NSViewController new]);
  [vc setView: AUTORELEASE([[NSView alloc] initWithFrame: NSMakeRect(0,0,100,100)])];
  return [NSSplitViewItem splitViewItemWithViewController: vc];
}
int main(void)
{
  START_SET("NSSplitViewController replacement")
  [NSApplication sharedApplication];
  NSSplitViewController *controller = AUTORELEASE([NSSplitViewController new]);
  NSSplitViewItem *a = item(), *b = item();
  [controller setSplitViewItems: [NSArray arrayWithObjects: a, b, nil]];
  PASS([[[controller splitView] subviews] count] == 2, "setting items installs both views");
  [controller setSplitViewItems: [NSArray arrayWithObjects: b, a, nil]];
  PASS([[[controller splitView] subviews] objectAtIndex: 0] == [[b viewController] view], "replacement reorders views");
  [controller setSplitViewItems: [controller splitViewItems]];
  PASS([[[controller splitView] subviews] count] == 2, "self-assignment preserves views");
  [controller setSplitViewItems: [NSArray arrayWithObject: a]];
  PASS([[[b viewController] view] superview] == nil, "removed item view is detached");
  [controller setSplitViewItems: nil];
  PASS([[[controller splitView] subviews] count] == 0 && [[controller splitViewItems] count] == 0, "nil clears items and views");
  END_SET("NSSplitViewController replacement")
  return 0;
}
