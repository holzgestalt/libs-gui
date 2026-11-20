#import <AppKit/AppKit.h>
#import "Testing.h"

@interface CompatibilityTarget : NSObject <NSMenuItemValidation>
{
@public
  BOOL enabled;
  NSUInteger validations;
  NSWindow *parent;
  NSWindow *sheet;
}
- (void) action: (id)sender;
- (void) finishSheet: (NSTimer *)timer;
@end
@implementation CompatibilityTarget
- (void) action: (id)sender {}
- (BOOL) validateMenuItem: (NSMenuItem *)item
{
  validations++;
  return enabled;
}
- (void) finishSheet: (NSTimer *)timer
{
  PASS([sheet sheetParent] == parent && [parent attachedSheet] == sheet,
       "sheetParent identifies the window presenting the sheet");
  [parent endSheet: sheet returnCode: 1234];
}
@end

int main(void)
{
  NSAutoreleasePool *pool = [NSAutoreleasePool new];
  [NSApplication sharedApplication];
  NSRect slice, remainder;
  NSDivideRect(NSMakeRect(0, 0, 100, 80), &slice, &remainder, 20, NSRectEdgeMaxY);
  PASS(NSRectEdgeMinX == NSMinXEdge && NSRectEdgeMinY == NSMinYEdge
       && NSRectEdgeMaxX == NSMaxXEdge && NSRectEdgeMaxY == NSMaxYEdge
       && NSEqualRects(slice, NSMakeRect(0, 60, 100, 20)),
       "modern rectangle edge names preserve geometry and legacy values");

  NSBindingName binding = NSValueBinding;
  NSBindingOption option = NSContinuouslyUpdatesValueBindingOption;
  PASS([binding length] > 0 && [option length] > 0,
       "binding names and options are available through AppKit");
  PASS([NSColor controlAccentColor] != nil && [NSColor separatorColor] != nil,
       "semantic colors resolve through the system catalog");
  NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
  id oldAccent = [[defaults objectForKey: @"controlAccentColor"] retain];
  id oldSeparator = [[defaults objectForKey: @"separatorColor"] retain];
  [defaults setObject: @"0.2 0.4 0.6" forKey: @"controlAccentColor"];
  [defaults setObject: @"0.6 0.4 0.2" forKey: @"separatorColor"];
  [[NSNotificationCenter defaultCenter] postNotificationName:
    NSUserDefaultsDidChangeNotification object: defaults];
  NSColor *accent = [[NSColor controlAccentColor] colorUsingColorSpaceName: NSCalibratedRGBColorSpace];
  NSColor *separator = [[NSColor separatorColor] colorUsingColorSpaceName: NSCalibratedRGBColorSpace];
  PASS(fabs([accent redComponent] - 0.2) < 0.001
       && fabs([separator redComponent] - 0.6) < 0.001,
       "semantic colors honor system-color changes rather than hard-coded accessors");
  if (oldAccent) [defaults setObject: oldAccent forKey: @"controlAccentColor"];
  else [defaults removeObjectForKey: @"controlAccentColor"];
  if (oldSeparator) [defaults setObject: oldSeparator forKey: @"separatorColor"];
  else [defaults removeObjectForKey: @"separatorColor"];
  [oldAccent release]; [oldSeparator release];

  CompatibilityTarget *target = [CompatibilityTarget new];
  NSMenu *menu = [[NSMenu alloc] initWithTitle: @"Validation"];
  NSMenuItem *item = (NSMenuItem *)[menu addItemWithTitle: @"Action" action: @selector(action:) keyEquivalent: @""];
  [item setTarget: target];
  target->enabled = NO; [menu update];
  PASS(![item isEnabled] && target->validations > 0,
       "modern menu validation disables an item through NSMenu update");
  target->enabled = YES; [menu update];
  PASS([item isEnabled], "modern menu validation re-enables an item");

  NSAlert *alert = [NSAlert new];
  PASS(![alert showsSuppressionButton] && [alert suppressionButton] == nil,
       "alerts do not display a suppression checkbox by default");
  [alert setMessageText: @"File changed"];
  [alert setInformativeText: @"Reload the contents from disk?"];
  [alert addButtonWithTitle: @"Reload"];
  [alert setShowsSuppressionButton: YES];
  NSButton *checkbox = [alert suppressionButton];
  [checkbox setTitle: @"Do not ask about changes again"];
  NSWindow *panel = [alert window];
  PASS([checkbox superview] == [panel contentView] && [checkbox state] == NSOffState,
       "the suppression checkbox is a live control in the alert window");
  [checkbox performClick: nil];
  PASS([checkbox state] == NSOnState,
       "clicking suppression changes its state without dismissing the alert");
  [alert setShowsSuppressionButton: NO];
  PASS([checkbox superview] == nil, "suppression can be removed from an existing alert");
  [alert setShowsSuppressionButton: YES];
  PASS([alert suppressionButton] == checkbox && [checkbox state] == NSOnState
       && [[checkbox title] isEqual: @"Do not ask about changes again"],
       "suppression retains identity, title and state when shown again");
  NSRect boxFrame = [checkbox frame];
  NSRect buttonFrame = [[[alert buttons] objectAtIndex: 0] frame];
  PASS(!NSIntersectsRect(boxFrame, buttonFrame)
       && NSContainsRect([[panel contentView] bounds], boxFrame),
       "suppression fits inside the panel without overlapping response buttons");
  [alert release];

  target->parent = [[NSWindow alloc] initWithContentRect: NSMakeRect(0, 0, 300, 200)
    styleMask: NSTitledWindowMask backing: NSBackingStoreBuffered defer: NO];
  target->sheet = [[NSWindow alloc] initWithContentRect: NSMakeRect(0, 0, 200, 100)
    styleMask: NSTitledWindowMask backing: NSBackingStoreBuffered defer: NO];
  NSFont *regular = [NSFont monospacedSystemFontOfSize: 13 weight: NSFontWeightRegular];
  NSFont *bold = [NSFont monospacedSystemFontOfSize: 18 weight: NSFontWeightBold];
  PASS([regular isFixedPitch] && fabs([regular pointSize] - 13) < 0.01
       && [bold isFixedPitch] && fabs([bold pointSize] - 18) < 0.01,
       "monospaced system fonts preserve fixed pitch and requested size");
  PASS([[NSFontManager sharedFontManager] weightOfFont: bold]
       >= [[NSFontManager sharedFontManager] weightOfFont: regular],
       "requesting a bold monospaced font does not select a lighter face");

  NSAppearance *appearance = [NSAppearance appearanceNamed: NSAppearanceNameDarkAqua];
  [target->parent setAppearance: appearance];
  PASS([target->parent appearance] == appearance,
       "window appearances are retained without requiring NSCopying");
  NSView *child = [[[NSView alloc] initWithFrame: NSMakeRect(0,0,10,10)] autorelease];
  [[target->parent contentView] addSubview: child];
  PASS([child effectiveAppearance] == appearance,
       "views inherit the appearance of their containing window");
  [child setAppearance: [NSAppearance appearanceNamed: NSAppearanceNameAqua]];
  PASS([child effectiveAppearance] == [child appearance],
       "an explicit view appearance overrides the window appearance");
  [child setAppearance: nil]; [target->parent setAppearance: nil];
  [NSApp setAppearance: appearance];
  PASS([child effectiveAppearance] == appearance,
       "an unset window appearance inherits the application appearance");
  [NSApp setAppearance: nil];

  NSSplitViewController *split = [NSSplitViewController new];
  NSViewController *pane = [NSViewController new];
  [pane setView: [[[NSView alloc] initWithFrame: NSMakeRect(0,0,100,100)] autorelease]];
  NSSplitViewItem *splitItem = [NSSplitViewItem sidebarWithViewController: pane];
  [split addSplitViewItem: splitItem];
  [splitItem setCanCollapse: NO];
  PASS(![split splitView: [split splitView] canCollapseSubview: [pane view]],
       "split controllers honor an item's disabled collapsing policy");
  [splitItem setCanCollapse: YES];
  PASS([split splitView: [split splitView] canCollapseSubview: [pane view]],
       "split controllers honor an item's enabled collapsing policy");
  [pane release]; [split release];

  [target->parent setReleasedWhenClosed: NO];
  [target->sheet setReleasedWhenClosed: NO];
  NSTimer *timer = [NSTimer timerWithTimeInterval: 0.1 target: target
    selector: @selector(finishSheet:) userInfo: nil repeats: NO];
  [[NSRunLoop currentRunLoop] addTimer: timer forMode: NSModalPanelRunLoopMode];
  __block NSInteger response = 0;
  [target->parent beginSheet: target->sheet completionHandler: ^(NSModalResponse result) {
    response = result;
  }];
  PASS(response == 1234, "window endSheet forwards the requested response code");
  PASS([target->sheet sheetParent] == nil && [target->parent attachedSheet] == nil,
       "ending a sheet clears both parent and sheet associations");
  [target->parent close];
  [target->sheet release]; [target->parent release];
  [menu release]; [target release]; [pool drain];
  return 0;
}
