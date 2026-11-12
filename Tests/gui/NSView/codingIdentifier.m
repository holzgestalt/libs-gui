#import "Testing.h"
#import <AppKit/AppKit.h>

@interface PrototypeSubclass : NSTableCellView
@end
@implementation PrototypeSubclass
@end

/* An archive from before NSView stored its identifier. */
@interface LegacyView : NSView
@end
@implementation LegacyView
- (void) encodeWithCoder: (NSCoder *)coder
{
  [coder encodeRect: [self frame] forKey: @"NSFrame"];
}
@end

int main(void)
{
  START_SET("NSView identifier coding")
  NSView *view = AUTORELEASE([[NSView alloc] initWithFrame: NSMakeRect(0,0,100,100)]);
  [view setIdentifier: @"prototype"];
  NSData *data = [NSKeyedArchiver archivedDataWithRootObject: view];
  NSView *decoded = [NSKeyedUnarchiver unarchiveObjectWithData: data];
  PASS([[decoded identifier] isEqualToString: @"prototype"], "keyed coding preserves view identifier");
  NSTableCellView *prototype = AUTORELEASE([[PrototypeSubclass alloc] initWithFrame: NSMakeRect(4,5,120,24)]);
  [prototype setIdentifier: @"List"];
  NSTableCellView *copy = AUTORELEASE([prototype copy]);
  PASS([[copy identifier] isEqualToString: @"List"] && NSEqualRects([copy frame], [prototype frame]), "prototype copies preserve their lookup identifier and geometry");
  PASS([copy isKindOfClass: [PrototypeSubclass class]], "prototype copying preserves subclasses");
  LegacyView *legacy = AUTORELEASE([[LegacyView alloc] initWithFrame: [view frame]]);
  NSView *oldDecoded = [NSKeyedUnarchiver unarchiveObjectWithData:
    [NSKeyedArchiver archivedDataWithRootObject: legacy]];
  PASS([oldDecoded identifier] == nil && NSEqualRects([oldDecoded frame], [view frame]),
       "keyed archives without identifiers retain their geometry and nil identifier");
  NSView *unkeyed = [NSUnarchiver unarchiveObjectWithData: [NSArchiver archivedDataWithRootObject: view]];
  PASS(NSEqualRects([unkeyed frame], [view frame]), "legacy unkeyed view coding remains compatible");
  END_SET("NSView identifier coding")
  return 0;
}
