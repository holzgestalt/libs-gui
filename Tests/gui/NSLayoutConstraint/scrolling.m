#import "Testing.h"
#import <AppKit/AppKit.h>

@interface FlippedScrollDocument : NSView
@end
@implementation FlippedScrollDocument
- (BOOL) isFlipped { return YES; }
@end

static BOOL closeRect(NSRect a, NSRect b)
{
  return fabs(a.origin.x-b.origin.x) < .01 && fabs(a.origin.y-b.origin.y) < .01
    && fabs(a.size.width-b.size.width) < .01 && fabs(a.size.height-b.size.height) < .01;
}

int main(void)
{
  START_SET("Auto Layout in scrolling documents")
  [NSApplication sharedApplication];
  for (NSInteger variant = 0; variant < 4; variant++)
    {
      BOOL flipped = variant % 2;
      BOOL constrained = variant >= 2;
      NSWindow *window = AUTORELEASE([[NSWindow alloc] initWithContentRect: NSMakeRect(0,0,320,240)
        styleMask: NSWindowStyleMaskBorderless backing: NSBackingStoreBuffered defer: NO]);
      NSScrollView *scroll = AUTORELEASE([[NSScrollView alloc] initWithFrame: NSMakeRect(0,0,320,240)]);
      Class cls = flipped ? [FlippedScrollDocument class] : [NSView class];
      NSView *document = AUTORELEASE([[cls alloc] initWithFrame: NSMakeRect(0,0,600,1200)]);
      [document setTranslatesAutoresizingMaskIntoConstraints: !constrained];
      NSView *row = AUTORELEASE([[cls alloc] initWithFrame: NSMakeRect(10,400,500,30)]);
      NSView *label = AUTORELEASE([[NSView alloc] initWithFrame: NSZeroRect]);
      [label setTranslatesAutoresizingMaskIntoConstraints: NO];
      [row addSubview: label];
      [document addSubview: row];
      [scroll setDocumentView: document];
      [window setContentView: scroll];
      [NSLayoutConstraint activateConstraints: [NSArray arrayWithObjects:
        [[label leftAnchor] constraintEqualToAnchor: [row leftAnchor] constant: 5],
        [[label topAnchor] constraintEqualToAnchor: [row topAnchor] constant: 3],
        [[label widthAnchor] constraintEqualToConstant: 90],
        [[label heightAnchor] constraintEqualToConstant: 20], nil]];
      if (constrained)
        {
          NSClipView *clip = [scroll contentView];
          NSLayoutConstraint *vertical = flipped
            ? [[document topAnchor] constraintEqualToAnchor: [clip topAnchor]]
            : [[document bottomAnchor] constraintEqualToAnchor: [clip bottomAnchor]];
          [NSLayoutConstraint activateConstraints: [NSArray arrayWithObjects:
            [[document leftAnchor] constraintEqualToAnchor: [clip leftAnchor]], vertical,
            [[document widthAnchor] constraintEqualToConstant: 600],
            [[document heightAnchor] constraintEqualToConstant: 1200], nil]];
        }
      [window layoutIfNeeded];
      NSRect expected = NSMakeRect(5, flipped ? 3 : 7, 90, 20);
      PASS(closeRect([label frame], expected), "row labels use their parent's local coordinates")
      id engine = [window valueForKey: @"_layoutEngine"];
      NSDictionary *before = [[engine valueForKey: @"_frameConstraintsByView"] objectForKey: row];
      [[scroll contentView] scrollToPoint: NSMakePoint(20,200)];
      [window layoutIfNeeded];
      NSDictionary *after = [[engine valueForKey: @"_frameConstraintsByView"] objectForKey: row];
      PASS(closeRect([label frame], expected)
        && closeRect([row frame], NSMakeRect(10,400,500,30)) && before == after,
        "scrolling preserves row layout without replacing its frame constraints")

      NSRect frame = [document frame];
      [[scroll contentView] scrollToPoint: NSMakePoint(30,300)];
      [window layoutIfNeeded];
      PASS(closeRect([document frame], frame) && closeRect([label frame], expected),
        "a constrained document also retains its frame while scrolling")
      NSUInteger tracked = [[engine valueForKey: @"_trackedViews"] count];
      [row removeFromSuperview];
      PASS([[engine valueForKey: @"_trackedViews"] count] + 2 == tracked,
        "detached row and label leave the layout engine's tracked views")
      [document addSubview: row];
      [window layoutIfNeeded];
      PASS(closeRect([label frame], expected), "detached row constraints reinstall correctly on reattachment")
    }
  END_SET("Auto Layout in scrolling documents")
  return 0;
}
