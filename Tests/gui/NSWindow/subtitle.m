#import <AppKit/AppKit.h>
#import "Testing.h"

int main(void)
{
  NSAutoreleasePool *pool = [NSAutoreleasePool new];
  [NSApplication sharedApplication];
  NSWindow *window = [[NSWindow alloc] initWithContentRect:NSMakeRect(0,0,300,200)
    styleMask:NSTitledWindowMask backing:NSBackingStoreBuffered defer:NO];
  [window setReleasedWhenClosed:NO];
  [window setTitle:@"Document"];
  PASS([[window subtitle] isEqual:@""], "new windows have an empty subtitle");
  NSMutableString *subtitle = [NSMutableString stringWithString:@"5 infos"];
  [window setSubtitle:subtitle]; [subtitle appendString:@" changed"];
  PASS([[window subtitle] isEqual:@"5 infos"], "subtitles are copied rather than retained");
  [window setTitle:@"Renamed"];
  PASS([[window subtitle] isEqual:@"5 infos"], "changing the title preserves the subtitle");
  [window setSubtitle:nil];
  PASS([[window subtitle] isEqual:@""] && [[window title] isEqual:@"Renamed"],
    "clearing the subtitle preserves the title");
  [window close]; [window release]; [pool drain]; return 0;
}
