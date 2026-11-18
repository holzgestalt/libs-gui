/* NSTableView columnAutoresizingStyle: with no autoresizing, columns keep
   their widths when the scroll view changes size; the last-column style
   (GNUstep's long-standing behaviour) fits the last column to the view. */
#import "Testing.h"
#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>

static NSTableView *Table(NSScrollView **scrollOut)
{
  NSScrollView *scroll = [[NSScrollView alloc] initWithFrame: NSMakeRect(0, 0, 300, 200)];
  NSTableView *table = [[NSTableView alloc] initWithFrame: [[scroll contentView] bounds]];
  NSArray *widths = [NSArray arrayWithObjects: @300, @240, @240, nil];
  NSUInteger i;

  for (i = 0; i < [widths count]; i++)
    {
      NSTableColumn *column = [[NSTableColumn alloc] initWithIdentifier:
        [NSString stringWithFormat: @"%lu", (unsigned long)i]];
      [column setWidth: [[widths objectAtIndex: i] floatValue]];
      [table addTableColumn: column];
      RELEASE(column);
    }
  [scroll setHasHorizontalScroller: YES];
  [scroll setDocumentView: table];
  RELEASE(table);
  *scrollOut = scroll;
  return table;
}

int main(int argc, const char **argv)
{
  START_SET("NSTableView columnAutoresizingStyle")
  NS_DURING
    [NSApplication sharedApplication];
  NS_HANDLER
    if ([[localException name] isEqualToString: NSInternalInconsistencyException])
      SKIP("It looks like GNUstep backend is not yet installed")
  NS_ENDHANDLER

  NSScrollView *scroll;
  NSTableView *table = Table(&scroll);

  PASS([table columnAutoresizingStyle] == NSTableViewLastColumnOnlyAutoresizingStyle,
       "the default style resizes the last column");
  [table setColumnAutoresizingStyle: NSTableViewNoColumnAutoresizing];
  PASS([table columnAutoresizingStyle] == NSTableViewNoColumnAutoresizing,
       "setColumnAutoresizingStyle: round-trips");
  [scroll setFrame: NSMakeRect(0, 0, 1200, 200)];
  [scroll setFrame: NSMakeRect(0, 0, 400, 200)];
  PASS([[[table tableColumns] objectAtIndex: 2] width] == 240.0
       && [[[table tableColumns] objectAtIndex: 0] width] == 300.0,
       "no autoresizing keeps every column's width");
  PASS(NSWidth([table frame]) >= 780.0, "the table stays as wide as its columns");
  RELEASE(scroll);

  table = Table(&scroll);
  [table setColumnAutoresizingStyle: NSTableViewLastColumnOnlyAutoresizingStyle];
  [table sizeLastColumnToFit];
  [scroll setFrame: NSMakeRect(0, 0, 1200, 200)];
  PASS([[[table tableColumns] objectAtIndex: 0] width] == 300.0
       && [[[table tableColumns] objectAtIndex: 2] width] > 240.0,
       "last-column style widens only the last column");
  RELEASE(scroll);

  table = Table(&scroll);
  [table setAutoresizesAllColumnsToFit: YES];
  PASS([table columnAutoresizingStyle] == NSTableViewUniformColumnAutoresizingStyle,
       "autoresizesAllColumnsToFit maps to the uniform style");
  [table setAutoresizesAllColumnsToFit: NO];
  PASS([table columnAutoresizingStyle] == NSTableViewLastColumnOnlyAutoresizingStyle,
       "and NO to the last-column style");
  RELEASE(scroll);

  for (NSUInteger style = NSTableViewNoColumnAutoresizing;
       style <= NSTableViewFirstColumnOnlyAutoresizingStyle; style++)
    {
      table = Table(&scroll);
      [table setColumnAutoresizingStyle: NSTableViewNoColumnAutoresizing];
      CGFloat width = NSWidth([[scroll contentView] bounds]) / 3;
      for (NSTableColumn *column in [table tableColumns]) [column setWidth: width];
      [table setColumnAutoresizingStyle: style];
      [scroll setFrameSize: NSMakeSize(NSWidth([scroll frame]) + 120, 200)];
      CGFloat expected[] = {width, width, width};
      if (style == NSTableViewUniformColumnAutoresizingStyle)
        for (NSUInteger i = 0; i < 3; i++) expected[i] += 40;
      else if (style == NSTableViewFirstColumnOnlyAutoresizingStyle
               || style == NSTableViewReverseSequentialColumnAutoresizingStyle) expected[0] += 120;
      else if (style != NSTableViewNoColumnAutoresizing) expected[2] += 120;
      BOOL correct = YES;
      for (NSUInteger i = 0; i < 3; i++)
        correct &= fabs([[[table tableColumns] objectAtIndex:i] width] - expected[i]) < .01;
      PASS(correct, "each column autoresizing style distributes growth to the correct columns");
      [scroll setFrameSize: NSMakeSize(NSWidth([scroll frame]) - 120, 200)];
      correct = YES;
      for (NSTableColumn *column in [table tableColumns]) correct &= fabs([column width] - width) < .01;
      PASS(correct, "each resizing style restores the original widths when the viewport shrinks back");
      NSTableView *decoded = [NSKeyedUnarchiver unarchiveObjectWithData:
        [NSKeyedArchiver archivedDataWithRootObject: table]];
      PASS([decoded columnAutoresizingStyle] == style, "keyed archives retain the column autoresizing style");
      decoded = [NSUnarchiver unarchiveObjectWithData:[NSArchiver archivedDataWithRootObject: table]];
      PASS([decoded columnAutoresizingStyle] == style, "unkeyed archives retain the column autoresizing style");
      RELEASE(scroll);
    }
  for (NSUInteger style = NSTableViewUniformColumnAutoresizingStyle;
       style <= NSTableViewFirstColumnOnlyAutoresizingStyle; style++)
    {
      table = Table(&scroll);
      [table setColumnAutoresizingStyle: NSTableViewNoColumnAutoresizing];
      CGFloat width = NSWidth([[scroll contentView] bounds]) / 3;
      for (NSTableColumn *column in [table tableColumns]) [column setWidth: width];
      NSUInteger limited = (style == NSTableViewSequentialColumnAutoresizingStyle
        || style == NSTableViewLastColumnOnlyAutoresizingStyle) ? 2 : 0;
      [[[table tableColumns] objectAtIndex:limited] setMaxWidth: width + 30];
      [table setColumnAutoresizingStyle: style];
      [scroll setFrameSize: NSMakeSize(NSWidth([scroll frame]) + 120, 200)];
      CGFloat expected[] = {width, width, width};
      expected[limited] += 30;
      if (style == NSTableViewUniformColumnAutoresizingStyle) { expected[1] += 45; expected[2] += 45; }
      if (style == NSTableViewSequentialColumnAutoresizingStyle
          || style == NSTableViewReverseSequentialColumnAutoresizingStyle) expected[1] += 90;
      BOOL correct = YES;
      for (NSUInteger i = 0; i < 3; i++)
        correct &= fabs([[[table tableColumns] objectAtIndex:i] width] - expected[i]) < .01;
      PASS(correct, "column bounds stop first/last-only resizing and redistribute uniform/sequential resizing");
      RELEASE(scroll);
    }

  table = Table(&scroll);
  [table setColumnAutoresizingStyle: NSTableViewNoColumnAutoresizing];
  CGFloat base = NSWidth([[scroll contentView] bounds]) / 3;
  for (NSTableColumn *column in [table tableColumns]) [column setWidth: base];
  [[[table tableColumns] objectAtIndex:1] setResizingMask:NSTableColumnUserResizingMask];
  [table setColumnAutoresizingStyle:NSTableViewUniformColumnAutoresizingStyle];
  [scroll setFrameSize:NSMakeSize(NSWidth([scroll frame]) + 120,200)];
  PASS(fabs([[[table tableColumns] objectAtIndex:0] width] - base - 60) < .01
    && fabs([[[table tableColumns] objectAtIndex:1] width] - base) < .01
    && fabs([[[table tableColumns] objectAtIndex:2] width] - base - 60) < .01,
    "user-resizable columns without the autoresizing mask retain their widths");
  RELEASE(scroll);

  END_SET("NSTableView columnAutoresizingStyle")
  return 0;
}
