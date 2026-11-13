#import "Testing.h"
#import <AppKit/AppKit.h>

int main(void)
{
  START_SET("NSLayoutConstraint adjacent hugging priorities")
  [NSApplication sharedApplication];
  NSWindow *window = AUTORELEASE([[NSWindow alloc] initWithContentRect: NSMakeRect(0,0,300,100)
    styleMask: NSWindowStyleMaskBorderless backing: NSBackingStoreBuffered defer: NO]);
  NSView *container = AUTORELEASE([[NSView alloc] initWithFrame: NSMakeRect(10,10,220,30)]);
  [[window contentView] addSubview: container];
  NSTextField *code = AUTORELEASE([NSTextField new]);
  NSTextField *name = AUTORELEASE([NSTextField new]);
  [code setStringValue: @"0041"];
  [name setStringValue: @"A"];
  [code setTranslatesAutoresizingMaskIntoConstraints: NO];
  [name setTranslatesAutoresizingMaskIntoConstraints: NO];
  [code setContentHuggingPriority: 251 forOrientation: NSLayoutConstraintOrientationHorizontal];
  [name setContentHuggingPriority: 250 forOrientation: NSLayoutConstraintOrientationHorizontal];
  [container addSubview: code];
  [container addSubview: name];
  [NSLayoutConstraint activateConstraints: [NSArray arrayWithObjects:
    [[code leadingAnchor] constraintEqualToAnchor: [container leadingAnchor] constant: 2],
    [[code widthAnchor] constraintGreaterThanOrEqualToConstant: 60],
    [[name leadingAnchor] constraintEqualToAnchor: [code trailingAnchor] constant: 8],
    [[name trailingAnchor] constraintEqualToAnchor: [container trailingAnchor]],
    [[code centerYAnchor] constraintEqualToAnchor: [container centerYAnchor]],
    [[name centerYAnchor] constraintEqualToAnchor: [container centerYAnchor]], nil]];
  [window layoutIfNeeded];
  PASS(fabs(NSWidth([code frame])-60) < .01 && fabs(NSMinX([name frame])-70) < .01,
    "the 251 hugging priority keeps the code narrow beside an expanding 250 label")
  [name setStringValue: @"Amacron.alt"];
  [container setFrameSize: NSMakeSize(280,30)];
  [window layoutIfNeeded];
  PASS(fabs(NSWidth([code frame])-60) < .01 && fabs(NSMinX([name frame])-70) < .01,
    "text and container changes preserve the column boundary")
  NSTextField *detail = AUTORELEASE([NSTextField new]);
  [detail setStringValue: @"0041"];
  [detail setTranslatesAutoresizingMaskIntoConstraints: NO];
  [detail setContentHuggingPriority: 250 forOrientation: NSLayoutConstraintOrientationHorizontal];
  [container addSubview: detail];
  [NSLayoutConstraint activateConstraints: [NSArray arrayWithObjects:
    [[detail leadingAnchor] constraintEqualToAnchor: [name leadingAnchor]],
    [[detail trailingAnchor] constraintEqualToAnchor: [name trailingAnchor]], nil]];
  [window layoutIfNeeded];
  PASS(fabs(NSWidth([code frame])-60) < .01 && fabs(NSMinX([name frame])-70) < .01,
    "two priority-250 labels cannot outweigh the priority-251 column")
  [code setContentHuggingPriority: 249 forOrientation: NSLayoutConstraintOrientationHorizontal];
  [window layoutIfNeeded];
  PASS(NSWidth([code frame]) > 100,
    "changing the priority moves expansion to the now lower-priority column")
  [code setContentHuggingPriority: 251 forOrientation: NSLayoutConstraintOrientationHorizontal];
  [window layoutIfNeeded];
  PASS(fabs(NSWidth([code frame])-60) < .01,
    "restoring the priority removes the old objective contribution")
  END_SET("NSLayoutConstraint adjacent hugging priorities")
  return 0;
}
