#import "GSDefaultDrawing.h"
#import "GSDefaultTheme.h"
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


@implementation	GSDefaultTheme (MidLevelDrawing)

- (NSRect) drawButton: (NSRect)border withClip: (NSRect)clip
{
[NSGraphicsContext saveGraphicsState];
  if (!NSIsEmptyRect(clip)) NSRectClip(clip);
  MacRound(border,6,nil,MacBorder());
  [NSGraphicsContext restoreGraphicsState];
  return NSInsetRect(border,1,1);
}

- (NSRect) drawDarkBezel: (NSRect)border withClip: (NSRect)clip
{
[NSGraphicsContext saveGraphicsState];
  if (!NSIsEmptyRect(clip)) NSRectClip(clip);
  MacRound(border,6,nil,MacBorder());
  [NSGraphicsContext restoreGraphicsState];
  return NSInsetRect(border,1,1);
}

- (NSRect) drawDarkButton: (NSRect)border withClip: (NSRect)clip
{
[NSGraphicsContext saveGraphicsState];
  if (!NSIsEmptyRect(clip)) NSRectClip(clip);
  MacRound(border,6,nil,MacBorder());
  [NSGraphicsContext restoreGraphicsState];
  return NSInsetRect(border,1,1);
}

- (NSRect) drawFramePhoto: (NSRect)border withClip: (NSRect)clip
{
[NSGraphicsContext saveGraphicsState];
  if (!NSIsEmptyRect(clip)) NSRectClip(clip);
  MacRound(border,6,nil,MacBorder());
  [NSGraphicsContext restoreGraphicsState];
  return NSInsetRect(border,1,1);
}

- (NSRect) drawGradientBorder: (NSGradientType)gradientType
                       inRect: (NSRect)border
                     withClip: (NSRect)clip
{
return border;
}



- (NSRect) drawGrayBezel: (NSRect)border withClip: (NSRect)clip
{
[NSGraphicsContext saveGraphicsState];
  if (!NSIsEmptyRect(clip)) NSRectClip(clip);
  MacRound(border,6,nil,MacBorder());
  [NSGraphicsContext restoreGraphicsState];
  return NSInsetRect(border,1,1);
}

- (NSRect) drawGroove: (NSRect)border withClip: (NSRect)clip
{
[NSGraphicsContext saveGraphicsState];
  if (!NSIsEmptyRect(clip)) NSRectClip(clip);
  MacRound(border,6,nil,MacBorder());
  [NSGraphicsContext restoreGraphicsState];
  return NSInsetRect(border,1,1);
}

- (NSRect) drawLightBezel: (NSRect)border withClip: (NSRect)clip
{
[NSGraphicsContext saveGraphicsState];
  if (!NSIsEmptyRect(clip)) NSRectClip(clip);
  MacRound(border,6,nil,MacBorder());
  [NSGraphicsContext restoreGraphicsState];
  return NSInsetRect(border,1,1);
}

- (NSRect) drawWhiteBezel: (NSRect)border withClip: (NSRect)clip
{
[NSGraphicsContext saveGraphicsState];
  if (!NSIsEmptyRect(clip)) NSRectClip(clip);
  MacRound(border,6,nil,MacBorder());
  [NSGraphicsContext restoreGraphicsState];
  return NSInsetRect(border,1,1);
}

- (void) drawRoundBezel: (NSRect)cellFrame withColor: (NSColor*)backgroundColor
{
MacRound(cellFrame,MIN(9,NSHeight(cellFrame)/2),backgroundColor,MacBorder());
}

- (void) drawCircularBezel: (NSRect)cellFrame
		 withColor: (NSColor*)backgroundColor
{
MacRound(cellFrame,MIN(NSWidth(cellFrame),NSHeight(cellFrame))/2,backgroundColor,MacBorder());
}

@end




@implementation	GSDefaultTheme (LowLevelDrawing)

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
