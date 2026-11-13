#import "Testing.h"
#import <AppKit/AppKit.h>

int main(void)
{
  START_SET("NSLayoutConstraint split-view spacing")
  [NSApplication sharedApplication];
  NSWindow *window = [[NSWindow alloc] initWithContentRect: NSMakeRect(0,0,850,600)
    styleMask: NSWindowStyleMaskBorderless backing: NSBackingStoreBuffered defer: NO];
  [window setReleasedWhenClosed: NO];
  NSSplitView *split = [[[NSSplitView alloc] initWithFrame: NSMakeRect(0,0,850,600)] autorelease];
  [split setVertical: YES];
  NSView *sidebar = [[[NSView alloc] initWithFrame: NSMakeRect(0,0,240,600)] autorelease];
  NSView *editor = [[[NSView alloc] initWithFrame: NSMakeRect(243,0,607,600)] autorelease];
  NSView *field = [[[NSView alloc] initWithFrame: NSZeroRect] autorelease];
  [field setTranslatesAutoresizingMaskIntoConstraints: NO];
  [split addSubview: sidebar];
  [split addSubview: editor];
  [editor addSubview: field];
  [[[sidebar widthAnchor] constraintGreaterThanOrEqualToConstant: 240] setActive: YES];
  [NSLayoutConstraint activateConstraints: [NSArray arrayWithObjects:
    [[field leftAnchor] constraintEqualToAnchor: [editor leftAnchor] constant: 20],
    [[field rightAnchor] constraintEqualToAnchor: [editor rightAnchor] constant: -20],
    [[field topAnchor] constraintEqualToAnchor: [editor topAnchor] constant: 10],
    [[field heightAnchor] constraintEqualToConstant: 30], nil]];
  [window setContentView: split];
  NSString *key = @"NSSplitView Dividers ConstraintSpacingRegression";
  [[NSUserDefaults standardUserDefaults] setObject:
    [NSDictionary dictionaryWithObject: [NSNumber numberWithDouble: 0] forKey: @"0"] forKey: key];
  [split setAutosaveName: @"ConstraintSpacingRegression"];
  [split adjustSubviews];
  [window layoutIfNeeded];
  NSRect sidebarRect = [sidebar frame], editorRect = [editor frame];
  PASS(NSWidth(sidebarRect) >= 240 && NSMinX(editorRect) >= NSMaxX(sidebarRect),
    "restoring a collapsed proportion respects the sidebar minimum without overlap")
  PASS(fabs(NSMinX(editorRect)-NSMaxX(sidebarRect)-[split dividerThickness]) < 1,
    "the sidebar and editor retain the divider spacing")
  PASS(fabs(NSMaxX(editorRect)-NSWidth([split bounds])) < 1,
    "the editor fills the remaining split-view width")
  NSRect fieldRect = [field convertRect: [field bounds] toView: split];
  PASS(fabs(NSMinX(fieldRect)-NSMinX(editorRect)-20) < 1
    && fabs(NSMaxX(fieldRect)-NSMaxX(editorRect)+20) < 1,
    "editor constraints use the final pane geometry in a single layout pass")
  [split setPosition: 10 ofDividerAtIndex: 0];
  [window layoutIfNeeded];
  PASS(NSWidth([sidebar frame]) >= 240 && NSMinX([editor frame]) >= NSMaxX([sidebar frame]),
    "moving the divider below the required minimum keeps panes disjoint")
  [split setVertical: NO];
  [[[sidebar heightAnchor] constraintGreaterThanOrEqualToConstant: 100] setActive: YES];
  [split adjustSubviews];
  [window layoutIfNeeded];
  PASS(NSHeight([sidebar frame]) >= 100
    && NSMinY([editor frame]) >= NSMaxY([sidebar frame])
    && fabs(NSMaxY([editor frame])-NSHeight([split bounds])) < 1,
    "horizontal splits also reserve the required pane height and divider")
  [window setContentSize: NSMakeSize(1000,750)];
  [window layoutIfNeeded];
  PASS(NSHeight([sidebar frame]) >= 100
    && NSMinY([editor frame]) >= NSMaxY([sidebar frame]),
    "window resizing preserves the minimum size and non-overlapping panes")
  [[NSUserDefaults standardUserDefaults] removeObjectForKey: key];
  [window close];
  [window release];
  END_SET("NSLayoutConstraint split-view spacing")
  return 0;
}
