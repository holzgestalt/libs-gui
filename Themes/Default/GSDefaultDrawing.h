#ifndef _GSDEFAULT_DRAWING_H
#define _GSDEFAULT_DRAWING_H
/* Shared vector primitives. All dimensions are logical AppKit points. */
#import <AppKit/AppKit.h>
#import <GNUstepGUI/GSTheme.h>
#include <math.h>
static inline NSColor *MacGray(CGFloat value)
{ return [NSColor colorWithCalibratedWhite:value alpha:1]; }
static inline NSColor *MacAccent(void)
{ return [NSColor colorWithCalibratedRed:0.04 green:0.46 blue:0.96 alpha:1]; }
static inline NSColor *MacBorder(void) { return MacGray(0.77); }
static inline void MacRound(NSRect r, CGFloat radius, NSColor *fill, NSColor *border)
{
  if (NSIsEmptyRect(r)) return;
  r = NSInsetRect(r, 0.5, 0.5);
  radius = MIN(radius, MIN(NSWidth(r), NSHeight(r))/2);
  NSBezierPath *p = [NSBezierPath bezierPathWithRoundedRect:r xRadius:radius yRadius:radius];
  if (fill) { [fill set]; [p fill]; }
  if (border) { [border set]; [p setLineWidth:1]; [p stroke]; }
}
static inline void MacLine(NSPoint a, NSPoint b, NSColor *color, CGFloat width)
{
  NSBezierPath *p = [NSBezierPath bezierPath];
  [p moveToPoint:a]; [p lineToPoint:b];
  [p setLineWidth:width]; [p setLineCapStyle:NSRoundLineCapStyle];
  [color set]; [p stroke];
}
static inline void MacChevron(NSRect r, BOOL up, BOOL flipped, NSColor *color)
{
  CGFloat x=NSMidX(r), y=NSMidY(r), d=(up != flipped) ? 1 : -1;
  MacLine(NSMakePoint(x-3,y-1.5*d), NSMakePoint(x,y+1.5*d), color, 1.5);
  MacLine(NSMakePoint(x,y+1.5*d), NSMakePoint(x+3,y-1.5*d), color, 1.5);
}
static inline BOOL MacPressed(GSThemeControlState s)
{
  return s==GSThemeHighlightedState || s==GSThemeHighlightedFirstResponderState
    || s==GSThemeSelectedState || s==GSThemeSelectedFirstResponderState;
}

#endif
