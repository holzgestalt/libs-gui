#import "Testing.h"
#import <Foundation/NSAutoreleasePool.h>
#import <Foundation/NSGeometry.h>
#import <AppKit/NSApplication.h>
#import <AppKit/NSWindow.h>
#import <AppKit/NSView.h>
#import <AppKit/NSTextField.h>
#import <AppKit/NSLayoutConstraint.h>
#import <AppKit/NSLayoutAnchor.h>

/* Counts the layout passes that reach it.  It never calls super, so it stays
   marked as needing layout and every pass calls it. */
@interface PassCountingView : NSView
{
@public
  int passes;
}
@end

@implementation PassCountingView
- (void) layout
{
  passes++;
}
@end

/* Reports whatever intrinsic size it is given. */
@interface SizedView : NSView
{
@public
  NSSize size;
}
@end

@implementation SizedView
- (NSSize) intrinsicContentSize
{
  return size;
}
@end

static void
pin(NSView *view, NSView *container, CGFloat inset)
{
  [[[view leftAnchor] constraintEqualToAnchor: [container leftAnchor]
                                     constant: inset] setActive: YES];
  [[[view rightAnchor] constraintEqualToAnchor: [container rightAnchor]
                                      constant: -inset] setActive: YES];
  [[[view topAnchor] constraintEqualToAnchor: [container topAnchor]
                                    constant: inset] setActive: YES];
  [[[view bottomAnchor] constraintEqualToAnchor: [container bottomAnchor]
                                       constant: -inset] setActive: YES];
}

int
main(int argc, const char **argv)
{
  START_SET("NSWindow skips layout passes when nothing changed")

  NS_DURING
    [NSApplication sharedApplication];
  NS_HANDLER
    if ([[localException name] isEqualToString: NSInternalInconsistencyException])
      SKIP("It looks like GNUstep backend is not yet installed")
  NS_ENDHANDLER

  NS_DURING
    {
      NSWindow *w = AUTORELEASE([[NSWindow alloc]
        initWithContentRect: NSMakeRect(0, 0, 300, 200)
                  styleMask: NSWindowStyleMaskBorderless
                    backing: NSBackingStoreBuffered
                      defer: NO]);
      NSView *content = [w contentView];
      PassCountingView *counter = AUTORELEASE([[PassCountingView alloc]
        initWithFrame: NSZeroRect]);
      NSLayoutConstraint *width;
      int before;

      [counter setTranslatesAutoresizingMaskIntoConstraints: NO];
      [counter setNeedsLayout: YES];
      [content addSubview: counter];
      width = [[counter widthAnchor] constraintEqualToConstant: 50.0];
      [width setActive: YES];
      [[[counter heightAnchor] constraintEqualToConstant: 20.0] setActive: YES];
      [[[counter leftAnchor] constraintEqualToAnchor: [content leftAnchor]] setActive: YES];
      [[[counter bottomAnchor] constraintEqualToAnchor: [content bottomAnchor]] setActive: YES];

      [w layoutIfNeeded];
      before = counter->passes;
      PASS(before > 0, "the first layoutIfNeeded runs a pass");

      [w layoutIfNeeded];
      [w layoutIfNeeded];
      PASS(counter->passes == before, "layoutIfNeeded with nothing changed runs no pass");

      [width setConstant: 80.0];
      [w layoutIfNeeded];
      PASS(counter->passes > before, "a changed constant runs a pass");
      PASS(fabs(NSWidth([counter frame]) - 80.0) < 0.01, "a changed constant sets the new width");

      before = counter->passes;
      [counter setNeedsLayout: YES];
      [w layoutIfNeeded];
      PASS(counter->passes > before, "setNeedsLayout: YES runs a pass");
    }
  NS_HANDLER
    PASS(0, "unexpected exception %s", [[localException reason] UTF8String]);
  NS_ENDHANDLER

  NS_DURING
    {
      NSWindow *w = AUTORELEASE([[NSWindow alloc]
        initWithContentRect: NSMakeRect(0, 0, 300, 200)
                  styleMask: NSWindowStyleMaskBorderless
                    backing: NSBackingStoreBuffered
                      defer: NO]);
      NSView *content = [w contentView];
      NSTextField *label = AUTORELEASE([[NSTextField alloc] initWithFrame: NSZeroRect]);
      SizedView *sized = AUTORELEASE([[SizedView alloc] initWithFrame: NSZeroRect]);
      CGFloat shortWidth;

      [label setStringValue: @"a"];
      [label setTranslatesAutoresizingMaskIntoConstraints: NO];
      [content addSubview: label];
      [[[label leftAnchor] constraintEqualToAnchor: [content leftAnchor]] setActive: YES];
      [[[label bottomAnchor] constraintEqualToAnchor: [content bottomAnchor]] setActive: YES];

      sized->size = NSMakeSize(40, 30);
      [sized setTranslatesAutoresizingMaskIntoConstraints: NO];
      [content addSubview: sized];
      [[[sized rightAnchor] constraintEqualToAnchor: [content rightAnchor]] setActive: YES];
      [[[sized topAnchor] constraintEqualToAnchor: [content topAnchor]] setActive: YES];

      [w layoutIfNeeded];
      shortWidth = NSWidth([label frame]);
      [label setStringValue: @"a much longer label than before"];
      [w layoutIfNeeded];
      PASS(NSWidth([label frame]) > shortWidth + 20,
        "a new string value lays a label out at its new intrinsic width");

      PASS(fabs(NSWidth([sized frame]) - 40.0) < 0.01, "a view starts at its intrinsic width");
      sized->size = NSMakeSize(70, 30);
      [sized invalidateIntrinsicContentSize];
      [w layoutIfNeeded];
      PASS(fabs(NSWidth([sized frame]) - 70.0) < 0.01,
        "invalidateIntrinsicContentSize lays a view out at its new intrinsic width");

      [sized setHidden: YES];
      [w layoutIfNeeded];
      [sized setHidden: NO];
      [w layoutIfNeeded];
      PASS(fabs(NSWidth([sized frame]) - 70.0) < 0.01, "hiding and showing a view keeps its layout");
    }
  NS_HANDLER
    PASS(0, "unexpected exception %s", [[localException reason] UTF8String]);
  NS_ENDHANDLER

  NS_DURING
    {
      /* A constraint view inside a mask-sized view inside a constraint view:
         each level only sees the level above after a pass, as in a split
         view's panes. */
      NSWindow *w = AUTORELEASE([[NSWindow alloc]
        initWithContentRect: NSMakeRect(0, 0, 300, 200)
                  styleMask: NSWindowStyleMaskBorderless
                    backing: NSBackingStoreBuffered
                      defer: NO]);
      NSView *content = [w contentView];
      NSView *outer = AUTORELEASE([[NSView alloc] initWithFrame: NSZeroRect]);
      NSView *middle;
      NSView *inner = AUTORELEASE([[NSView alloc] initWithFrame: NSZeroRect]);
      NSRect settled;

      [outer setTranslatesAutoresizingMaskIntoConstraints: NO];
      [content addSubview: outer];
      pin(outer, content, 10);
      [w layoutIfNeeded];

      middle = AUTORELEASE([[NSView alloc] initWithFrame: [outer bounds]]);
      [middle setAutoresizingMask: NSViewWidthSizable | NSViewHeightSizable];
      [outer addSubview: middle];
      [inner setTranslatesAutoresizingMaskIntoConstraints: NO];
      [middle addSubview: inner];
      pin(inner, middle, 5);
      [w layoutIfNeeded];
      PASS(NSEqualRects([inner frame], NSMakeRect(5, 5, 270, 170)),
        "a nested constraint view is laid out inside a mask-sized view");

      [w setContentSize: NSMakeSize(400, 300)];
      [w layoutIfNeeded];
      settled = [inner frame];
      PASS(NSEqualRects(settled, NSMakeRect(5, 5, 370, 270)),
        "after a resize one layoutIfNeeded settles every nesting level");
      [w layoutIfNeeded];
      PASS(NSEqualRects([inner frame], settled), "a further layoutIfNeeded changes nothing");
    }
  NS_HANDLER
    PASS(0, "unexpected exception %s", [[localException reason] UTF8String]);
  NS_ENDHANDLER

  END_SET("NSWindow skips layout passes when nothing changed")

  return 0;
}
