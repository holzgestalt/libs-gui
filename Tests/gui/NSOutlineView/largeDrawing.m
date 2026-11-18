#import "Testing.h"
#import <AppKit/AppKit.h>

@interface LargeOutlineSource : NSObject
{
@public
  NSUInteger heightRequests;
  NSInteger count;
  CGFloat extraHeight;
  BOOL grouped;
}
@end

@implementation LargeOutlineSource
- (NSInteger) outlineView: (NSOutlineView *)view numberOfChildrenOfItem: (id)item
{
  if (item == nil) return grouped ? 1 : count;
  return [item isEqual: @"group"] ? count : 0;
}
- (id) outlineView: (NSOutlineView *)view child: (NSInteger)index ofItem: (id)item
{
  return grouped && item == nil ? (id)@"group" : [NSNumber numberWithInteger: index];
}
- (BOOL) outlineView: (NSOutlineView *)view isItemExpandable: (id)item { return [item isEqual: @"group"]; }
- (id) outlineView: (NSOutlineView *)view objectValueForTableColumn: (NSTableColumn *)column byItem: (id)item
{
  return [item description];
}
- (CGFloat) outlineView: (NSOutlineView *)view heightOfRowByItem: (id)item
{
  heightRequests++;
  return 20 + [item integerValue] % 3 + ([item integerValue] == 0 ? extraHeight : 0);
}
@end

int main(void)
{
  START_SET("NSOutlineView large drawing")
  [NSApplication sharedApplication];
  LargeOutlineSource *source = AUTORELEASE([LargeOutlineSource new]);
  source->count = 2000;
  NSWindow *window = AUTORELEASE([[NSWindow alloc] initWithContentRect: NSMakeRect(0,0,300,200)
    styleMask: NSWindowStyleMaskBorderless backing: NSBackingStoreBuffered defer: NO]);
  NSScrollView *scroll = AUTORELEASE([[NSScrollView alloc] initWithFrame: NSMakeRect(0,0,300,200)]);
  NSOutlineView *outline = AUTORELEASE([[NSOutlineView alloc] initWithFrame: NSMakeRect(0,0,300,200)]);
  NSTableColumn *column = AUTORELEASE([[NSTableColumn alloc] initWithIdentifier: @"text"]);
  [column setWidth: 280];
  [outline addTableColumn: column];
  [outline setOutlineTableColumn: column];
  [outline setHeaderView: nil];
  [outline setAutoresizesOutlineColumn: YES];
  [outline setDelegate: source];
  [outline setDataSource: source];
  [scroll setDocumentView: outline];
  [window setContentView: scroll];
  [window orderFront: nil];
  PASS([outline numberOfRows] == 2000, "all large-outline rows are loaded")
  source->heightRequests = 0;
  [outline display];
  PASS(source->heightRequests < 40000,
    "repainting the viewport does not scan every row's preceding heights")
  PASS([outline rowAtPoint: NSMakePoint(5, 42)] == 2,
    "delegate-provided variable row heights still determine row positions")
  NSRect last = [outline rectOfRow: 1999];
  source->heightRequests = 0;
  BOOL geometry = YES;
  for (NSInteger i = 0; i < 100; i++)
    {
      NSRect rect = [outline rectOfRow: 1999];
      geometry &= NSEqualRects(rect, last)
        && [outline rowAtPoint: NSMakePoint(5, NSMinY(rect))] == 1999
        && [outline rowAtPoint: NSMakePoint(5, NSMaxY(rect) - .1)] == 1999;
    }
  PASS(geometry && source->heightRequests < 1000,
    "repeated far-row geometry and hit tests reuse cached heights")
  PASS([outline rowAtPoint: NSMakePoint(5, NSMaxY(last))] == -1,
    "the exact end of the last row is outside the row data")
  source->extraHeight = 10;
  [outline noteHeightOfRowsWithIndexesChanged: [NSIndexSet indexSetWithIndex: 0]];
  NSRect changed = [outline rectOfRow: 1999];
  PASS(NSMinY(changed) == NSMinY(last) + 10
    && [outline rowAtPoint: NSMakePoint(5, 29)] == 0
    && [outline rowAtPoint: NSMakePoint(5, 30)] == 1
    && NSHeight([outline frame]) >= NSMaxY(changed),
    "height change notifications update origins, hit testing and document size")
  source->extraHeight = 5;
  [outline reloadData];
  PASS(NSMinY([outline rectOfRow: 1999]) == NSMinY(last) + 5,
    "same-count reloads invalidate cached heights")
  source->count++;
  [outline reloadData];
  PASS([outline numberOfRows] == 2001
    && NSMinY([outline rectOfRow: 2000]) == NSMaxY(last) + 5,
    "row-count changes rebuild cached row positions")
  source->grouped = YES;
  [outline reloadData];
  [outline expandItem: @"group"];
  PASS([outline numberOfRows] == 2002
    && NSMinY([outline rectOfRow: 2001]) == NSMaxY(last) + 30,
    "expansion rebuilds cached positions including the group header")
  [outline collapseItem: @"group"];
  PASS([outline numberOfRows] == 1 && NSHeight([outline rectOfRow: 0]) == 25,
    "collapse invalidates cached geometry for removed child rows")
  source->grouped = NO;
  [outline reloadData];
  LargeOutlineSource *replacement = AUTORELEASE([LargeOutlineSource new]);
  replacement->count = source->count;
  replacement->extraHeight = 2;
  [outline setDelegate: replacement];
  PASS(NSMinY([outline rectOfRow: 1999]) == NSMinY(last) + 2,
    "replacing the height delegate invalidates cached positions")
  [outline setDelegate: nil];
  [outline setRowHeight: 25];
  PASS(NSMinY([outline rectOfRow: 1999]) == 1999 * 25,
    "switching to fixed row heights uses the configured height")
  END_SET("NSOutlineView large drawing")
  return 0;
}
