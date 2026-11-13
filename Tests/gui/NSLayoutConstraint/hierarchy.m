#import "Testing.h"
#import <AppKit/AppKit.h>

@interface FlippedLayoutView : NSView
@end
@implementation FlippedLayoutView
- (BOOL) isFlipped { return YES; }
@end

static BOOL closeRect(NSRect a, NSRect b)
{
  return fabs(a.origin.x-b.origin.x) < .01 && fabs(a.origin.y-b.origin.y) < .01
    && fabs(a.size.width-b.size.width) < .01 && fabs(a.size.height-b.size.height) < .01;
}

int main(void)
{
  START_SET("NSLayoutConstraint hierarchy and ownership")
  [NSApplication sharedApplication];
  NSWindow *window = [[NSWindow alloc] initWithContentRect: NSMakeRect(0,0,500,400)
    styleMask: NSWindowStyleMaskBorderless backing: NSBackingStoreBuffered defer: NO];
  [window setReleasedWhenClosed: NO];
  NSView *root = [window contentView];
  NSView *panel = [[[NSView alloc] initWithFrame: NSMakeRect(70,80,300,200)] autorelease];
  NSView *child = [[[NSView alloc] initWithFrame: NSZeroRect] autorelease];
  [child setTranslatesAutoresizingMaskIntoConstraints: NO];
  [panel addSubview: child];
  NSArray *edges = [NSArray arrayWithObjects:
    [[child leftAnchor] constraintEqualToAnchor: [panel leftAnchor] constant: 20],
    [[child rightAnchor] constraintEqualToAnchor: [panel rightAnchor] constant: -30],
    [[child topAnchor] constraintEqualToAnchor: [panel topAnchor] constant: 15],
    [[child bottomAnchor] constraintEqualToAnchor: [panel bottomAnchor] constant: -10], nil];
  [NSLayoutConstraint activateConstraints: edges];
  PASS([[panel constraints] count] == 4 && [[child constraints] count] == 0,
    "detached constraints are active and owned by the common ancestor")
  [root addSubview: panel];
  NSView *unrelated = [[[NSView alloc] initWithFrame: NSMakeRect(11,12,60,40)] autorelease];
  [root addSubview: unrelated];
  [window layoutIfNeeded];
  PASS(closeRect([child frame], NSMakeRect(20,10,250,175)),
    "nested constraints use the parent's coordinates and top-down offsets")
  PASS(closeRect([unrelated frame], NSMakeRect(11,12,60,40)),
    "layout preserves unconstrained siblings")
  [[edges objectAtIndex: 0] setConstant: 35];
  [window layoutIfNeeded];
  PASS(closeRect([child frame], NSMakeRect(35,10,235,175)),
    "changing an active constant updates the solver")
  [NSLayoutConstraint deactivateConstraints: edges];
  PASS([[panel constraints] count] == 0 && ![[edges objectAtIndex: 0] isActive],
    "deactivation removes ownership")
  [NSLayoutConstraint activateConstraints: edges];
  [window layoutIfNeeded];
  PASS(closeRect([child frame], NSMakeRect(35,10,235,175)),
    "constraints can be reactivated without stale solver entries")

  FlippedLayoutView *flipped = [[[FlippedLayoutView alloc]
    initWithFrame: NSMakeRect(10,10,160,120)] autorelease];
  [panel addSubview: flipped];
  NSView *inside = [[[NSView alloc] initWithFrame: NSZeroRect] autorelease];
  [inside setTranslatesAutoresizingMaskIntoConstraints: NO];
  [flipped addSubview: inside];
  [NSLayoutConstraint activateConstraints: [NSArray arrayWithObjects:
    [[inside leftAnchor] constraintEqualToAnchor: [flipped leftAnchor] constant: 5],
    [[inside topAnchor] constraintEqualToAnchor: [flipped topAnchor] constant: 7],
    [[inside widthAnchor] constraintEqualToConstant: 40],
    [[inside heightAnchor] constraintEqualToConstant: 20], nil]];
  [window layoutIfNeeded];
  PASS(closeRect([inside frame], NSMakeRect(5,7,40,20)),
    "flipped and unflipped parents use the same visual anchor semantics")
  NSLayoutConstraint *same = [[inside widthAnchor] constraintEqualToConstant: 40];
  [same setActive: YES];
  [same setActive: NO];
  PASS([[inside constraints] count] == 2,
    "equal equations remain independent constraint objects")
  [flipped setFrameSize: NSMakeSize(180,150)];
  [window layoutIfNeeded];
  PASS(closeRect([inside frame], NSMakeRect(5,7,40,20)),
    "frame-managed containers can resize without corrupting nested layout")
  NSView *minimum = [[[NSView alloc] initWithFrame: NSMakeRect(0,0,90,30)] autorelease];
  [root addSubview: minimum];
  [[[minimum widthAnchor] constraintGreaterThanOrEqualToConstant: 100] setActive: YES];
  [window layoutIfNeeded];
  PASS(fabs([minimum frame].size.width-100) < .01,
    "required minimum sizes survive a smaller frame-managed container")
  [[[root widthAnchor] constraintGreaterThanOrEqualToConstant: 550] setActive: YES];
  [window layoutIfNeeded];
  PASS(fabs([root bounds].size.width-550) < .01,
    "a required content minimum can enlarge the window")
  NSLayoutConstraint *cross = [[inside leftAnchor]
    constraintGreaterThanOrEqualToAnchor: [root leftAnchor]];
  [cross setActive: YES];
  [panel removeFromSuperview];
  PASS(![cross isActive] && [[panel constraints] count] == 4,
    "removing a subtree deactivates ancestor constraints and preserves local ones")
  [root addSubview: panel];
  [window layoutIfNeeded];
  PASS(closeRect([child frame], NSMakeRect(35,10,235,175)),
    "a detached constrained subtree can be installed again")
  [window close];
  [window release];
  END_SET("NSLayoutConstraint hierarchy and ownership")
  return 0;
}
