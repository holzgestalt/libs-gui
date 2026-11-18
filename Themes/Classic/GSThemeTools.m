#import "GSClassicTheme.h"
/** <title>GSThemeTools</title>

   <abstract>Useful/configurable drawing functions</abstract>

   Copyright (C) 2004 Free Software Foundation, Inc.

   Author: Adam Fedor <fedor@gnu.org>
   Date: Jan 2004

   This file is part of the GNU Objective C User interface library.

   This library is free software; you can redistribute it and/or
   modify it under the terms of the GNU Lesser General Public
   License as published by the Free Software Foundation; either
   version 2 of the License, or (at your option) any later version.

   This library is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.	 See the GNU
   Lesser General Public License for more details.

   You should have received a copy of the GNU Lesser General Public
   License along with this library; see the file COPYING.LIB.
   If not, see <http://www.gnu.org/licenses/> or write to the
   Free Software Foundation, 51 Franklin Street, Fifth Floor,
   Boston, MA 02110-1301, USA.
*/

#import <Foundation/NSException.h>
#import "AppKit/NSBezierPath.h"
#import "AppKit/NSGraphics.h"
#import "AppKit/NSImage.h"
#import "AppKit/PSOperators.h"
#import "GSThemePrivate.h"

#include <math.h>
#include <float.h>


@implementation	GSClassicTheme (MidLevelDrawing)

- (NSRect) drawButton: (NSRect)border withClip: (NSRect)clip
{
  NSRectEdge up_sides[] = {NSMaxXEdge, NSMinYEdge,
			   NSMinXEdge, NSMaxYEdge,
			   NSMaxXEdge, NSMinYEdge};
  NSRectEdge dn_sides[] = {NSMaxXEdge, NSMaxYEdge,
			   NSMinXEdge, NSMinYEdge,
			   NSMaxXEdge, NSMaxYEdge};
  // These names are role names not the actual colours
  NSColor *black = [NSColor controlDarkShadowColor];
  NSColor *dark = [NSColor controlShadowColor];
  NSColor *white = [NSColor controlLightHighlightColor];
  NSColor *colors[] = {black, black, white, white, dark, dark};

  if ([[NSView focusView] isFlipped] == YES)
    {
      return NSDrawColorTiledRects(border, clip, dn_sides, colors, 6);
    }
  else
    {
      return NSDrawColorTiledRects(border, clip, up_sides, colors, 6);
    }
}

- (NSRect) drawDarkBezel: (NSRect)border withClip: (NSRect)clip
{
  NSRectEdge up_sides[] = {NSMaxXEdge, NSMinYEdge, NSMinXEdge, NSMaxYEdge,
			   NSMinXEdge, NSMaxYEdge, NSMaxXEdge, NSMinYEdge};
  NSRectEdge dn_sides[] = {NSMaxXEdge, NSMaxYEdge, NSMinXEdge, NSMinYEdge,
			   NSMinXEdge, NSMinYEdge, NSMaxXEdge, NSMaxYEdge};
  // These names are role names not the actual colours
  NSColor *black = [NSColor controlDarkShadowColor];
  NSColor *dark = [NSColor controlShadowColor];
  NSColor *light = [NSColor controlColor];
  NSColor *white = [NSColor controlLightHighlightColor];
  NSColor *colors[] = {white, white, dark, dark, black, black, light, light};
  NSRect rect;

  if ([[NSView focusView] isFlipped] == YES)
    {
      rect = NSDrawColorTiledRects(border, clip, dn_sides, colors, 8);

      [dark set];
      PSrectfill(NSMinX(border) + 1., NSMinY(border) - 2., 1., 1.);
      PSrectfill(NSMaxX(border) - 2., NSMaxY(border) + 1., 1., 1.);
    }
  else
    {
      rect = NSDrawColorTiledRects(border, clip, up_sides, colors, 8);

      [dark set];
      PSrectfill(NSMinX(border) + 1., NSMinY(border) + 1., 1., 1.);
      PSrectfill(NSMaxX(border) - 2., NSMaxY(border) - 2., 1., 1.);
    }
  return rect;
}

- (NSRect) drawDarkButton: (NSRect)border withClip: (NSRect)clip
{
  NSRectEdge up_sides[] = {NSMaxXEdge, NSMinYEdge,
			   NSMinXEdge, NSMaxYEdge};
  NSRectEdge dn_sides[] = {NSMaxXEdge, NSMaxYEdge,
			   NSMinXEdge, NSMinYEdge};
  // These names are role names not the actual colours
  NSColor *black = [NSColor controlDarkShadowColor];
  NSColor *white = [NSColor controlHighlightColor];
  NSColor *colors[] = {black, black, white, white};

  if ([[NSView focusView] isFlipped] == YES)
    {
      return NSDrawColorTiledRects(border, clip, dn_sides, colors, 4);
    }
  else
    {
      return NSDrawColorTiledRects(border, clip, up_sides, colors, 4);
    }
}

- (NSRect) drawFramePhoto: (NSRect)border withClip: (NSRect)clip
{
  NSRectEdge up_sides[] = {NSMaxXEdge, NSMinYEdge,
			   NSMinXEdge, NSMaxYEdge,
			   NSMaxXEdge, NSMinYEdge};
  NSRectEdge dn_sides[] = {NSMaxXEdge, NSMaxYEdge,
			   NSMinXEdge, NSMinYEdge,
			   NSMaxXEdge, NSMaxYEdge};
  // These names are role names not the actual colours
  NSColor *black = [NSColor controlDarkShadowColor];
  NSColor *dark = [NSColor controlShadowColor];
  NSColor *colors[] = {dark, dark, dark, dark, black,black};

  if ([[NSView focusView] isFlipped] == YES)
    {
      return NSDrawColorTiledRects(border, clip, dn_sides, colors, 6);
    }
  else
    {
      return NSDrawColorTiledRects(border, clip, up_sides, colors, 6);
    }
}

#if 1
- (NSRect) drawGradientBorder: (NSGradientType)gradientType
                       inRect: (NSRect)border
                     withClip: (NSRect)clip
{
  NSRectEdge up_sides[] = {NSMaxXEdge, NSMinYEdge,
			   NSMinXEdge, NSMaxYEdge};
  NSRectEdge dn_sides[] = {NSMaxXEdge, NSMaxYEdge,
			   NSMinXEdge, NSMinYEdge};
  NSColor *black = [NSColor controlDarkShadowColor];
  NSColor *dark = [NSColor controlShadowColor];
  NSColor *light = [NSColor controlColor];
  NSColor **colors;
  NSColor *concaveWeak[] = {dark, dark, light, light};
  NSColor *concaveStrong[] = {black, black, light, light};
  NSColor *convexWeak[] = {light, light, dark, dark};
  NSColor *convexStrong[] = {light, light, black, black};
  NSRect rect;

  switch (gradientType)
    {
      case NSGradientConcaveWeak:
	colors = concaveWeak;
	break;
      case NSGradientConcaveStrong:
	colors = concaveStrong;
	break;
      case NSGradientConvexWeak:
	colors = convexWeak;
	break;
      case NSGradientConvexStrong:
	colors = convexStrong;
	break;
      case NSGradientNone:
      default:
	return border;
    }

  if ([[NSView focusView] isFlipped] == YES)
    {
      rect = NSDrawColorTiledRects(border, clip, dn_sides, colors, 4);
    }
  else
    {
      rect = NSDrawColorTiledRects(border, clip, up_sides, colors, 4);
    }

  return rect;
}

#else
// FIXME: I think this method is wrong.
- (NSRect) drawGradientBorder: (NSGradientType)gradientType
                       inRect: (NSRect)cellFrame
                     withClip: (NSRect)clip
{
  float   start_white = 0.0;
  float   end_white = 0.0;
  float   white = 0.0;
  float   white_step = 0.0;
  float   h, s, v, a;
  NSPoint p1, p2;
  NSColor *gray = nil;
  NSColor *darkGray = nil;
  NSColor *lightGray = nil;

  lightGray = [NSColor colorWithDeviceRed: NSLightGray
                       green: NSLightGray
                       blue: NSLightGray
                       alpha:1.0];
  gray = [NSColor colorWithDeviceRed: NSGray
                  green: NSGray
                  blue: NSGray
                  alpha:1.0];
  darkGray = [NSColor colorWithDeviceRed: NSDarkGray
                      green: NSDarkGray
                      blue: NSDarkGray
                      alpha:1.0];

  switch (gradientType)
    {
      case NSGradientNone:
        return NSZeroRect;
        break;

      case NSGradientConcaveWeak:
        [gray getHue: &h saturation: &s brightness: &v alpha: &a];
        start_white = [lightGray brightnessComponent];
        end_white = [gray brightnessComponent];
        break;

      case NSGradientConvexWeak:
        [darkGray getHue: &h saturation: &s brightness: &v alpha: &a];
        start_white = [gray brightnessComponent];
        end_white = [lightGray brightnessComponent];
        break;

      case NSGradientConcaveStrong:
        [lightGray getHue: &h saturation: &s brightness: &v alpha: &a];
        start_white = [lightGray brightnessComponent];
        end_white = [darkGray brightnessComponent];
        break;

      case NSGradientConvexStrong:
        [darkGray getHue: &h saturation: &s brightness: &v alpha: &a];
        start_white = [darkGray brightnessComponent];
        end_white = [lightGray brightnessComponent];
        break;

      default:
        break;
    }

  white = start_white;
  white_step = fabs(start_white - end_white)
    / (cellFrame.size.width + cellFrame.size.height);

  // Start from top left
  p1 = NSMakePoint(cellFrame.origin.x,
    cellFrame.size.height + cellFrame.origin.y);
  p2 = NSMakePoint(cellFrame.origin.x,
    cellFrame.size.height + cellFrame.origin.y);

  // Move by Y
  while (p1.y > cellFrame.origin.y)
    {
      [[NSColor
        colorWithDeviceHue: h saturation: s brightness: white alpha: 1.0] set];
      [NSBezierPath strokeLineFromPoint: p1 toPoint: p2];

      if (start_white > end_white)
        white -= white_step;
      else
        white += white_step;

      p1.y -= 1.0;
      if (p2.x < (cellFrame.size.width + cellFrame.origin.x))
        p2.x += 1.0;
      else
        p2.y -= 1.0;
    }

  // Move by X
  while (p1.x < (cellFrame.size.width + cellFrame.origin.x))
    {
      [[NSColor
        colorWithDeviceHue: h saturation: s brightness: white alpha: 1.0] set];
      [NSBezierPath strokeLineFromPoint: p1 toPoint: p2];

      if (start_white > end_white)
        white -= white_step;
      else
        white += white_step;

      p1.x += 1.0;
      if (p2.x >= (cellFrame.size.width + cellFrame.origin.x))
        p2.y -= 1.0;
      else
        p2.x += 1.0;
    }

  return NSZeroRect;
}

#endif

- (NSRect) drawGrayBezel: (NSRect)border withClip: (NSRect)clip
{
  NSRectEdge up_sides[] = {NSMaxXEdge, NSMinYEdge, NSMinXEdge, NSMaxYEdge,
			   NSMaxXEdge, NSMinYEdge, NSMinXEdge, NSMaxYEdge};
  NSRectEdge dn_sides[] = {NSMaxXEdge, NSMaxYEdge, NSMinXEdge, NSMinYEdge,
			     NSMaxXEdge, NSMaxYEdge, NSMinXEdge, NSMinYEdge};
  // These names are role names not the actual colours
  NSColor *black = [NSColor controlDarkShadowColor];
  NSColor *dark = [NSColor controlShadowColor];
  NSColor *light = [NSColor controlColor];
  NSColor *white = [NSColor controlLightHighlightColor];
  NSColor *colors[] = {white, white, dark, dark,
		       light, light, black, black};
  NSRect rect;

  if ([[NSView focusView] isFlipped] == YES)
    {
      rect = NSDrawColorTiledRects(border, clip, dn_sides, colors, 8);
      [dark set];
      PSrectfill(NSMinX(border) + 1., NSMaxY(border) - 2., 1., 1.);
      PSrectfill(NSMaxX(border) - 2., NSMinY(border) + 1., 1., 1.);
    }
  else
    {
      rect = NSDrawColorTiledRects(border, clip, up_sides, colors, 8);
      [dark set];
      PSrectfill(NSMinX(border) + 1., NSMinY(border) + 1., 1., 1.);
      PSrectfill(NSMaxX(border) - 2., NSMaxY(border) - 2., 1., 1.);
    }
  return rect;
}

- (NSRect) drawGroove: (NSRect)border withClip: (NSRect)clip
{
  // go clockwise from the top twice -- makes the groove come out right
  NSRectEdge up_sides[] = {NSMaxYEdge, NSMaxXEdge, NSMinYEdge, NSMinXEdge,
			   NSMaxYEdge, NSMaxXEdge, NSMinYEdge, NSMinXEdge};
  NSRectEdge dn_sides[] = {NSMinYEdge, NSMaxXEdge, NSMaxYEdge, NSMinXEdge,
			   NSMinYEdge, NSMaxXEdge, NSMaxYEdge, NSMinXEdge};
  // These names are role names not the actual colours
  NSColor *dark = [NSColor controlShadowColor];
  NSColor *white = [NSColor controlLightHighlightColor];
  NSColor *colors[] = {dark, white, white, dark,
		       white, dark, dark, white};

  if ([[NSView focusView] isFlipped] == YES)
    {
      return NSDrawColorTiledRects(border, clip, dn_sides, colors, 8);
    }
  else
    {
      return NSDrawColorTiledRects(border, clip, up_sides, colors, 8);
    }
}

- (NSRect) drawLightBezel: (NSRect)border withClip: (NSRect)clip
{
  NSRectEdge up_sides[] = {NSMaxXEdge, NSMinYEdge, NSMinXEdge, NSMaxYEdge,
                           NSMaxXEdge, NSMinYEdge, NSMinXEdge, NSMaxYEdge};
  NSRectEdge dn_sides[] = {NSMaxXEdge, NSMaxYEdge, NSMinXEdge, NSMinYEdge,
			   NSMaxXEdge, NSMaxYEdge, NSMinXEdge, NSMinYEdge};
  // These names are role names not the actual colours
  NSColor *dark = [NSColor controlShadowColor];
  NSColor *light = [NSColor controlColor];
  NSColor *white = [NSColor controlLightHighlightColor];
  NSColor *colors[] = {white, white, dark, dark,
		       light, light, dark, dark};

  if ([[NSView focusView] isFlipped] == YES)
    {
      return NSDrawColorTiledRects(border, clip, dn_sides, colors, 8);
    }
  else
    {
      return NSDrawColorTiledRects(border, clip, up_sides, colors, 8);
    }
}

- (NSRect) drawWhiteBezel: (NSRect)border withClip: (NSRect)clip
{
  NSRectEdge up_sides[] = {NSMaxYEdge, NSMaxXEdge, NSMinYEdge, NSMinXEdge,
                           NSMaxYEdge, NSMaxXEdge, NSMinYEdge, NSMinXEdge};
  NSRectEdge dn_sides[] = {NSMinYEdge, NSMaxXEdge, NSMaxYEdge, NSMinXEdge,
                             NSMinYEdge, NSMaxXEdge, NSMaxYEdge, NSMinXEdge};
  // These names are role names not the actual colours
  NSColor *dark = [NSColor controlShadowColor];
  NSColor *light = [NSColor controlColor];
  NSColor *white = [NSColor controlLightHighlightColor];
  NSColor *colors[] = {dark, white, white, dark,
		       dark, light, light, dark};

  if ([[NSView focusView] isFlipped] == YES)
    {
      return NSDrawColorTiledRects(border, clip, dn_sides, colors, 8);
    }
  else
    {
      return NSDrawColorTiledRects(border, clip, up_sides, colors, 8);
    }
}

- (void) drawRoundBezel: (NSRect)cellFrame withColor: (NSColor*)backgroundColor
{
  NSBezierPath *p;
  NSPoint point;
  CGFloat radius;

  // make smaller than enclosing frame
  cellFrame = NSInsetRect(cellFrame, 4, 4);
  radius = cellFrame.size.height / 2.0;
  point = cellFrame.origin;
  point.x += radius;
  point.y += radius - 0.5;

  // Draw initial path to enclose the button...
  // left half-circle
  p = [NSBezierPath bezierPath];
  [p appendBezierPathWithArcWithCenter: point
				radius: radius
			    startAngle: 90.0
			      endAngle: 270.0];

  // line to first point and right halfcircle
  point.x += cellFrame.size.width - cellFrame.size.height;
  [p appendBezierPathWithArcWithCenter: point
				radius: radius
			    startAngle: 270.0
			      endAngle: 90.0];
  [p closePath];

  // fill with background color
  [backgroundColor set];
  [p fill];

  // and stroke rounded button
  [[NSColor shadowColor] set];
  [p stroke];

  // Add highlights...
  point = cellFrame.origin;
  point.x += radius - 0.5;
  point.y += radius - 0.5;
  p = [NSBezierPath bezierPath];
  [p setLineWidth: 1.0];
  [p appendBezierPathWithArcWithCenter: point
				radius: radius
			    startAngle: 135.0
			      endAngle: 270.0];

  // line to first point and right halfcircle
  point.x += cellFrame.size.width - cellFrame.size.height;
  [p appendBezierPathWithArcWithCenter: point
				radius: radius
			    startAngle: 270.0
			      endAngle: 315.0];
  [[NSColor controlLightHighlightColor] set];
  [p stroke];
}

- (void) drawCircularBezel: (NSRect)cellFrame
		 withColor: (NSColor*)backgroundColor
{
  // make smaller so that it does not touch frame
  NSBezierPath *oval;

  oval = [NSBezierPath bezierPathWithOvalInRect: NSInsetRect(cellFrame, 1, 1)];

  // fill oval with background color
  [backgroundColor set];
  [oval fill];

  // and stroke rounded button
  [[NSColor shadowColor] set];
  [oval stroke];
}

@end




@implementation	GSClassicTheme (LowLevelDrawing)

- (void) fillHorizontalRect: (NSRect)rect
		  withImage: (NSImage*)image
		   fromRect: (NSRect)source
		    flipped: (BOOL)flipped
{
  NSGraphicsContext	*ctxt = GSCurrentContext();
  NSBezierPath		*path;
  unsigned		repetitions;
  float			remainder;
  unsigned		count;
  NSPoint		p;
  float			y;

  if (rect.size.width <= 0.0)
    [NSException raise: NSInvalidArgumentException
		format: @"[%@-%@] rect width is not positive",
      NSStringFromClass([self class]), NSStringFromSelector(_cmd)];
  if (rect.size.height <= 0.0)
    [NSException raise: NSInvalidArgumentException
		format: @"[%@-%@] rect height is not positive",
      NSStringFromClass([self class]), NSStringFromSelector(_cmd)];
  if (source.size.width <= 0.0)
    [NSException raise: NSInvalidArgumentException
		format: @"[%@-%@] source width is not positive",
      NSStringFromClass([self class]), NSStringFromSelector(_cmd)];
  if (source.size.height <= 0.0)
    [NSException raise: NSInvalidArgumentException
		format: @"[%@-%@] source height is not positive",
      NSStringFromClass([self class]), NSStringFromSelector(_cmd)];
  if (image == nil)
    [NSException raise: NSInvalidArgumentException
		format: @"[%@-%@] image is nil",
      NSStringFromClass([self class]), NSStringFromSelector(_cmd)];

  ctxt = GSCurrentContext();
  DPSgsave (ctxt);
  path = [NSBezierPath bezierPathWithRect: rect];
  [path addClip];
  repetitions = rect.size.width / source.size.width;
  remainder = rect.size.width - repetitions * source.size.width;
  y = rect.origin.y;

  if (flipped) y = rect.origin.y + rect.size.height;

  for (count = 0; count < repetitions; count++)
    {
      p = NSMakePoint (rect.origin.x + count * source.size.width, y);
      [image compositeToPoint: p
		     fromRect: source
		    operation: NSCompositeSourceOver];
    }
  if (remainder > 0)
    {
      p = NSMakePoint (rect.origin.x + repetitions * source.size.width, y);
      source.size.width = remainder;
      [image compositeToPoint: p
		     fromRect: source
		    operation: NSCompositeSourceOver];
    }
  DPSgrestore (ctxt);
}

- (void) fillRect: (NSRect)rect
withRepeatedImage: (NSImage*)image
	 fromRect: (NSRect)source
	   center: (BOOL)center
{
  NSGraphicsContext	*ctxt;
  NSBezierPath		*path;
  NSSize		size;
  unsigned		xrepetitions;
  unsigned		yrepetitions;
  unsigned		x;
  unsigned		y;

  if (rect.size.width <= 0.0)
    [NSException raise: NSInvalidArgumentException
		format: @"[%@-%@] rect width is not positive",
      NSStringFromClass([self class]), NSStringFromSelector(_cmd)];
  if (rect.size.height <= 0.0)
    [NSException raise: NSInvalidArgumentException
		format: @"[%@-%@] rect height is not positive",
      NSStringFromClass([self class]), NSStringFromSelector(_cmd)];
  if (source.size.width <= 0.0)
    [NSException raise: NSInvalidArgumentException
		format: @"[%@-%@] source width is not positive",
      NSStringFromClass([self class]), NSStringFromSelector(_cmd)];
  if (source.size.height <= 0.0)
    [NSException raise: NSInvalidArgumentException
		format: @"[%@-%@] source height is not positive",
      NSStringFromClass([self class]), NSStringFromSelector(_cmd)];
  if (image == nil)
    [NSException raise: NSInvalidArgumentException
		format: @"[%@-%@] image is nil",
      NSStringFromClass([self class]), NSStringFromSelector(_cmd)];

  ctxt = GSCurrentContext ();
  DPSgsave (ctxt);
  path = [NSBezierPath bezierPathWithRect: rect];
  [path addClip];
  size = [image size];
  xrepetitions = (rect.size.width / size.width) + 1;
  yrepetitions = (rect.size.height / size.height) + 1;

  for (x = 0; x < xrepetitions; x++)
    {
      for (y = 0; y < yrepetitions; y++)
	{
	  NSPoint p;

	  p = NSMakePoint (rect.origin.x + x * size.width,
	    rect.origin.y + y * size.height);
	  [image compositeToPoint: p
			 fromRect: source
			operation: NSCompositeSourceOver];
      }
  }
  DPSgrestore (ctxt);
}

- (NSRect) fillRect: (NSRect)rect
	  withTiles: (GSDrawTiles*)tiles
	 background: (NSColor*)color
{
  return [self fillRect: rect
	      withTiles: tiles
	     background: color
	      fillStyle: [tiles fillStyle]];
}

- (NSRect) fillRect: (NSRect)rect
	  withTiles: (GSDrawTiles*)tiles
{
  return [self fillRect: rect
	      withTiles: tiles
	     background: [NSColor clearColor]
	      fillStyle: [tiles fillStyle]];
}

- (NSRect) fillRect: (NSRect)rect
	  withTiles: (GSDrawTiles*)tiles
	 background: (NSColor*)color
	  fillStyle: (GSThemeFillStyle)style
{
  if (rect.size.width <= 0.0)
    [NSException raise: NSInvalidArgumentException
		format: @"[%@-%@] rect width is not positive",
      NSStringFromClass([self class]), NSStringFromSelector(_cmd)];
  if (rect.size.height <= 0.0)
    [NSException raise: NSInvalidArgumentException
		format: @"[%@-%@] rect height is not positive",
      NSStringFromClass([self class]), NSStringFromSelector(_cmd)];
  if (tiles == nil)
    [NSException raise: NSInvalidArgumentException
		format: @"[%@-%@] tiles is nil",
      NSStringFromClass([self class]), NSStringFromSelector(_cmd)];

  return [tiles fillRect: rect background: color fillStyle: style];
}

- (void) fillVerticalRect: (NSRect)rect
		withImage: (NSImage*)image
		 fromRect: (NSRect)source
		  flipped: (BOOL)flipped
{
  NSGraphicsContext	*ctxt;
  NSBezierPath		*path;
  unsigned		repetitions;
  float			remainder;
  unsigned		count;
  NSPoint		p;

  if (rect.size.width <= 0.0)
    [NSException raise: NSInvalidArgumentException
		format: @"[%@-%@] rect width is not positive",
      NSStringFromClass([self class]), NSStringFromSelector(_cmd)];
  if (rect.size.height <= 0.0)
    [NSException raise: NSInvalidArgumentException
		format: @"[%@-%@] rect height is not positive",
      NSStringFromClass([self class]), NSStringFromSelector(_cmd)];
  if (source.size.width <= 0.0)
    [NSException raise: NSInvalidArgumentException
		format: @"[%@-%@] source width is not positive",
      NSStringFromClass([self class]), NSStringFromSelector(_cmd)];
  if (source.size.height <= 0.0)
    [NSException raise: NSInvalidArgumentException
		format: @"[%@-%@] source height is not positive",
      NSStringFromClass([self class]), NSStringFromSelector(_cmd)];
  if (image == nil)
    [NSException raise: NSInvalidArgumentException
		format: @"[%@-%@] image is nil",
      NSStringFromClass([self class]), NSStringFromSelector(_cmd)];
  ctxt = GSCurrentContext();
  DPSgsave (ctxt);
  path = [NSBezierPath bezierPathWithRect: rect];
  [path addClip];
  repetitions = rect.size.height / source.size.height;
  remainder = rect.size.height - repetitions * source.size.height;

  if (flipped)
    {
      for (count = 0; count < repetitions; count++)
	{
	  p = NSMakePoint (rect.origin.x,
	    rect.origin.y + rect.size.height - count * source.size.height);
	  [image compositeToPoint: p
			 fromRect: source
			operation: NSCompositeSourceOver];
	}
      if (remainder > 0)
	{
	  p = NSMakePoint (rect.origin.x,
	    rect.origin.y + rect.size.height
	    - repetitions * source.size.height);
	  source.origin.y += source.size.height - remainder;
	  source.size.height = remainder;
	  [image compositeToPoint: p
			 fromRect: source
			operation: NSCompositeSourceOver];
	}
    }
  else
    {
      for (count = 0; count < repetitions; count++)
	{
	  p = NSMakePoint (rect.origin.x,
	    rect.origin.y + count * source.size.height);
	  [image compositeToPoint: p
			 fromRect: source
			operation: NSCompositeSourceOver];
	}
      if (remainder > 0)
	{
	  p = NSMakePoint (rect.origin.x,
	    rect.origin.y + repetitions * source.size.height);
	  source.size.height = remainder;
	  [image compositeToPoint: p
			 fromRect: source
			operation: NSCompositeSourceOver];
	}
    }
  DPSgrestore (ctxt);
}

@end
