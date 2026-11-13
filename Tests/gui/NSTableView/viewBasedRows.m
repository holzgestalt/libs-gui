#import "Testing.h"
#import <AppKit/AppKit.h>

@interface ViewTable : NSTableView
@end
@implementation ViewTable
- (id) initWithFrame: (NSRect)rect
{
  self = [super initWithFrame: rect];
  _viewBased = YES;
  return self;
}
@end

@interface Rows : NSObject
{
@public
  NSInteger count;
  NSInteger added;
  NSInteger removed;
}
@end
@implementation Rows
- (NSInteger) numberOfRowsInTableView: (NSTableView *)table { return count; }
- (NSTableRowView *) tableView: (NSTableView *)table rowViewForRow: (NSInteger)row
{
  return AUTORELEASE([NSTableRowView new]);
}
- (void) tableView: (NSTableView *)table didAddRowView: (NSTableRowView *)view forRow: (NSInteger)row { added++; }
- (void) tableView: (NSTableView *)table didRemoveRowView: (NSTableRowView *)view forRow: (NSInteger)row { removed++; }
- (NSView *) tableView: (NSTableView *)table viewForTableColumn: (NSTableColumn *)column row: (NSInteger)row
{
  NSTableCellView *cell = AUTORELEASE([[NSTableCellView alloc] initWithFrame: NSMakeRect(0,0,50,20)]);
  NSTextField *field = AUTORELEASE([NSTextField new]);
  [field setStringValue: [NSString stringWithFormat: @"Row %ld", (long)row]];
  [field setBordered: NO];
  [field setDrawsBackground: NO];
  [field setTranslatesAutoresizingMaskIntoConstraints: NO];
  [cell addSubview: field];
  [cell setTextField: field];
  [NSLayoutConstraint activateConstraints: [NSArray arrayWithObjects:
    [[field leadingAnchor] constraintEqualToAnchor: [cell leadingAnchor] constant: 5],
    [[field centerYAnchor] constraintEqualToAnchor: [cell centerYAnchor]], nil]];
  return cell;
}
@end

static NSColor *pixel(NSTableRowView *row)
{
  NSBitmapImageRep *bitmap = [row bitmapImageRepForCachingDisplayInRect: [row bounds]];
  [row cacheDisplayInRect: [row bounds] toBitmapImageRep: bitmap];
  return [[bitmap colorAtX: [bitmap pixelsWide] - 5 y: [bitmap pixelsHigh] / 2]
    colorUsingColorSpaceName: NSCalibratedRGBColorSpace];
}

static BOOL sameColor(NSColor *a, NSColor *b)
{
  b = [b colorUsingColorSpaceName: NSCalibratedRGBColorSpace];
  return fabs([a redComponent]-[b redComponent]) < .03
    && fabs([a greenComponent]-[b greenComponent]) < .03
    && fabs([a blueComponent]-[b blueComponent]) < .03;
}

int main(void)
{
  START_SET("NSTableView view-based rows")
  [NSApplication sharedApplication];
  Rows *source = AUTORELEASE([Rows new]);
  source->count = 4;
  NSWindow *window = AUTORELEASE([[NSWindow alloc] initWithContentRect: NSMakeRect(0,0,300,180)
    styleMask: NSWindowStyleMaskBorderless backing: NSBackingStoreBuffered defer: NO]);
  ViewTable *table = AUTORELEASE([[ViewTable alloc] initWithFrame: NSMakeRect(0,0,300,180)]);
  NSTableColumn *column = AUTORELEASE([[NSTableColumn alloc] initWithIdentifier: @"text"]);
  [column setWidth: 300];
  [table addTableColumn: column];
  [table setHeaderView: nil];
  [table setRowHeight: 30];
  [table setBackgroundColor: [NSColor whiteColor]];
  [table setDataSource: source];
  [table setDelegate: source];
  [window setContentView: table];
  [window orderFront: nil];
  [table selectRowIndexes: [NSIndexSet indexSetWithIndex: 2] byExtendingSelection: NO];
  [table display];
  BOOL geometry = YES;
  for (NSInteger row = 0; row < source->count; row++)
    {
      NSTableRowView *rv = [table rowViewAtRow: row makeIfNecessary: NO];
      NSTableCellView *cell = (id)[table viewAtColumn: 0 row: row makeIfNecessary: NO];
      NSRect field = [[cell textField] convertRect: [[cell textField] bounds] toView: table];
      NSRect expected = [table rectOfRow: row];
      geometry &= NSEqualRects([rv frame], expected) && [cell superview] == rv
        && NSMinY(field) >= NSMinY(expected) && NSMaxY(field) <= NSMaxY(expected);
      geometry &= [table rowForView: [cell textField]] == row && [rv viewAtColumn: 0] == cell;
    }
  PASS(geometry, "new cells and their constrained labels stay inside the correct row on first display")
  NSTableRowView *old = [table rowViewAtRow: 2 makeIfNecessary: NO];
  PASS([old isSelected] && !sameColor(pixel(old), [table backgroundColor]),
    "selection state reaches the row and paints a visible highlight")
  [table selectRowIndexes: [NSIndexSet indexSetWithIndex: 1] byExtendingSelection: NO];
  PASS(![old isSelected] && [[table rowViewAtRow: 1 makeIfNecessary: NO] isSelected],
    "selection changes update existing row state immediately")
  [table display];
  PASS(sameColor(pixel(old), [table backgroundColor]), "the old row highlight is cleared")
  [table setSelectionHighlightStyle: NSTableViewSelectionHighlightStyleNone];
  [table display];
  PASS(sameColor(pixel([table rowViewAtRow: 1 makeIfNecessary: NO]), [table backgroundColor]),
    "the none selection style suppresses painting without clearing selection")
  source->count++;
  [table reloadData];
  [table display];
  PASS(source->removed == 4 && source->added == 9,
    "reload removes old rows and calls row lifecycle delegates for the replacement rows")
  PASS([table rowForView: AUTORELEASE([NSView new])] == -1
    && [table viewAtColumn: 0 row: 20 makeIfNecessary: YES] == nil,
    "unrelated views and invalid rows do not resolve to row zero")
  END_SET("NSTableView view-based rows")
  return 0;
}
