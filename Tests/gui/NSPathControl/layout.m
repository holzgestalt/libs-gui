/* NSPathControl with path items: components keep the items' titles, are
   laid out by content from the left, and a click on a component reports
   that component's own NSPathControlItem. */
#import "Testing.h"
#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>

int main(int argc, const char **argv)
{
  START_SET("NSPathControl layout")
  NS_DURING
    [NSApplication sharedApplication];
  NS_HANDLER
    if ([[localException name] isEqualToString: NSInternalInconsistencyException])
      SKIP("It looks like GNUstep backend is not yet installed")
  NS_ENDHANDLER

  NSWindow *window = [[NSWindow alloc] initWithContentRect: NSMakeRect(100, 100, 400, 60)
    styleMask: NSTitledWindowMask backing: NSBackingStoreBuffered defer: NO];
  NSPathControl *pc = [[NSPathControl alloc] initWithFrame: NSMakeRect(10, 10, 380, 26)];
  NSMutableArray *items = [NSMutableArray array];
  NSArray *titles = [NSArray arrayWithObjects: @"Project", @"Sources", @"main.m", nil];
  NSUInteger i;

  [[window contentView] addSubview: pc];
  for (i = 0; i < [titles count]; i++)
    {
      NSPathControlItem *item = AUTORELEASE([[NSPathControlItem alloc] init]);
      [item setTitle: [titles objectAtIndex: i]];
      [item setURL: [NSURL URLWithString: [NSString stringWithFormat: @"x-test:///%lu", (unsigned long)i]]];
      [items addObject: item];
    }
  [pc setPathItems: items];

  NSArray *cells = [[pc cell] pathComponentCells];
  PASS([cells count] == 3, "one component cell per item");
  PASS([[[cells objectAtIndex: 0] stringValue] isEqual: @"Project"]
       && [[[cells objectAtIndex: 2] stringValue] isEqual: @"main.m"],
       "component cells keep the items' titles");

  NSRect bounds = [pc bounds];
  NSRect r0 = [[pc cell] rectOfPathComponentCell: [cells objectAtIndex: 0] withFrame: bounds inView: pc];
  NSRect r1 = [[pc cell] rectOfPathComponentCell: [cells objectAtIndex: 1] withFrame: bounds inView: pc];
  NSRect r2 = [[pc cell] rectOfPathComponentCell: [cells objectAtIndex: 2] withFrame: bounds inView: pc];
  PASS(NSMinX(r0) == NSMinX(bounds) && NSMinX(r1) == NSMaxX(r0) && NSMinX(r2) == NSMaxX(r1),
       "components follow each other from the left");
  PASS(NSWidth(r0) < NSWidth(bounds) / 3.0 && NSMaxX(r2) < NSMaxX(bounds),
       "components are as wide as their content, not a third each");
  PASS(NSWidth(r0) == [[cells objectAtIndex: 0] cellSize].width,
       "a component is its natural width when everything fits");

  [pc setFrame: NSMakeRect(10, 10, 120, 26)];
  bounds = [pc bounds];
  r2 = [[pc cell] rectOfPathComponentCell: [cells objectAtIndex: 2] withFrame: bounds inView: pc];
  PASS(NSMaxX(r2) <= NSMaxX(bounds) + 0.5, "components shrink to fit a narrow control");
  [pc setFrame: NSMakeRect(10, 10, 380, 26)];
  bounds = [pc bounds];
  r1 = [[pc cell] rectOfPathComponentCell: [cells objectAtIndex: 1] withFrame: bounds inView: pc];

  PASS([[pc cell] pathComponentCellAtPoint: NSMakePoint(NSMidX(r1), NSMidY(r1))
                                 withFrame: bounds inView: pc] == [cells objectAtIndex: 1],
       "hit testing uses the view's coordinates");
  PASS([[pc cell] pathComponentCellAtPoint: NSMakePoint(NSMaxX(bounds) - 1, NSMidY(bounds))
                                 withFrame: bounds inView: pc] == nil,
       "no component after the last one");

  /* A real click (window coordinates) on the second component. */
  NSPoint inWindow = [pc convertPoint: NSMakePoint(NSMidX(r1), NSMidY(r1)) toView: nil];
  NSEvent *down = [NSEvent mouseEventWithType: NSLeftMouseDown location: inWindow
    modifierFlags: 0 timestamp: 0 windowNumber: [window windowNumber] context: nil
    eventNumber: 0 clickCount: 1 pressure: 1.0];
  [pc mouseDown: down];
  PASS([pc clickedPathItem] == [items objectAtIndex: 1],
       "a click reports the clicked component's own item");
  PASS([[[pc clickedPathItem] title] isEqual: @"Sources"], "the clicked item keeps its title");

  RELEASE(pc);
  RELEASE(window);
  END_SET("NSPathControl layout")
  return 0;
}
