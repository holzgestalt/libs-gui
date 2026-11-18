#import <AppKit/AppKit.h>
#import <GNUstepGUI/GSTheme.h>
#include <assert.h>
int main(int argc, char **argv) {
  NSAutoreleasePool *pool=[NSAutoreleasePool new];
  @try {
    if (argc>1 && strcmp(argv[1],"missing")==0) {
      [GSTheme theme]; return 2;
    }
    [NSApplication sharedApplication];
    NSString *name=[[GSTheme theme] name];
    assert([name isEqual:[NSString stringWithUTF8String:argv[1]]]);
    NSWindow *window=[[NSWindow alloc] initWithContentRect:NSMakeRect(0,0,240,120)
      styleMask:NSTitledWindowMask backing:NSBackingStoreBuffered defer:NO];
    NSButton *button=[[[NSButton alloc] initWithFrame:NSMakeRect(20,20,160,32)] autorelease];
    [button setTitle:name]; [button setBezelStyle:NSRoundedBezelStyle];
    [[window contentView] addSubview:button]; [window display];
    NSLog(@"Application-linked theme %@ draws successfully",name);
    [window release];
  } @catch (NSException *error) {
    if (argc>1 && strcmp(argv[1],"missing")==0 && [[error reason] containsString:@"must link a theme"]) {
      NSLog(@"Expected no-theme failure: %@",[error reason]); return 0;
    }
    NSLog(@"Unexpected exception: %@",error); return 1;
  }
  [pool drain]; return 0;
}
