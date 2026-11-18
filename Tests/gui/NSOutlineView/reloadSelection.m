/* Rebuilding the outline's root rows must not shift existing selection.
   View-based expansion/collapse reloads the root after shifting selection for
   the changed subtree; applying another shift would clear valid selection. */
#include "Testing.h"
#include <AppKit/AppKit.h>

@interface ReloadTree : NSObject
@end
@implementation ReloadTree
- (NSArray *)children:(id)item
{
  if (item == nil) return [NSArray arrayWithObjects: @"Folder", @"After", nil];
  if ([item isEqual: @"Folder"]) return [NSArray arrayWithObjects: @"Child", nil];
  return [NSArray array];
}
- (NSInteger)outlineView:(NSOutlineView *)view numberOfChildrenOfItem:(id)item
{ return [[self children:item] count]; }
- (id)outlineView:(NSOutlineView *)view child:(NSInteger)index ofItem:(id)item
{ return [[self children:item] objectAtIndex:index]; }
- (BOOL)outlineView:(NSOutlineView *)view isItemExpandable:(id)item
{ return [[self children:item] count] > 0; }
- (id)outlineView:(NSOutlineView *)view objectValueForTableColumn:(NSTableColumn *)column byItem:(id)item
{ return item; }
@end
#ifdef GNUSTEP
@interface NSTableView (ReloadPrototype)
- (void)_registerPrototypeViews:(NSArray *)views;
@end
#endif
int main(void)
{
  START_SET("NSOutlineView reload selection")
  [NSApplication sharedApplication];
  NSOutlineView *view=AUTORELEASE([[NSOutlineView alloc] initWithFrame:NSMakeRect(0,0,300,300)]);
  NSTableColumn *column=AUTORELEASE([[NSTableColumn alloc] initWithIdentifier:@"Name"]);
  [view addTableColumn:column]; [view setOutlineTableColumn:column];
  ReloadTree *data=AUTORELEASE([ReloadTree new]); [view setDataSource:data];
  [view reloadData];
  [view selectRowIndexes:[NSIndexSet indexSetWithIndex:1] byExtendingSelection:NO];
  [view reloadData];
  PASS([view selectedRow]==1 && [[view itemAtRow:1] isEqual:@"After"],
    "reloading root rows preserves a valid selected row");
#ifdef GNUSTEP
  [view _registerPrototypeViews:[NSArray array]];
#endif
  [view selectRowIndexes:[NSIndexSet indexSetWithIndex:1] byExtendingSelection:NO];
  [view expandItem:@"Folder"];
  PASS([view selectedRow]==2 && [[view itemAtRow:[view selectedRow]] isEqual:@"After"],
    "expansion shifts selection once and preserves the selected item");
  [view collapseItem:@"Folder"];
  PASS([view selectedRow]==1 && [[view itemAtRow:[view selectedRow]] isEqual:@"After"],
    "collapse shifts selection once and preserves the selected item");
  END_SET("NSOutlineView reload selection")
  return 0;
}
