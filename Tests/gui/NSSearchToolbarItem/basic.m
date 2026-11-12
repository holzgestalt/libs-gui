#import "Testing.h"
#import <AppKit/AppKit.h>

@interface SearchTarget : NSObject
{
  id _sender;
}
- (void) search: (id)sender;
- (id) sender;
@end
@implementation SearchTarget
- (void) search: (id)sender { _sender = sender; }
- (id) sender { return _sender; }
@end

int main(void)
{
  START_SET("NSSearchToolbarItem")
  [NSApplication sharedApplication];
  NSSearchToolbarItem *item = AUTORELEASE([[NSSearchToolbarItem alloc] initWithItemIdentifier: @"search"]);
  SearchTarget *target = AUTORELEASE([SearchTarget new]);
  PASS([[item searchField] isKindOfClass: [NSSearchField class]], "creates a search field");
  [item setTarget: target];
  [item setAction: @selector(search:)];
  [item setEnabled: NO];
  NSSearchField *replacement = AUTORELEASE([[NSSearchField alloc] initWithFrame: NSMakeRect(0,0,180,24)]);
  [item setSearchField: replacement];
  PASS([item view] == replacement, "replacement is installed as the toolbar view");
  PASS([replacement target] == target && [replacement action] == @selector(search:), "replacement inherits target and action");
  PASS(![replacement isEnabled], "replacement preserves disabled state");
  [item setEnabled: YES];
  [replacement sendAction: [replacement action] to: [replacement target]];
  PASS([target sender] == replacement, "search dispatches the field as sender");
  NSWindow *window = AUTORELEASE([[NSWindow alloc] initWithContentRect: NSMakeRect(0,0,300,100)
    styleMask: NSTitledWindowMask backing: NSBackingStoreBuffered defer: NO]);
  [window setReleasedWhenClosed: NO];
  [[window contentView] addSubview: replacement];
  [window makeKeyAndOrderFront: nil];
  [item beginSearchInteraction];
  PASS([replacement currentEditor] != nil, "beginning interaction focuses the editor");
  [item endSearchInteraction];
  PASS([replacement currentEditor] == nil, "ending interaction resigns the editor");
  NSTextField *other = AUTORELEASE([[NSTextField alloc] initWithFrame: NSMakeRect(0,40,100,24)]);
  [[window contentView] addSubview: other];
  [window makeFirstResponder: other];
  id responder = [window firstResponder];
  [item endSearchInteraction];
  PASS([window firstResponder] == responder, "ending search preserves another control's focus");
  [window makeFirstResponder: nil];
  [item setTarget: nil];
  [replacement removeFromSuperview];
  NSData *data = [NSKeyedArchiver archivedDataWithRootObject: item];
  NSSearchToolbarItem *decoded = [NSKeyedUnarchiver unarchiveObjectWithData: data];
  PASS([[decoded searchField] isKindOfClass: [NSSearchField class]], "coding preserves the search field");
  [replacement setStringValue: @"find me"];
  NSSearchToolbarItem *copy = AUTORELEASE([item copy]);
  PASS([copy isKindOfClass: [NSSearchToolbarItem class]] && [copy searchField] != replacement
       && [[[copy searchField] stringValue] isEqualToString: @"find me"],
       "copying preserves the class and independently copies the search field");
  END_SET("NSSearchToolbarItem")
  return 0;
}
