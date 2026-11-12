#import "Testing.h"
#import <AppKit/AppKit.h>
#import <GNUstepGUI/GSXibKeyedUnarchiver.h>

static NSToolbar *toolbar(NSString *attributes)
{
  NSString *xml = [NSString stringWithFormat:
    @"<document type='com.apple.InterfaceBuilder3.Cocoa.XIB' version='3.0' targetRuntime='MacOSX.Cocoa'><objects><toolbar id='toolbar' implicitIdentifier='ModeTest' %@/></objects></document>", attributes];
  NSKeyedUnarchiver *coder = [GSXibKeyedUnarchiver unarchiverForReadingWithData:
    [xml dataUsingEncoding:NSUTF8StringEncoding]];
  NSArray *objects = [coder decodeObjectForKey:@"IBDocument.RootObjects"];
  return [objects count] ? [objects objectAtIndex:0] : nil;
}

int main(void)
{
  START_SET("XIB toolbar display and size modes")
  [NSApplication sharedApplication];
  NSToolbar *icons = toolbar(@"displayMode='iconOnly' sizeMode='regular'");
  PASS([icons isKindOfClass:[NSToolbar class]], "decodes a toolbar");
  PASS([icons displayMode] == NSToolbarDisplayModeIconOnly, "icon-only XIB hides item labels");
  PASS([icons sizeMode] == NSToolbarSizeModeRegular, "regular XIB size is preserved");
  NSToolbar *labels = toolbar(@"displayMode='labelOnly' sizeMode='small'");
  PASS([labels displayMode] == NSToolbarDisplayModeLabelOnly, "label-only XIB preserves its mode");
  PASS([labels sizeMode] == NSToolbarSizeModeSmall, "small XIB size is preserved");
  PASS([toolbar(@"displayMode='iconAndLabel'") displayMode] == NSToolbarDisplayModeIconAndLabel,
       "icon-and-label XIB preserves its mode");
  NSToolbar *defaults = toolbar(@"");
  PASS([defaults displayMode] == NSToolbarDisplayModeDefault, "omitted display mode retains the default");
  PASS([defaults sizeMode] == NSToolbarSizeModeDefault, "omitted size mode retains the default");
  NSToolbar *numeric = toolbar(@"displayMode='2' sizeMode='2'");
  PASS([numeric displayMode] == NSToolbarDisplayModeIconOnly, "numeric display modes remain compatible");
  PASS([numeric sizeMode] == NSToolbarSizeModeSmall, "numeric size modes remain compatible");
  NSToolbar *unknown = toolbar(@"displayMode='futureMode' sizeMode='futureSize'");
  PASS([unknown displayMode] == NSToolbarDisplayModeDefault && [unknown sizeMode] == NSToolbarSizeModeDefault,
       "unknown modes retain defaults");
  NSToolbar *decoded = [NSKeyedUnarchiver unarchiveObjectWithData:
    [NSKeyedArchiver archivedDataWithRootObject: numeric]];
  PASS([decoded displayMode] == NSToolbarDisplayModeIconOnly && [decoded sizeMode] == NSToolbarSizeModeSmall,
       "keyed toolbar archives preserve numeric modes");
  END_SET("XIB toolbar display and size modes")
  return 0;
}
