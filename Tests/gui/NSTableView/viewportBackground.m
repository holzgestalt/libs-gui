#import "Testing.h"
#import <AppKit/AppKit.h>

static BOOL greenPixel(NSBitmapImageRep *bitmap)
{
  NSColor *color = [[bitmap colorAtX: [bitmap pixelsWide] - 3
                                y: [bitmap pixelsHigh] / 2]
    colorUsingColorSpaceName: NSCalibratedRGBColorSpace];
  return [color greenComponent] > .6 && [color redComponent] < .2
    && [color blueComponent] < .4;
}

static NSBitmapImageRep *snapshot(NSView *view)
{
  [view display];
  NSBitmapImageRep *bitmap = [view bitmapImageRepForCachingDisplayInRect: [view bounds]];
  [view cacheDisplayInRect: [view bounds] toBitmapImageRep: bitmap];
  return bitmap;
}

int main(void)
{
  START_SET("NSTableView viewport background")
  [NSApplication sharedApplication];
  NSWindow *window = [[NSWindow alloc] initWithContentRect: NSMakeRect(0,0,300,200)
    styleMask: NSWindowStyleMaskBorderless backing: NSBackingStoreBuffered defer: NO];
  [window setReleasedWhenClosed: NO];
  [window setBackgroundColor: [NSColor magentaColor]];
  NSScrollView *scroll = [[[NSScrollView alloc] initWithFrame: NSMakeRect(0,0,300,200)] autorelease];
  [scroll setBorderType: NSNoBorder];
  [scroll setAutoresizingMask: NSViewWidthSizable | NSViewHeightSizable];
  NSTableView *table = [[[NSTableView alloc] initWithFrame: NSMakeRect(0,0,100,10)] autorelease];
  [table setHeaderView: nil];
  [table setBackgroundColor: [NSColor colorWithCalibratedRed: 0 green: .8 blue: .2 alpha: 1]];
  [table setAutoresizingMask: NSViewWidthSizable | NSViewHeightSizable];
  [scroll setDocumentView: table];
  [[scroll contentView] setDrawsBackground: NO];
  [window setContentView: scroll];
  [window orderFront: nil];
  [table setFrame: NSMakeRect(0,0,100,10)];
  PASS(NSWidth([table frame]) >= NSWidth([[scroll contentView] bounds]),
    "setFrame: keeps a short table as wide as its transparent viewport")
  PASS(greenPixel(snapshot(scroll)),
    "the table paints the empty area at the right edge of its viewport")
  [scroll setAutohidesScrollers: YES];
  [scroll setHasVerticalScroller: YES];
  [table reloadData];
  [table setFrameSize: NSMakeSize(100,10)];
  PASS(NSWidth([table frame]) >= NSWidth([[scroll contentView] bounds]),
    "setFrameSize: covers the space returned by an autohiding scroller")
  PASS(greenPixel(snapshot(scroll)),
    "no old scrollbar border is exposed through the transparent clip view")
  [window setContentSize: NSMakeSize(500,350)];
  [table setFrame: NSMakeRect(0,0,120,10)];
  PASS(NSWidth([table frame]) >= NSWidth([[scroll contentView] bounds])
    && NSHeight([table frame]) >= NSHeight([[scroll contentView] bounds]),
    "resizing keeps the full viewport covered in both dimensions")
  PASS(greenPixel(snapshot(scroll)), "the enlarged sidebar background reaches its right edge")
  [window close];
  [window release];
  END_SET("NSTableView viewport background")
  return 0;
}
