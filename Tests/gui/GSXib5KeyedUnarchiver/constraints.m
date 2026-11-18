#import "Testing.h"
#import <AppKit/AppKit.h>
#import <Additions/GNUstepGUI/GSXibKeyedUnarchiver.h>

int main(void)
{
  START_SET("GSXib5KeyedUnarchiver constraints")
  [NSApplication sharedApplication];
  NSString *xml = @"<document type=\"com.apple.InterfaceBuilder3.Cocoa.XIB\" version=\"3.0\" targetRuntime=\"MacOSX.Cocoa\"><objects>"
    "<customView id=\"root\"><rect key=\"frame\" x=\"0\" y=\"0\" width=\"300\" height=\"200\"/>"
    "<subviews><customView id=\"child\" translatesAutoresizingMaskIntoConstraints=\"NO\">"
    "<rect key=\"frame\" x=\"0\" y=\"0\" width=\"10\" height=\"10\"/>"
    "<constraints><constraint firstAttribute=\"height\" constant=\"30\" id=\"height\"/>"
    "<constraint firstAttribute=\"height\" constant=\"999\" placeholder=\"YES\" id=\"placeholder\"/></constraints>"
    "</customView></subviews><constraints>"
    "<constraint firstItem=\"child\" firstAttribute=\"leading\" secondItem=\"root\" secondAttribute=\"leading\" constant=\"20\" id=\"left\"/>"
    "<constraint firstItem=\"child\" firstAttribute=\"top\" secondItem=\"root\" secondAttribute=\"top\" constant=\"15\" id=\"top\"/>"
    "<constraint firstItem=\"child\" firstAttribute=\"width\" secondItem=\"root\" secondAttribute=\"width\" multiplier=\"1:2\" id=\"width\"/>"
    "</constraints></customView></objects></document>";
  id decoder = [GSXibKeyedUnarchiver unarchiverForReadingWithData:
    [xml dataUsingEncoding: NSUTF8StringEncoding]];
  NSView *root = [[decoder decodeObjectForKey: @"IBDocument.RootObjects"] objectAtIndex: 0];
  NSView *child = [[root subviews] objectAtIndex: 0];
  PASS([root translatesAutoresizingMaskIntoConstraints]
    && ![child translatesAutoresizingMaskIntoConstraints], "custom views decode translation flags")
  PASS([[root constraints] count] == 3 && [[child constraints] count] == 1,
    "custom views decode their constraints and exclude placeholders")
  NSLayoutConstraint *height = [[child constraints] objectAtIndex: 0];
  PASS([height firstItem] == child && [height isActive],
    "omitted firstItem references the containing view")
  NSWindow *window = [[NSWindow alloc] initWithContentRect: NSMakeRect(0,0,300,200)
    styleMask: NSWindowStyleMaskBorderless backing: NSBackingStoreBuffered defer: NO];
  [window setReleasedWhenClosed: NO];
  [window setContentView: root];
  [window layoutIfNeeded];
  NSRect frame = [child frame];
  PASS(fabs(frame.origin.x-20)<.01 && fabs(frame.origin.y-155)<.01
    && fabs(frame.size.width-150)<.01 && fabs(frame.size.height-30)<.01,
    "XIB anchors and ratio multipliers determine the actual frame")
  [window setContentSize: NSMakeSize(400,260)];
  [window layoutIfNeeded];
  frame = [child frame];
  PASS(fabs(frame.origin.y-215)<.01 && fabs(frame.size.width-200)<.01,
    "decoded constraints reflow on window resize")
  [window close];
  [window release];
  NSString *segments = @"<document type=\"com.apple.InterfaceBuilder3.Cocoa.XIB\" version=\"3.0\" targetRuntime=\"MacOSX.Cocoa\"><objects>"
    "<segmentedControl id=\"control\"><rect key=\"frame\" x=\"0\" y=\"0\" width=\"80\" height=\"24\"/>"
    "<segmentedCell key=\"cell\" id=\"cell\"><segments><segment image=\"NSAddTemplate\" width=\"24\"/>"
    "<segment label=\"Text\" width=\"40\"/></segments></segmentedCell></segmentedControl></objects></document>";
  decoder = [GSXibKeyedUnarchiver unarchiverForReadingWithData:
    [segments dataUsingEncoding: NSUTF8StringEncoding]];
  NSSegmentedControl *control = [[decoder decodeObjectForKey: @"IBDocument.RootObjects"] objectAtIndex: 0];
  PASS([[control imageForSegment: 0] isKindOfClass: [NSImage class]]
    && [control imageForSegment: 1] == nil, "segment resources decode as images rather than name strings")
  PASS([control intrinsicContentSize].width > 0, "image segments can be measured for toolbar and constraint layout")
  END_SET("GSXib5KeyedUnarchiver constraints")
  return 0;
}
