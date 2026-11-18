#import <AppKit/AppKit.h>
#import <GNUstepGUI/GSTheme.h>
#include <assert.h>

@interface PreviewView : NSView
@end
@implementation PreviewView
- (BOOL)isFlipped { return YES; }
- (void)drawRect:(NSRect)r { [[NSColor windowBackgroundColor] set]; NSRectFill(r); }
@end
@interface PreviewData : NSObject <NSTableViewDataSource>
@end
@implementation PreviewData
- (NSInteger)numberOfRowsInTableView:(NSTableView *)v { return 6; }
- (id)tableView:(NSTableView *)v objectValueForTableColumn:(NSTableColumn *)c row:(NSInteger)row
{
  NSArray *names=@[@"Desktop",@"Documents",@"Downloads",@"Pictures",@"Music",@"Movies"];
  return [[c identifier] isEqual:@"name"] ? names[row] : @[@"2 items",@"18 items",@"7 items",@"24 items",@"12 items",@"3 items"][row];
}
@end
static NSTextField *label(NSView *parent, NSString *text, NSRect r, CGFloat size, BOOL bold)
{
  NSTextField *field=[[[NSTextField alloc] initWithFrame:r] autorelease];
  [field setStringValue:text]; [field setBezeled:NO]; [field setDrawsBackground:NO];
  [field setEditable:NO]; [field setSelectable:NO];
  [field setFont:bold ? [NSFont boldSystemFontOfSize:size] : [NSFont systemFontOfSize:size]];
  [parent addSubview:field]; return field;
}
static NSButton *button(NSView *parent, NSString *title, NSRect r)
{
  NSButton *b=[[[NSButton alloc] initWithFrame:r] autorelease]; [b setTitle:title];
  [b setBezelStyle:NSRoundedBezelStyle]; [b setFont:[NSFont systemFontOfSize:13]];
  [parent addSubview:b]; return b;
}
static NSData *capture(NSView *v)
{
  NSBitmapImageRep *rep=[v bitmapImageRepForCachingDisplayInRect:[v bounds]];
  [v cacheDisplayInRect:[v bounds] toBitmapImageRep:rep];
  return [rep representationUsingType:NSPNGFileType properties:@{}];
}
int main(int argc, char **argv)
{
  NSAutoreleasePool *pool=[NSAutoreleasePool new]; [NSApplication sharedApplication];
  assert([[[GSTheme theme] name] isEqual:@"Default"]);
  NSWindow *window=[[NSWindow alloc] initWithContentRect:NSMakeRect(0,0,900,840)
    styleMask:NSTitledWindowMask|NSClosableWindowMask backing:NSBackingStoreBuffered defer:NO];
  [window setTitle:@"Default — GNUstep control gallery"];
  PreviewView *view=[[[PreviewView alloc] initWithFrame:NSMakeRect(0,0,900,840)] autorelease];
  [window setContentView:view];
  label(view,@"Default",NSMakeRect(32,24,500,38),28,YES);
  label(view,@"A simplified, opaque appearance for GNUstep",NSMakeRect(34,66,700,24),14,NO);
  label(view,@"BUTTONS & SELECTION",NSMakeRect(34,118,400,20),11,YES);
  NSButton *normal=button(view,@"Cancel",NSMakeRect(32,148,110,32));
  NSButton *primary=button(view,@"Continue",NSMakeRect(152,148,120,32));
  [primary setKeyEquivalent:@"\r"];
  NSButton *disabled=button(view,@"Unavailable",NSMakeRect(282,148,130,32)); [disabled setEnabled:NO];
  NSButton *check=button(view,@"Keep organized",NSMakeRect(34,194,180,26));
  [check setButtonType:NSSwitchButton]; [check setState:NSOnState];
  NSButton *radio=button(view,@"Selected option",NSMakeRect(224,194,190,26));
  [radio setButtonType:NSRadioButton]; [radio setState:NSOnState];
  NSSegmentedControl *segments=[[[NSSegmentedControl alloc] initWithFrame:NSMakeRect(32,238,380,30)] autorelease];
  [segments setSegmentCount:3]; [segments setLabel:@"All files" forSegment:0];
  [segments setLabel:@"Recent" forSegment:1]; [segments setLabel:@"Shared" forSegment:2];
  for (int i=0;i<3;i++) [segments setWidth:126 forSegment:i];
  [segments setSelectedSegment:0]; [view addSubview:segments];
  label(view,@"INPUT & FEEDBACK",NSMakeRect(34,302,400,20),11,YES);
  NSTextField *entry=[[[NSTextField alloc] initWithFrame:NSMakeRect(32,332,380,32)] autorelease];
  [entry setStringValue:@"Project name"]; [entry setFont:[NSFont systemFontOfSize:13]]; [view addSubview:entry];
  NSSlider *slider=[[[NSSlider alloc] initWithFrame:NSMakeRect(32,390,290,24)] autorelease];
  [slider setDoubleValue:0.62]; [view addSubview:slider];
  NSStepper *stepper=[[[NSStepper alloc] initWithFrame:NSMakeRect(346,384,24,34)] autorelease]; [view addSubview:stepper];
  NSPopUpButton *popup=[[[NSPopUpButton alloc] initWithFrame:NSMakeRect(32,440,220,32) pullsDown:NO] autorelease];
  [popup addItemsWithTitles:@[@"Automatic",@"Light",@"Dark"]]; [view addSubview:popup];
  NSProgressIndicator *progress=[[[NSProgressIndicator alloc] initWithFrame:NSMakeRect(32,504,380,16)] autorelease];
  [progress setIndeterminate:NO]; [progress setMinValue:0]; [progress setMaxValue:100]; [progress setDoubleValue:64]; [view addSubview:progress];
  NSProgressIndicator *spinner=[[[NSProgressIndicator alloc] initWithFrame:NSMakeRect(380,442,24,24)] autorelease];
  [spinner setStyle:NSProgressIndicatorSpinningStyle]; [spinner setIndeterminate:YES]; [view addSubview:spinner];
  label(view,@"FILES",NSMakeRect(466,118,300,20),11,YES);
  NSScrollView *scroll=[[[NSScrollView alloc] initWithFrame:NSMakeRect(464,148,400,248)] autorelease];
  NSTableView *table=[[[NSTableView alloc] initWithFrame:NSMakeRect(0,0,384,220)] autorelease];
  NSTableColumn *name=[[[NSTableColumn alloc] initWithIdentifier:@"name"] autorelease];
  [[name headerCell] setStringValue:@"Name"]; [name setWidth:245]; [table addTableColumn:name];
  NSTableColumn *count=[[[NSTableColumn alloc] initWithIdentifier:@"count"] autorelease];
  [[count headerCell] setStringValue:@"Contents"]; [count setWidth:125]; [table addTableColumn:count];
  PreviewData *data=[PreviewData new]; [table setDataSource:data]; [table setRowHeight:30];
  [table setUsesAlternatingRowBackgroundColors:YES]; [table selectRowIndexes:[NSIndexSet indexSetWithIndex:1] byExtendingSelection:NO];
  [scroll setDocumentView:table]; [scroll setHasVerticalScroller:YES]; [scroll setBorderType:NSBezelBorder]; [view addSubview:scroll];
  NSTabView *tabs=[[[NSTabView alloc] initWithFrame:NSMakeRect(464,428,400,180)] autorelease];
  for (NSString *title in @[@"General",@"Advanced",@"Privacy"]) {
    NSTabViewItem *item=[[[NSTabViewItem alloc] initWithIdentifier:title] autorelease]; [item setLabel:title];
    NSView *pane=[[[NSView alloc] initWithFrame:NSMakeRect(0,0,350,100)] autorelease];
    label(pane,@"Simple surfaces. Familiar controls.",NSMakeRect(14,34,340,24),13,NO);
    [item setView:pane]; [tabs addTabViewItem:item];
  }
  [view addSubview:tabs];
  assert(NSMinY([tabs contentRect])>=28);
  label(view,@"Opaque fills • Vector symbols • No material effects",NSMakeRect(34,796,800,22),12,NO);
  label(view,@"MENUS",NSMakeRect(34,554,300,20),11,YES);
  NSMenu *menu=[[[NSMenu alloc] initWithTitle:@"Actions"] autorelease];
  [menu addItemWithTitle:@"New Folder" action:NULL keyEquivalent:@"n"];
  [menu addItemWithTitle:@"Rename" action:NULL keyEquivalent:@""];
  [menu addItem:[NSMenuItem separatorItem]];
  [menu addItemWithTitle:@"Get Info" action:NULL keyEquivalent:@"i"];
  [menu setAutoenablesItems:NO];
  NSMenuView *menuView=(NSMenuView *)[menu menuRepresentation];
  [menuView setHorizontal:NO]; [menuView sizeToFit];
  NSRect menuFrame=[menuView frame]; menuFrame.origin=NSMakePoint(32,584);
  [menuView setFrame:menuFrame];
  [menuView setHighlightedItemIndex:1]; [view addSubview:menuView];
  label(view,@"OPTIONS",NSMakeRect(466,642,300,20),11,YES);
  NSSwitch *toggle=[[[NSSwitch alloc] initWithFrame:NSMakeRect(464,674,50,28)] autorelease];
  [toggle setState:NSControlStateValueOn]; [view addSubview:toggle];
  label(view,@"Automatic updates",NSMakeRect(528,679,250,24),13,NO);
  [spinner setDisplayedWhenStopped:YES];
  [window makeKeyAndOrderFront:nil]; [window display];
  // Regression: state changes produce different pixels without mutating geometry.
  NSData *before=capture(normal); [[normal cell] setHighlighted:YES]; [normal setNeedsDisplay:YES]; [normal display]; NSData *pressed=capture(normal);
  assert(![before isEqual:pressed]); [[normal cell] setHighlighted:NO]; [normal setNeedsDisplay:YES];
  [entry lockFocus];
  assert([[GSTheme theme] drawTextFieldCell:[entry cell] frame:[entry bounds] view:entry]==YES);
  [entry unlockFocus];
  // Editing and custom colors keep the normal AppKit lifecycle/fallback.
  [window makeFirstResponder:entry];
  NSTextView *editor=(NSTextView *)[window firstResponder]; assert([editor isKindOfClass:[NSTextView class]]);
  assert(![editor drawsBackground]);
  [window makeFirstResponder:normal];
  [entry setBackgroundColor:[NSColor yellowColor]];
  assert(![[GSTheme theme] drawTextFieldCell:[entry cell] frame:[entry bounds] view:entry]);
  [entry setBackgroundColor:[NSColor textBackgroundColor]];
  [window makeFirstResponder:window];
  [window display];
  NSString *path=argc>1 ? [NSString stringWithUTF8String:argv[1]] : @"/tmp/default-preview.png";
  assert([capture(view) writeToFile:path atomically:YES]);
  NSLog(@"Default gallery and state/editing regressions passed: %@",path);
  [table setDataSource:nil]; [data release];
  [window orderOut:nil]; [window release]; [pool drain]; return 0;
}
