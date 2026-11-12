#import "Testing.h"
#import <AppKit/AppKit.h>

@interface BackgroundProbeCell : NSButtonCell
{
@public
  BOOL backgroundKeyPresent;
  BOOL backgroundValue;
}
@end
@implementation BackgroundProbeCell
- (id) initWithCoder: (NSCoder *)coder
{
  self = [super initWithCoder: coder];
  if (self)
    {
      backgroundKeyPresent = [coder containsValueForKey: @"NSDrawsBackground"];
      backgroundValue = [coder decodeBoolForKey: @"NSDrawsBackground"];
    }
  return self;
}
@end

int main(void)
{
  START_SET("XIB text field background defaults")
  [NSApplication sharedApplication];
  NSString *xml = @"<document type='com.apple.InterfaceBuilder3.Cocoa.XIB' version='3.0' targetRuntime='MacOSX.Cocoa'><objects>"
    "<customObject id='-2' userLabel='Owner' customClass='NSApplication'/><customObject id='-1' customClass='FirstResponder'/><customObject id='-3' customClass='NSObject'/>"
    "<textField id='a'><rect key='frame' width='100' height='24'/><textFieldCell key='cell' id='ac' borderStyle='bezel' editable='YES'/></textField>"
    "<textField id='b'><rect key='frame' width='100' height='24'/><textFieldCell key='cell' id='bc' borderStyle='bezel' editable='YES' drawsBackground='NO'/></textField>"
    "<textField id='c'><rect key='frame' width='100' height='24'/><textFieldCell key='cell' id='cc' borderStyle='bezel' editable='YES' drawsBackground='YES'/></textField>"
    "<textField id='d'><rect key='frame' width='100' height='24'/><textFieldCell key='cell' id='dc' title='Label'/></textField>"
    "<buttonCell id='probe' customClass='BackgroundProbeCell' borderStyle='bezel'/>"
    "</objects></document>";
  NSNib *nib = AUTORELEASE([[NSNib alloc] initWithNibData:[xml dataUsingEncoding:NSUTF8StringEncoding] bundle:nil]);
  NSArray *objects = nil;
  BOOL loaded = [nib instantiateWithOwner:NSApp topLevelObjects:&objects];
  NSMutableArray *fields = [NSMutableArray array];
  BackgroundProbeCell *probe = nil;
  for (id object in objects)
    {
      if ([object isKindOfClass:[NSTextField class]]) [fields addObject:object];
      if ([object isKindOfClass:[BackgroundProbeCell class]]) probe = object;
    }
  PASS(probe != nil && !probe->backgroundKeyPresent && !probe->backgroundValue,
       "bezel attributes do not synthesize background defaults for other cell classes");
  objects = fields;
  PASS(loaded && [objects count] == 4, "loads the four background variants");
  if (loaded && [objects count] == 4) {
    PASS([[objects objectAtIndex:0] drawsBackground], "bezeled entry defaults to drawing its background");
    PASS(![[objects objectAtIndex:1] drawsBackground], "explicit transparency is preserved");
    PASS([[objects objectAtIndex:2] drawsBackground], "explicit background is preserved");
    PASS(![[objects objectAtIndex:3] drawsBackground], "labels remain transparent");
  }
  END_SET("XIB text field background defaults")
  return 0;
}
