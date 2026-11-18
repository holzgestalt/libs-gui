#import "ObjectTesting.h"
#import <AppKit/AppKit.h>
#import <GNUstepGUI/GSTheme.h>

int main(void)
{
  START_SET("NSScroller optional native theme hooks")
  [NSApplication sharedApplication];
  GSTheme *base = [[GSTheme alloc] initWithBundle:nil];
  NSScroller *bar = [[NSScroller alloc] initWithFrame:NSMakeRect(0,0,18,200)];
  NSRect sentinel = NSMakeRect(1,2,3,4), result = sentinel;
  PASS(![base getScrollerRect:&result forPart:NSScrollerKnob inScroller:bar],
    "base theme retains standard part geometry")
  PASS(NSEqualRects(result, sentinel), "declined geometry leaves output untouched")
  PASS(![base drawNativeScroller:bar dirtyRect:[bar bounds]],
    "base theme retains standard part drawing")
  [bar setEnabled:YES];
  PASS([bar isEnabled], "enabled getter reads the scroller state")
  [bar setEnabled:NO];
  PASS(![bar isEnabled], "disabled getter reads the scroller state")
  [bar setKnobProportion:.25];
  PASS([bar isEnabled], "scrollable content enables the scroller")
  [bar setKnobProportion:1];
  PASS(![bar isEnabled], "full-page content disables the scroller")
  [bar release]; [base release];
  END_SET("NSScroller optional native theme hooks")
  return 0;
}
