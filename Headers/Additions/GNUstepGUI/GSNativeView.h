/* Optional platform view peers. No toolkit or theme dependency belongs here.
   Registration and callbacks are on the AppKit thread; peers are weakly held. */
#ifndef _GNUstepGUI_GSNativeView_h
#define _GNUstepGUI_GSNativeView_h
#import <AppKit/NSView.h>
@protocol GSNativeViewPeer <NSObject>
- (void)invalidateNativeView:(NSView *)view inRect:(NSRect)rect;
- (BOOL)ownsLayoutForNativeView:(NSView *)view;
- (void)layoutNativeView:(NSView *)view;
- (BOOL)focusNativeView:(NSView *)view;
@end
/* Draw only this view, with native dirty-region queries, in the current context. */
APPKIT_EXPORT void GSDrawNativeView(NSView *view, NSRect rect);
@protocol GSNativeEventSource <NSObject>
- (NSEvent *)nativeEventMatchingMask:(NSUInteger)mask dequeue:(BOOL)dequeue;
@end
APPKIT_EXPORT id<GSNativeEventSource> GSSetNativeEventSource(id<GSNativeEventSource> source);
APPKIT_EXPORT NSEvent *GSNextNativeEvent(NSUInteger mask, BOOL dequeue);
APPKIT_EXPORT void GSSetNativeViewPeer(NSView *view, id<GSNativeViewPeer> peer);
APPKIT_EXPORT id<GSNativeViewPeer> GSNativeViewPeerForView(NSView *view);
#endif
