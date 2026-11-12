#import "ObjectTesting.h"
#import <AppKit/AppKit.h>
#import <Additions/GNUstepGUI/GSXibKeyedUnarchiver.h>

int main(void)
{
  START_SET("GSXib5KeyedUnarchiver control sizes")
  [NSApplication sharedApplication];
  NSArray *sizes = [NSArray arrayWithObjects: @"regular", @"small", @"mini", @"large", nil];
  NSUInteger expected[] = { NSRegularControlSize, NSSmallControlSize,
                            NSMiniControlSize, NSControlSizeLarge };
  NSUInteger i;
  for (i = 0; i < [sizes count]; i++)
    {
      NSString *xml = [NSString stringWithFormat:
        @"<document type=\"com.apple.InterfaceBuilder3.Cocoa.XIB\" version=\"3.0\" targetRuntime=\"MacOSX.Cocoa\"><objects>"
         "<button id=\"button\"><rect key=\"frame\" x=\"0\" y=\"0\" width=\"80\" height=\"30\"/>"
         "<buttonCell key=\"cell\" type=\"push\" title=\"Test\" controlSize=\"%@\" id=\"cell\"/>"
         "</button></objects></document>", [sizes objectAtIndex: i]];
      id decoder = [GSXibKeyedUnarchiver unarchiverForReadingWithData:
        [xml dataUsingEncoding: NSUTF8StringEncoding]];
      NSArray *objects = [decoder decodeObjectForKey: @"IBDocument.RootObjects"];
      NSButton *button = [objects count] ? [objects objectAtIndex: 0] : nil;
      PASS([button isKindOfClass: [NSButton class]], "button decoded")
      PASS([[button cell] controlSize] == expected[i],
        "control size %s decodes to the supported size", [[sizes objectAtIndex: i] UTF8String])
      NSData *archive = [NSKeyedArchiver archivedDataWithRootObject: [button cell]];
      NSCell *restored = [NSKeyedUnarchiver unarchiveObjectWithData: archive];
      PASS([restored controlSize] == expected[i], "keyed cell archive preserves size")
      NSCell *copied = [[button cell] copy];
      PASS([copied controlSize] == expected[i], "cell copy preserves size")
      [copied release];
    }

  NSArray *elements = [NSArray arrayWithObjects:
    @"<scroller id=\"scroller\" controlSize=\"large\" arrowsPosition=\"none\"><rect key=\"frame\" x=\"0\" y=\"0\" width=\"18\" height=\"120\"/></scroller>",
    @"<tabView id=\"tabs\" controlSize=\"large\"><rect key=\"frame\" x=\"0\" y=\"0\" width=\"200\" height=\"120\"/></tabView>", nil];
  for (NSString *element in elements)
    {
      NSString *xml = [NSString stringWithFormat:
        @"<document type=\"com.apple.InterfaceBuilder3.Cocoa.XIB\" version=\"3.0\" targetRuntime=\"MacOSX.Cocoa\"><objects>%@</objects></document>", element];
      id decoder = [GSXibKeyedUnarchiver unarchiverForReadingWithData:
        [xml dataUsingEncoding: NSUTF8StringEncoding]];
      NSArray *objects = [decoder decodeObjectForKey: @"IBDocument.RootObjects"];
      PASS([objects count] == 1, "non-cell control decoded")
      PASS([[objects objectAtIndex: 0] controlSize] == NSControlSizeLarge,
        "non-cell control preserves the large size")
    }

  NSButton *button = [[[NSButton alloc] initWithFrame: NSMakeRect(0, 0, 120, 44)] autorelease];
  [button setTitle: @"Large button"];
  [button setBordered: YES];
  [button setBezelStyle: NSRoundedBezelStyle];
  NSSize regular = [[button cell] cellSize];
  NSRect regularInterior = [[button cell] drawingRectForBounds: [button bounds]];
  NSFont *font = [button font];
  [button setControlSize: NSControlSizeLarge];
  NSSize large = [[button cell] cellSize];
  NSRect largeInterior = [[button cell] drawingRectForBounds: [button bounds]];
  PASS([button controlSize] == NSControlSizeLarge, "control forwards size to its cell")
  PASS([button font] == font, "changing control size preserves the font")
  PASS(large.width > regular.width && large.height > regular.height,
    "large buttons have larger intrinsic dimensions with the same font")
  PASS(NSWidth(largeInterior) < NSWidth(regularInterior)
       && NSHeight(largeInterior) < NSHeight(regularInterior),
    "large button drawing uses the larger content margins")
  [button sizeToFit];
  PASS(NSEqualSizes([button frame].size, large), "sizeToFit uses large button metrics")
  [button setControlSize: NSControlSizeRegular];
  PASS(NSEqualSizes([[button cell] cellSize], regular), "regular button metrics are restored")

  NSRect tightFrame = NSMakeRect(0, 0, 70, 28);
  NSRect tightRegular = [[button cell] drawingRectForBounds: tightFrame];
  [button setControlSize: NSControlSizeLarge];
  NSRect tightLarge = [[button cell] drawingRectForBounds: tightFrame];
  PASS(NSEqualRects(tightRegular, tightLarge),
    "fixed-size frames that cannot fit large margins retain their content space")

  NSTextField *field = [[[NSTextField alloc] initWithFrame: NSMakeRect(0, 0, 120, 44)] autorelease];
  [field setBezeled: YES];
  [field setStringValue: @"Large field"];
  regular = [[field cell] cellSize];
  [field setControlSize: NSControlSizeLarge];
  large = [[field cell] cellSize];
  PASS(large.width > regular.width && large.height > regular.height,
    "large text fields have larger intrinsic dimensions")

  CGFloat regularFont = [NSFont systemFontSizeForControlSize: NSControlSizeRegular];
  PASS([NSFont systemFontSizeForControlSize: NSControlSizeLarge] > regularFont,
    "large controls have a larger default system font size")
  [[NSUserDefaults standardUserDefaults] setObject: @19 forKey: @"NSLargeFontSize"];
  PASS([NSFont systemFontSizeForControlSize: NSControlSizeLarge] == 19,
    "large system font size respects NSLargeFontSize")
  [[NSUserDefaults standardUserDefaults] removeObjectForKey: @"NSLargeFontSize"];
  PASS([NSFont systemFontSizeForControlSize: 99] == regularFont,
    "invalid size values retain the standard font fallback")
  END_SET("GSXib5KeyedUnarchiver control sizes")
  return 0;
}
