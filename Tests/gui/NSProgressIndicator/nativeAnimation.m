/* Animation ownership can move between AppKit and a toolkit peer. */
#import <AppKit/AppKit.h>
#import <GNUstepGUI/GSNativeView.h>
#include "Testing.h"

@interface AnimationPeer : NSObject <GSNativeViewPeer>
@end
@implementation AnimationPeer
- (void)invalidateNativeView:(NSView *)view inRect:(NSRect)rect {}
- (BOOL)ownsLayoutForNativeView:(NSView *)view { return YES; }
- (void)layoutNativeView:(NSView *)view {}
- (BOOL)focusNativeView:(NSView *)view { return NO; }
- (BOOL)ownsAnimationForNativeView:(NSView *)view { return YES; }
@end
@interface DrawingPeer : AnimationPeer @end
@implementation DrawingPeer
- (BOOL)ownsAnimationForNativeView:(NSView *)view { return NO; }
@end
@interface CountingIndicator : NSProgressIndicator
{
  NSUInteger ticks;
}
- (NSUInteger)ticks;
@end
@implementation CountingIndicator
- (void)animate:(id)sender
{
  @synchronized(self) { ticks++; }
  [super animate:sender];
}
- (NSUInteger)ticks { @synchronized(self) { return ticks; } }
@end
static void pump(void)
{
  [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:.12]];
}
int main(void)
{
  NSAutoreleasePool *pool=[NSAutoreleasePool new];
  [NSApplication sharedApplication];
  AnimationPeer *peer=[AnimationPeer new];
  for (int threaded=0;threaded<2;threaded++) {
    CountingIndicator *indicator=[[CountingIndicator alloc] initWithFrame:NSMakeRect(0,0,200,24)];
    [indicator setUsesThreadedAnimation:threaded];
    [indicator setAnimationDelay:.01];
    [indicator startAnimation:nil]; pump();
    PASS(indicator.isAnimating && indicator.ticks>0,"AppKit animation runs before native attachment");
    GSSetNativeViewPeer(indicator,peer); pump();
    NSUInteger count=indicator.ticks; pump();
    PASS(indicator.isAnimating && indicator.ticks==count,"native peer owns animation without AppKit wakeups");
    GSSetNativeViewPeer(indicator,nil); pump();
    PASS(indicator.ticks>count,"AppKit animation resumes after native detachment");
    DrawingPeer *drawing=[DrawingPeer new];
    count=indicator.ticks; GSSetNativeViewPeer(indicator,drawing); pump();
    PASS(indicator.ticks>count,"a drawing-only peer preserves AppKit animation");
    GSSetNativeViewPeer(indicator,nil); [drawing release];
    GSSetNativeViewPeer(indicator,peer);
    [indicator stopAnimation:nil];
    [indicator startAnimation:nil]; pump(); count=indicator.ticks; pump();
    PASS(indicator.isAnimating && indicator.ticks==count,"startAnimation on an attached peer avoids AppKit wakeups");
    [indicator stopAnimation:nil];
    GSSetNativeViewPeer(indicator,nil); pump();
    PASS(!indicator.isAnimating && indicator.ticks==count,"stopped native indicator stays stopped after detachment");
    [indicator release];
  }
  [peer release]; [pool drain]; return 0;
}
