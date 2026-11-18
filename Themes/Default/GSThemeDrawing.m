#import "GSDefaultDrawing.h"
#import "GSDefaultTheme.h"
/** <title>GSThemeDrawing</title>

   <abstract>The theme methods for drawing controls</abstract>

   Copyright (C) 2004-2023 Free Software Foundation, Inc.

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

#import "GSThemePrivate.h"

#import "Foundation/NSUserDefaults.h"
#import "Foundation/NSIndexSet.h"

#import "AppKit/NSAttributedString.h"
#import "AppKit/NSBezierPath.h"
#import "AppKit/NSButton.h"
#import "AppKit/NSButtonCell.h"
#import "AppKit/NSBrowser.h"
#import "AppKit/NSBrowserCell.h"
#import "AppKit/NSCell.h"
#import "AppKit/NSColor.h"
#import "AppKit/NSColorList.h"
#import "AppKit/NSColorWell.h"
#import "AppKit/NSGraphics.h"
#import "AppKit/NSImage.h"
#import "AppKit/NSImageView.h"
#import "AppKit/NSKeyValueBinding.h"
#import "AppKit/NSMenuView.h"
#import "AppKit/NSMenuItemCell.h"
#import "AppKit/NSOutlineView.h"
#import "AppKit/NSParagraphStyle.h"
#import "AppKit/NSPopUpButtonCell.h"
#import "AppKit/NSProgressIndicator.h"
#import "AppKit/NSScroller.h"
#import "AppKit/NSScrollView.h"
#import "AppKit/NSStringDrawing.h"
#import "AppKit/NSTableView.h"
#import "AppKit/NSTableCellView.h"
#import "AppKit/NSTableColumn.h"
#import "AppKit/NSTableHeaderCell.h"
#import "AppKit/NSTableHeaderView.h"
#import "AppKit/NSTableView.h"
#import "AppKit/NSView.h"
#import "AppKit/NSTabView.h"
#import "AppKit/NSTabViewItem.h"
#import "AppKit/PSOperators.h"
#import "AppKit/NSSliderCell.h"
#import "AppKit/NSPathCell.h"
#import "AppKit/NSPathControl.h"
#import "AppKit/NSPathComponentCell.h"

#import "GNUstepGUI/GSToolbarView.h"
#import "GNUstepGUI/GSTitleView.h"
#import "GSBindingHelpers.h"

/* a border width of 5 gives a reasonable compromise between Cocoa metrics and looking good */
/* 7.0 gives us the NeXT Look (which is 8 pix wide including the shadow) */
#define COLOR_WELL_BORDER_WIDTH 3.0

@interface NSTableView (Private)
- (CGFloat *)_columnOrigins;
- (void) _willDisplayCell: (NSCell*)cell
	   forTableColumn: (NSTableColumn *)tb
		      row: (NSInteger)index;
- (id)_objectValueForTableColumn: (NSTableColumn *)tb
			     row: (NSInteger)index;
- (void) _calculatedStartingColumn: (NSInteger *)startingColumn
		      endingColumn: (NSInteger *)endingColumn
			inClipRect: (NSRect)clipRect;
@end

@interface NSCell (Private)
- (void) _setInEditing: (BOOL)flag;
- (BOOL) _inEditing;
- (void) _drawEditorWithFrame: (NSRect)cellFrame
                       inView: (NSView *)controlView;
- (void) _drawAttributedText: (NSAttributedString*)aString
                     inFrame: (NSRect)aRect;
@end

@implementation	GSDefaultTheme (Drawing)
- (void) setKeyEquivalent: (NSString *)key
            forButtonCell: (NSButtonCell *)cell
{
/* Default actions use an accent pill, without the old return-arrow bitmap. */
}

- (void) drawButton: (NSRect)frame
                 in: (NSCell*)cell
               view: (NSView*)view
              style: (int)style
              state: (GSThemeControlState)state
{
NSString *part = [self nameForElement:cell];
  if ([part isEqual:GSScrollerHorizontalKnob] || [part isEqual:GSScrollerVerticalKnob])
    { MacRound(NSInsetRect(frame,2,2), 20, MacGray(0.56), nil); return; }
  BOOL pressed = MacPressed(state);
  BOOL enabled = [cell isEnabled];
  BOOL primary = [cell isKindOfClass:[NSButtonCell class]]
    && ([[(NSButtonCell *)cell keyEquivalent] isEqual:@"\r"]
      || [[(NSButtonCell *)cell keyEquivalent] isEqual:@"\n"]);
  NSColor *fill = primary && enabled ? MacAccent() : MacGray(pressed ? 0.87 : 1);
  if ([cell isKindOfClass:[NSButtonCell class]] && [(NSButtonCell *)cell bezelColor])
    fill = [(NSButtonCell *)cell bezelColor];
  if (!enabled) fill=MacGray(0.94);
  if (primary && pressed) fill=[fill blendedColorWithFraction:0.15 ofColor:MacGray(0)];
  CGFloat radius = style==NSCircularBezelStyle || style==NSHelpButtonBezelStyle
    ? MIN(NSWidth(frame),NSHeight(frame))/2 : MIN(9,NSHeight(frame)/2);
  MacRound(NSInsetRect(frame,1,1), radius, fill, primary && enabled ? fill : MacBorder());
  if (style==NSHelpButtonBezelStyle)
    { NSDictionary *a=@{NSFontAttributeName:[NSFont systemFontOfSize:13],NSForegroundColorAttributeName:MacGray(0.2)};
      NSSize s=[@"?" sizeWithAttributes:a];
      [@"?" drawAtPoint:NSMakePoint(NSMidX(frame)-s.width/2,NSMidY(frame)-s.height/2) withAttributes:a]; }
}

- (BOOL) drawTextFieldCell: (NSTextFieldCell*)cell
                   frame: (NSRect)frame
                    view: (NSView*)view
{
if (![cell isBezeled] || ![cell drawsBackground]) return NO;
  NSColor *background=[cell backgroundColor];
  if (background && ![background isEqual:[NSColor textBackgroundColor]]
      && ![background isEqual:[NSColor controlBackgroundColor]]) return NO;
  BOOL focused = [[view window] firstResponder] == view
    || ([[view window] fieldEditor:NO forObject:view] == [[view window] firstResponder]
      && [[view window] firstResponder] != nil
      && [(NSTextView *)[[view window] firstResponder] delegate] == (id)view);
  MacRound(NSInsetRect(frame,1,1),6,[cell isEnabled] ? MacGray(1) : MacGray(0.96),
    focused ? MacAccent() : MacBorder());
  if (focused) [self drawFocusFrame:frame view:view];
  return YES;
}

- (NSRect) textFieldContentRectForCell: (NSTextFieldCell*)cell
                               frame: (NSRect)frame
{
if (![cell isBezeled] || ![cell drawsBackground]) return NSZeroRect;
  NSColor *background=[cell backgroundColor];
  if (background && ![background isEqual:[NSColor textBackgroundColor]]
    && ![background isEqual:[NSColor controlBackgroundColor]]) return NSZeroRect;
  NSRect r=NSInsetRect(frame,7,3);
  CGFloat h=ceil([[cell font] ascender]-[[cell font] descender]);
  if (h<NSHeight(r)) { r.origin.y+=(NSHeight(r)-h)/2; r.size.height=h; }
  return r;
}

- (GSThemeMargins) buttonMarginsForCell: (NSCell*)cell
				  style: (int)style
				  state: (GSThemeControlState)state
{
GSThemeMargins m={6,6,6,6}; return m;
}

- (NSSize) buttonPushInOffsetForCell: (NSCell*)cell
{
return NSZeroSize;
}

- (void) drawFocusFrame: (NSRect) frame view: (NSView*) view
{
NSBezierPath *p=[NSBezierPath bezierPathWithRoundedRect:NSInsetRect(frame,1.5,1.5) xRadius:8 yRadius:8];
  [[MacAccent() colorWithAlphaComponent:0.35] set]; [p setLineWidth:3]; [p stroke];
}

- (void) drawWindowBackground: (NSRect) frame view: (NSView*) view
{
  NSColor *c;

  c = [[view window] backgroundColor];
  [c set];
  NSRectFill (frame);
}

- (void) drawBorderType: (NSBorderType)aType
                  frame: (NSRect)frame
                   view: (NSView*)view
{
if (aType!=NSNoBorder) MacRound(frame,aType==NSLineBorder ? 0 : 6,nil,MacBorder());
}

- (NSSize) sizeForBorderType: (NSBorderType)aType
{
return aType==NSNoBorder ? NSZeroSize : NSMakeSize(1,1);
}

- (void) drawBorderForImageFrameStyle: (NSImageFrameStyle)frameStyle
                                frame: (NSRect)frame
                                 view: (NSView*)view
{
if (frameStyle!=NSImageFrameNone) MacRound(frame,6,nil,MacBorder());
}

- (NSSize) sizeForImageFrameStyle: (NSImageFrameStyle)frameStyle
{
  // Get border size
  switch (frameStyle)
    {
      case NSImageFrameNone:
      default:
        return NSZeroSize;
      case NSImageFramePhoto:
        // FIXME
        return NSMakeSize(2, 2);
      case NSImageFrameGrayBezel:
      case NSImageFrameGroove:
      case NSImageFrameButton:
        return NSMakeSize(2, 2);
    }
}


/* NSScroller themeing.
 */
- (BOOL) scrollerArrowsSameEndForScroller: (NSScroller *)aScroller
{
return NO;
}

- (BOOL) scrollerScrollsByPageForScroller: (NSScroller *)aScroller
{
  NSUserDefaults *defs = [NSUserDefaults standardUserDefaults];

  if ([defs objectForKey: @"GSScrollerScrollsByPage"] != nil)
    {
      return [defs boolForKey: @"GSScrollerScrollsByPage"];
    }
  else
    {
      NSInterfaceStyle interfaceStyle =
	NSInterfaceStyleForKey(@"NSScrollerInterfaceStyle", aScroller);

      if (interfaceStyle == NSNextStepInterfaceStyle
	  || interfaceStyle == NSMacintoshInterfaceStyle
	  || interfaceStyle == GSWindowMakerInterfaceStyle)
	{
	  /* NeXTstep style is to scroll to point.
	   */
	  return NO;
	}
      else
	{
	  /* Windows style is to scroll by a page.
	   */
	  return YES;
	}
    }
}

- (NSButtonCell*) cellForScrollerArrow: (NSScrollerArrow)arrow
			    horizontal: (BOOL)horizontal
{
  NSButtonCell	*cell;
  NSString	*name;

  cell = [NSButtonCell new];
  if (horizontal)
    {
      if (arrow == NSScrollerDecrementArrow)
	{
	  [cell setHighlightsBy:
	    NSChangeBackgroundCellMask | NSContentsCellMask];
	  [cell setImage: [NSImage imageNamed: @"common_ArrowLeft"]];
	  [cell setAlternateImage: [NSImage imageNamed: @"common_ArrowLeftH"]];
	  [cell setImagePosition: NSImageOnly];
          name = GSScrollerLeftArrow;
	}
      else
	{
	  [cell setHighlightsBy:
	    NSChangeBackgroundCellMask | NSContentsCellMask];
	  [cell setImage: [NSImage imageNamed: @"common_ArrowRight"]];
	  [cell setAlternateImage: [NSImage imageNamed: @"common_ArrowRightH"]];
	  [cell setImagePosition: NSImageOnly];
          name = GSScrollerRightArrow;
	}
    }
  else
    {
      if (arrow == NSScrollerDecrementArrow)
	{
	  [cell setHighlightsBy:
	    NSChangeBackgroundCellMask | NSContentsCellMask];
	  [cell setImage: [NSImage imageNamed: @"common_ArrowUp"]];
	  [cell setAlternateImage: [NSImage imageNamed: @"common_ArrowUpH"]];
	  [cell setImagePosition: NSImageOnly];
          name = GSScrollerUpArrow;
	}
      else
	{
	  [cell setHighlightsBy:
	    NSChangeBackgroundCellMask | NSContentsCellMask];
	  [cell setImage: [NSImage imageNamed: @"common_ArrowDown"]];
	  [cell setAlternateImage: [NSImage imageNamed: @"common_ArrowDownH"]];
	  [cell setImagePosition: NSImageOnly];
          name = GSScrollerDownArrow;
	}
    }
  [self setName: name forElement: cell temporary: YES];
  RELEASE(cell);
  return cell;
}

- (NSCell*) cellForScrollerKnob: (BOOL)horizontal
{
NSButtonCell *cell=[NSButtonCell new];
  [cell setTitle:@""]; [cell setImage:nil];
  [self setName:horizontal ? GSScrollerHorizontalKnob : GSScrollerVerticalKnob forElement:cell temporary:YES];
  [cell release]; return cell;
}

- (NSCell*) cellForScrollerKnobSlot: (BOOL)horizontal
{
  GSDrawTiles   *tiles;
  NSButtonCell	*cell;
  NSColor	*color;
  NSString      *name;

  if (horizontal)
    {
      name = GSScrollerHorizontalSlot;
    }
  else
    {
      name = GSScrollerVerticalSlot;
    }

  tiles = [self tilesNamed: name state: GSThemeNormalState];
  color = [self colorNamed: name state: GSThemeNormalState];

  cell = [NSButtonCell new];
  [cell setBordered: (tiles != nil)];
  [cell setTitle: nil];

  [self setName: name forElement: cell temporary: YES];

  if (color == nil)
    {
      color = [NSColor scrollBarColor];
    }
  [cell setBackgroundColor: color];
  RELEASE(cell);
  return cell;
}

- (float) defaultScrollerWidth
{
return 12;
}

- (BOOL) scrollViewUseBottomCorner
{
return NO;
}

- (BOOL) scrollViewScrollersOverlapBorders
{
return NO;
}

- (NSColor *) toolbarBackgroundColor
{
return MacGray(0.95);
}

- (NSColor *) toolbarBorderColor
{
return MacGray(0.83);
}

- (NSColor *) badgeBackgroundColor
{
return MacAccent();
}

- (NSColor *) badgeDecorationColor
{
return MacAccent();
}

- (NSColor *) badgeTextColor
{
return MacGray(1);
}

- (void) drawToolbarRect: (NSRect)aRect
                   frame: (NSRect)viewFrame
              borderMask: (unsigned int)borderMask
{
  // We draw the background
  [[self toolbarBackgroundColor] set];
  [NSBezierPath fillRect: aRect];

  // We draw the border
  [[self toolbarBorderColor] set];
  if (borderMask & GSToolbarViewBottomBorder)
    {
      [NSBezierPath strokeLineFromPoint: NSMakePoint(0, 0.5)
                    toPoint: NSMakePoint(viewFrame.size.width, 0.5)];
    }
  if (borderMask & GSToolbarViewTopBorder)
    {
      [NSBezierPath strokeLineFromPoint: NSMakePoint(0,
                                                     viewFrame.size.height - 0.5)
                    toPoint: NSMakePoint(viewFrame.size.width,
                                         viewFrame.size.height -  0.5)];
    }
  if (borderMask & GSToolbarViewLeftBorder)
    {
      [NSBezierPath strokeLineFromPoint: NSMakePoint(0.5, 0)
                    toPoint: NSMakePoint(0.5, viewFrame.size.height)];
    }
  if (borderMask & GSToolbarViewRightBorder)
    {
      [NSBezierPath strokeLineFromPoint: NSMakePoint(viewFrame.size.width - 0.5,0)
                    toPoint: NSMakePoint(viewFrame.size.width - 0.5,
                                         viewFrame.size.height)];
    }
}

- (BOOL) toolbarIsOpaque
{
  if ([[self toolbarBackgroundColor] alphaComponent] < 1.0)
    {
      return NO;
    }
  else
    {
      return YES;
    }
}

- (NSRect) stepperUpButtonRectWithFrame: (NSRect)frame
{
return NSMakeRect(NSMinX(frame),NSMidY(frame),NSWidth(frame),NSHeight(frame)/2);
}

- (NSRect) stepperDownButtonRectWithFrame: (NSRect)frame
{
return NSMakeRect(NSMinX(frame),NSMinY(frame),NSWidth(frame),NSHeight(frame)/2);
}

- (void) drawStepperBorder: (NSRect)frame
{
MacRound(frame,6,MacGray(1),MacBorder());
}

- (NSRect) drawStepperLightButton: (NSRect)border : (NSRect)clip
{
MacRound(border,6,MacGray(1),MacBorder()); return NSInsetRect(border,1,1);
}

- (void) drawStepperUpButton: (NSRect)aRect
{
MacChevron(aRect,YES,[[NSView focusView] isFlipped],MacGray(0.25));
}

- (void) drawStepperHighlightUpButton: (NSRect)aRect
{
MacRound(aRect,4,MacGray(0.86),nil); [self drawStepperUpButton:aRect];
}

- (void) drawStepperDownButton: (NSRect)aRect
{
MacChevron(aRect,NO,[[NSView focusView] isFlipped],MacGray(0.25));
}

- (void) drawStepperHighlightDownButton: (NSRect)aRect
{
MacRound(aRect,4,MacGray(0.86),nil); [self drawStepperDownButton:aRect];
}

- (void) drawStepperCell: (NSCell*)cell
               withFrame: (NSRect)cellFrame
                  inView: (NSView*)controlView
             highlightUp: (BOOL)highlightUp
           highlightDown: (BOOL)highlightDown
{
[self drawStepperBorder:cellFrame];
  NSRect top=NSMakeRect(NSMinX(cellFrame),NSMinY(cellFrame),NSWidth(cellFrame),NSHeight(cellFrame)/2);
  NSRect bottom=top; bottom.origin.y+=NSHeight(top);
  NSRect up=[controlView isFlipped] ? top : bottom;
  NSRect down=[controlView isFlipped] ? bottom : top;
  if (highlightUp) [self drawStepperHighlightUpButton:up]; else [self drawStepperUpButton:up];
  if (highlightDown) [self drawStepperHighlightDownButton:down]; else [self drawStepperDownButton:down];
  MacLine(NSMakePoint(NSMinX(cellFrame)+2,NSMidY(cellFrame)),NSMakePoint(NSMaxX(cellFrame)-2,NSMidY(cellFrame)),MacGray(0.85),1);
}

// NSSwitch drawing methods

- (void) drawSwitchBezel: (NSRect)frame
                forState: (NSControlStateValue)v
                 enabled: (BOOL)enabled
{
MacRound(NSInsetRect(frame,3,3),NSHeight(frame)/2,
    enabled && v!=NSControlStateValueOff ? MacAccent() : MacGray(enabled ? 0.77 : 0.87),nil);
}

- (void) drawSwitchKnob: (NSRect)frame
               forState: (NSControlStateValue)value
                enabled: (BOOL)enabled
{
NSRect track=NSInsetRect(frame,3,3); CGFloat d=MAX(0,NSHeight(track)-4);
  NSRect knob=NSMakeRect(value==NSControlStateValueOff ? NSMinX(track)+2 : NSMaxX(track)-d-2,
    NSMinY(track)+2,d,d);
  MacRound(knob,d/2,MacGray(enabled ? 1 : 0.96),nil);
}

- (void) drawSwitchInRect: (NSRect)rect
                 forState: (NSControlStateValue)state
                  enabled: (BOOL)enabled
{
  // Draw the well bezel
  [self drawSwitchBezel: rect
               forState: state
                enabled: enabled];

  // Draw the knob
  [self drawSwitchKnob: rect
              forState: state
               enabled: enabled];

}

// NSPathComponentCell

- (void) drawPathComponentCellWithFrame: (NSRect)frame
                                 inView: (NSPathControl *)pc
                               withCell: (NSPathComponentCell *)cell
                        isLastComponent: (BOOL)last
{
  NSImage *img = [cell image];
  NSURL *url = [cell URL];
  NSString *string = [cell stringValue];
  NSRect textFrame = frame;
  NSRect imgFrame = frame;
  NSRect arrowFrame = frame;
  NSImage *arrowImage = [NSImage imageNamed: @"NSMenuArrow"];
  NSPathStyle style= [pc pathStyle];
  NSRect newFrame = frame;

  if ([string length] == 0)
    {
      string = [[url path] lastPathComponent];
    }

  if (style == NSPathStylePopUp)
    {
      newFrame = [pc frame];

      // Reset coodinates.
      newFrame.origin.x = 0.0;
      newFrame.origin.y = 0.0;

      // Use control frame...
      textFrame = newFrame;
      imgFrame = newFrame;
      arrowFrame = newFrame;
    }

  // Modify positions...
  imgFrame.size.width = 17.0;
  imgFrame.size.height = 17.0;
  imgFrame.origin.x += 2.0;
  imgFrame.origin.y += 2.0;
  textFrame.origin.x += imgFrame.size.width + 5.0; // the width of the image plus a few pixels.
  textFrame.origin.y += 5.0; // center with the image...
  arrowFrame.origin.x += newFrame.size.width - 17.0;
  arrowFrame.size.width = 8.0;
  arrowFrame.size.height = 8.0;
  arrowFrame.origin.y += 5.0;

  if (style== NSPathStyleStandard || style== NSPathStyleNavigationBar)
    {
      /* Icon and title centred in the component, a chevron separating it
       * from the next one; the title is truncated to the room left. */
      NSFont *font = [cell font] ? [cell font] : [NSFont systemFontOfSize: 0];
      NSMutableParagraphStyle *paragraph = [[[NSMutableParagraphStyle alloc] init] autorelease];
      NSDictionary *attributes;
      CGFloat separator = last ? 0.0 : 14.0;
      CGFloat x = NSMinX(frame) + 4.0;
      NSSize textSize;
      NSRect textRect;

      [paragraph setLineBreakMode: NSLineBreakByTruncatingTail];
      attributes = [NSDictionary dictionaryWithObjectsAndKeys:
        font, NSFontAttributeName,
        [NSColor controlTextColor], NSForegroundColorAttributeName,
        paragraph, NSParagraphStyleAttributeName, nil];
      if (img != nil)
        {
          [img drawInRect: NSMakeRect(x, floor(NSMidY(frame) - 8.0), 16.0, 16.0)
                 fromRect: NSZeroRect
                operation: NSCompositeSourceOver
                 fraction: 1.0
           respectFlipped: YES
                    hints: nil];
          x += 20.0;
        }
      textSize = [string sizeWithAttributes: attributes];
      textRect = NSMakeRect(x, floor(NSMidY(frame) - textSize.height / 2.0),
                            MAX(0.0, NSMaxX(frame) - separator - x - 2.0), textSize.height);
      [string drawInRect: textRect withAttributes: attributes];

      if (last == NO)
        {
          NSBezierPath *chevron = [NSBezierPath bezierPath];
          CGFloat cx = NSMaxX(frame) - 9.0;

          [chevron moveToPoint: NSMakePoint(cx - 2.0, NSMidY(frame) - 4.0)];
          [chevron lineToPoint: NSMakePoint(cx + 2.0, NSMidY(frame))];
          [chevron lineToPoint: NSMakePoint(cx - 2.0, NSMidY(frame) + 4.0)];
          [chevron setLineWidth: 1.2];
          [[NSColor disabledControlTextColor] set];
          [chevron stroke];
        }
    }
  else if (style == NSPathStylePopUp)
    {
      if (last == YES)
        {
          arrowImage = [NSImage imageNamed: @"common_ArrowDown"];

          // Draw border...
          [[NSColor controlShadowColor] set];
          NSFrameRectWithWidth(newFrame, 1.0);

          // Draw the image...
          [img drawInRect: imgFrame];

          // Draw the text...
          [[NSColor textColor] set];
          [string drawAtPoint: textFrame.origin
               withAttributes: nil];

          // Draw the arrow...
          [arrowImage drawInRect: arrowFrame];
        }
    }
}

// NSSegmentedControl drawing methods

- (void) drawSegmentedControlSegment: (NSCell *)cell
                           withFrame: (NSRect)cellFrame
                              inView: (NSView *)controlView
                               style: (NSSegmentStyle)style
                               state: (GSThemeControlState)state
                         roundedLeft: (BOOL)roundedLeft
                        roundedRight: (BOOL)roundedRight
{
BOOL selected=state==GSThemeSelectedState || state==GSThemeSelectedFirstResponderState;
  MacRound(cellFrame,6,MacGray(0.89),nil);
  if (selected || MacPressed(state)) MacRound(NSInsetRect(cellFrame,2,2),5,MacGray(selected ? 1 : 0.95),MacGray(0.82));
}

- (NSColor *) menuBackgroundColor
{
return MacGray(0.98);
}

- (NSColor *) menuItemBackgroundColor
{
return MacGray(0.98);
}

- (NSColor *) menuBorderColor
{
return MacGray(0.8);
}

- (CGFloat) menuBorderRadius
{
return 10;
}

- (NSColor *) menuBarBackgroundColor
{
return MacGray(0.95);
}

- (NSColor *) menuBarBorderColor
{
return MacGray(0.84);
}

- (NSColor *) menuBorderColorForEdge: (NSRectEdge)edge isHorizontal: (BOOL)horizontal
{
  if (horizontal && edge == NSMinYEdge)
    {
      return [self menuBorderColor];
    }
  else if (edge == NSMinXEdge || edge == NSMaxYEdge)
    {
      // Draw the dark gray upper left lines.
      return [self menuBorderColor];
    }
  return nil;
}

- (void) drawBackgroundForMenuView: (NSMenuView*)menuView
                         withFrame: (NSRect)bounds
                         dirtyRect: (NSRect)dirtyRect
                        horizontal: (BOOL)horizontal
{
[NSGraphicsContext saveGraphicsState]; NSRectClip(dirtyRect);
  if (horizontal) { [[self menuBarBackgroundColor] set]; NSRectFill(bounds); }
  else MacRound(bounds,10,[self menuBackgroundColor],[self menuBorderColor]);
  [NSGraphicsContext restoreGraphicsState];
}

- (BOOL) drawsBorderForMenuItemCell: (NSMenuItemCell *)cell
                              state: (GSThemeControlState)state
                       isHorizontal: (BOOL)horizontal
{
return NO;
}

- (void) drawBorderAndBackgroundForMenuItemCell: (NSMenuItemCell *)cell
                                      withFrame: (NSRect)cellFrame
                                         inView: (NSView *)controlView
                                          state: (GSThemeControlState)state
                                   isHorizontal: (BOOL)isHorizontal
{
if (MacPressed(state)) MacRound(NSInsetRect(cellFrame,1,1),5,MacAccent(),nil);
}

- (NSColor *) menuSeparatorColor
{
return MacGray(0.85);
}

- (CGFloat) menuSeparatorInset
{
return 10;
}

- (CGFloat) menuSubmenuHorizontalOverlap
{
  return [[NSUserDefaults standardUserDefaults]
    floatForKey: @"GSMenuSubmenuHorizontalOverlap"];
}

- (CGFloat) menuSubmenuVerticalOverlap
{
  return [[NSUserDefaults standardUserDefaults]
    floatForKey: @"GSMenuSubmenuVerticalOverlap"];
}

- (void) drawSeparatorItemForMenuItemCell: (NSMenuItemCell *)cell
                                withFrame: (NSRect)cellFrame
                                   inView: (NSView *)controlView
                             isHorizontal: (BOOL)isHorizontal
{
  GSDrawTiles *tiles;

  tiles = [self tilesNamed: GSMenuSeparatorItem state: GSThemeNormalState];
  if (tiles == nil)
    {
      NSBezierPath *path = [NSBezierPath bezierPath];
      CGFloat inset = [self menuSeparatorInset];
      NSPoint start = NSMakePoint(inset, cellFrame.size.height / 2 +
				         cellFrame.origin.y + 0.5);
      NSPoint end = NSMakePoint(cellFrame.size.width - inset,
        cellFrame.size.height / 2 + cellFrame.origin.y + 0.5);

      [[self menuSeparatorColor] set];

      [path setLineWidth: 0.0];
      [path moveToPoint: start];
      [path lineToPoint: end];

      [path stroke];
    }
  else
    {
      [self fillRect: cellFrame
           withTiles: tiles];
    }
}

- (void) drawTitleForMenuItemCell: (NSMenuItemCell *)cell
                        withFrame: (NSRect)cellFrame
                           inView: (NSView *)controlView
                            state: (GSThemeControlState)state
                     isHorizontal: (BOOL)isHorizontal
{
  [cell _drawText: [[cell menuItem] title]
          inFrame: [cell titleRectForBounds: cellFrame]];
}

- (Class) titleViewClassForMenuView: (NSMenuView *)aMenuView
{
  return [GSTitleView class];
}

- (NSRect) drawMenuTitleBackground: (GSTitleView *)aTitleView
			withBounds: (NSRect)bounds
			  withClip: (NSRect)clipRect
{
NSRect r=[aTitleView bounds]; MacRound(r,8,MacGray(0.95),MacBorder()); return NSInsetRect(r,8,3);
}

- (CGFloat) menuBarHeight
{
return 28;
}

- (CGFloat) menuItemHeight
{
return 25;
}

- (CGFloat) menuSeparatorHeight
{
return 9;
}

- (CGFloat) menuItemBackgroundRadius
{
return 5;
}

- (NSEdgeInsets) menuItemAreaInsets
{
NSEdgeInsets i={5,5,5,5}; return i;
}

// NSColorWell drawing method
- (NSRect) drawColorWellBorder: (NSColorWell*)well
                    withBounds: (NSRect)bounds
                      withClip: (NSRect)clipRect
{
if ([well isBordered]) MacRound(bounds,6,MacGray(1),[well isActive] ? MacAccent() : MacBorder());
  return NSInsetRect(bounds,[well isBordered] ? 4 : 0,[well isBordered] ? 4 : 0);
}

// progress indicator drawing methods

- (void) initProgressIndicatorDrawing
{
/* Progress is drawn procedurally at every scale. */
}

- (void) drawProgressIndicator: (NSProgressIndicator*)progress
                    withBounds: (NSRect)bounds
                      withClip: (NSRect)rect
                       atCount: (int)count
                      forValue: (double)val
{
[NSGraphicsContext saveGraphicsState]; NSRectClip(rect);
  if ([progress style]==NSProgressIndicatorSpinningStyle)
    {
      CGFloat radius=MAX(1,MIN(NSWidth(bounds),NSHeight(bounds))/2-3);
      for (int i=0;i<12;i++) {
        CGFloat a=(i*30-90)*M_PI/180;
        CGFloat shade=0.25+0.6*((i+12-count%12)%12)/11.0;
        MacLine(NSMakePoint(NSMidX(bounds)+cos(a)*radius*0.55,NSMidY(bounds)+sin(a)*radius*0.55),
          NSMakePoint(NSMidX(bounds)+cos(a)*radius,NSMidY(bounds)+sin(a)*radius),MacGray(shade),2);
      }
    }
  else {
    BOOL vertical=[progress isVertical]; CGFloat thickness=MIN(6,vertical ? NSWidth(bounds) : NSHeight(bounds));
    NSRect track=vertical ? NSMakeRect(NSMidX(bounds)-thickness/2,NSMinY(bounds),thickness,NSHeight(bounds))
      : NSMakeRect(NSMinX(bounds),NSMidY(bounds)-thickness/2,NSWidth(bounds),thickness);
    MacRound(track,thickness/2,MacGray(0.86),nil);
    NSBezierPath *clipPath=[NSBezierPath bezierPathWithRoundedRect:track xRadius:thickness/2 yRadius:thickness/2];
    [clipPath addClip]; NSRect fill=track;
    CGFloat fraction=MAX(0,MIN(1,val));
    if ([progress isIndeterminate]) {
      fraction=0.3; CGFloat phase=(count%60)/59.0;
      if (vertical) fill.origin.y+=NSHeight(track)*(phase*1.3-0.3);
      else fill.origin.x+=NSWidth(track)*(phase*1.3-0.3);
    }
    if (vertical) { fill.size.height*=fraction; if (![progress isIndeterminate] && [progress isFlipped]) fill.origin.y=NSMaxY(track)-NSHeight(fill); }
    else fill.size.width*=fraction;
    MacRound(fill,thickness/2,MacAccent(),nil);
  }
  [NSGraphicsContext restoreGraphicsState];
}

- (NSRect) drawProgressIndicatorBezel: (NSRect)bounds withClip: (NSRect) rect
{
MacRound(bounds,NSHeight(bounds)/2,MacGray(0.86),nil); return NSInsetRect(bounds,1,1);
}

- (void) drawProgressIndicatorBarDeterminate: (NSRect)bounds
{
MacRound(bounds,MIN(NSWidth(bounds),NSHeight(bounds))/2,MacAccent(),nil);
}

// Table drawing methods

- (NSColor *) tableHeaderTextColorForState: (GSThemeControlState)state
{
return MacGray(0.4);
}

- (void) drawTableCornerView: (NSView*)cornerView
                   withClip: (NSRect)aRect
{
[MacGray(0.95) set]; NSRectFill(aRect);
}

- (void) drawTableHeaderCell: (NSTableHeaderCell *)cell
                   withFrame: (NSRect)cellFrame
                      inView: (NSView *)controlView
                       state: (GSThemeControlState)state
{
[MacGray(MacPressed(state) ? 0.9 : 0.95) set]; NSRectFill(cellFrame);
  CGFloat y=[controlView isFlipped] ? NSMaxY(cellFrame)-0.5 : NSMinY(cellFrame)+0.5;
  MacLine(NSMakePoint(NSMinX(cellFrame),y),NSMakePoint(NSMaxX(cellFrame),y),MacGray(0.84),1);
}


// Window decoration drawing methods
/* These include the black border. */
#define TITLE_HEIGHT 32.0
#define RESIZE_HEIGHT 1.0
#define RESIZE_NOTCH_WIDTH 30.0
#define TITLEBAR_BUTTON_SIZE 14.0
#define TITLEBAR_PADDING_TOP 9.0
#define TITLEBAR_PADDING_RIGHT 4.0
#define TITLEBAR_PADDING_LEFT 12.0

- (float) titlebarHeight
{
  return TITLE_HEIGHT;
}

- (float) resizebarHeight
{
  return RESIZE_HEIGHT;
}

- (float) resizebarNotchWidth
{
  return RESIZE_NOTCH_WIDTH;
}

- (float) titlebarButtonSize
{
  return TITLEBAR_BUTTON_SIZE;
}

- (float) titlebarPaddingRight
{
  return TITLEBAR_PADDING_RIGHT;
}

- (float) titlebarPaddingTop
{
  return TITLEBAR_PADDING_TOP;
}

- (float) titlebarPaddingLeft
{
  return TITLEBAR_PADDING_LEFT;
}


- (void) drawTitleBarRect: (NSRect)titleBarRect
             forStyleMask: (unsigned int)styleMask
                    state: (int)inputState
                 andTitle: (NSString*)title
{
[MacGray(0.94) set]; NSRectFill(titleBarRect);
  MacLine(NSMakePoint(NSMinX(titleBarRect),NSMinY(titleBarRect)+0.5),NSMakePoint(NSMaxX(titleBarRect),NSMinY(titleBarRect)+0.5),MacGray(0.83),1);
  NSDictionary *a=@{NSFontAttributeName:[NSFont boldSystemFontOfSize:13],NSForegroundColorAttributeName:MacGray(inputState==0 ? 0.5 : 0.18)};
  NSSize size=[title sizeWithAttributes:a];
  NSRect text=NSMakeRect(MAX(NSMinX(titleBarRect)+80,NSMidX(titleBarRect)-size.width/2),NSMidY(titleBarRect)-size.height/2,MAX(0,NSWidth(titleBarRect)-160),size.height);
  [title drawInRect:text withAttributes:a];
}

// FIXME: Would be good if this took the window as a param
- (void) drawResizeBarRect: (NSRect)resizeBarRect
{
[MacGray(0.85) set]; NSRectFill(resizeBarRect);
}

- (void) drawWindowBorder: (NSRect)rect
                withFrame: (NSRect)frame
             forStyleMask: (unsigned int)styleMask
                    state: (int)inputState
                 andTitle: (NSString*)title
{
[NSGraphicsContext saveGraphicsState]; NSRectClip(rect);
  MacRound(frame,10,nil,MacGray(0.72));
  if (styleMask & NSTitledWindowMask) [self drawTitleBarRect:NSMakeRect(NSMinX(frame),NSMaxY(frame)-TITLE_HEIGHT,NSWidth(frame),TITLE_HEIGHT) forStyleMask:styleMask state:inputState andTitle:title];
  [NSGraphicsContext restoreGraphicsState];
}

- (void) setFrameForCloseButton: (NSButton *)closeButton
		       viewSize: (NSSize)viewSize
{
[closeButton setFrame:[self closeButtonFrameForBounds:NSMakeRect(0,0,viewSize.width,viewSize.height)]];
}

- (NSRect) closeButtonFrameForBounds: (NSRect)bounds
{
return NSMakeRect(NSMinX(bounds)+12,NSMaxY(bounds)-23,14,14);
}

- (NSRect) miniaturizeButtonFrameForBounds: (NSRect)bounds
{
return NSMakeRect(NSMinX(bounds)+34,NSMaxY(bounds)-23,14,14);
}

- (NSColor *) browserHeaderTextColor
{
return MacGray(0.4);
}

- (void) drawBrowserHeaderCell: (NSTableHeaderCell*)cell
                     withFrame: (NSRect)rect
			inView: (NSView*)view;
{
[self drawTableHeaderCell:cell withFrame:rect inView:view state:GSThemeNormalState];
}

- (NSRect) browserHeaderDrawingRectForCell: (NSTableHeaderCell*)cell
				 withFrame: (NSRect)rect
{
  GSDrawTiles *tiles;
  tiles = [self tilesNamed: GSBrowserHeader state: GSThemeNormalState];
  if (tiles == nil)
    {
      return NSInsetRect(rect, 2, 2);
    }
  else
    {
      const BOOL flipped = [[cell controlView] isFlipped];
      NSRect result = [tiles contentRectForRect: rect
				      isFlipped: flipped];
      return result;
    }
}

- (NSImage *)imageForTabPart: (GSTabPart)part type: (NSTabViewType)type
{
return nil;
}

- (GSDrawTiles *)tilesForTabPart: (GSTabPart)part type: (NSTabViewType)type
{
return nil;
}

- (void) frameTabRectTopAndBottom: (NSRect)aRect
			 topColor: (NSColor *)topColor
		      bottomColor: (NSColor *)bottomColor
{
/* Segmented tabs have no engraved top/bottom edges. */
}

- (void) drawTabFillInRect: (NSRect)aRect forPart: (GSTabPart)part type: (NSTabViewType)type
{
MacRound(aRect,6,MacGray(part==GSTabSelectedFill ? 1 : 0.9),nil);
}

- (CGFloat) tabHeightForType: (NSTabViewType)type
{
return (type==NSNoTabsBezelBorder || type==NSNoTabsLineBorder || type==NSNoTabsNoBorder) ? 0 : 28;
}

- (NSRect) tabViewBackgroundRectForBounds: (NSRect)aRect
			      tabViewType: (NSTabViewType)type
{
CGFloat h=[self tabHeightForType:type];
  if (type==NSLeftTabsBezelBorder) { aRect.origin.x+=92; aRect.size.width-=92; }
  else if (type==NSRightTabsBezelBorder) aRect.size.width-=92;
  else if (h>0) { if (type==NSTopTabsBezelBorder) aRect.origin.y+=h; aRect.size.height-=h; }
  return aRect;
}


- (NSRect) tabViewContentRectForBounds: (NSRect)aRect
			   tabViewType: (NSTabViewType)type
			       tabView: (NSTabView *)view
{
return NSInsetRect([self tabViewBackgroundRectForBounds:aRect tabViewType:type],6,6);
}


- (void) drawTabViewBezelRect: (NSRect)aRect
                  tabViewType: (NSTabViewType)type
                       inView: (NSView *)view
{
if (type!=NSNoTabsNoBorder) MacRound(aRect,8,MacGray(0.97),MacGray(0.84));
}

- (void) drawTabViewRect: (NSRect)rect
		  inView: (NSView *)view
	       withItems: (NSArray *)items
	    selectedItem: (NSTabViewItem *)selected
{
NSTabViewType type=[(NSTabView *)view tabViewType];
  NSRect bounds=[view bounds];
  [self drawTabViewBezelRect:[self tabViewBackgroundRectForBounds:bounds tabViewType:type] tabViewType:type inView:view];
  if ([self tabHeightForType:type]==0) return;
  BOOL vertical=type==NSLeftTabsBezelBorder || type==NSRightTabsBezelBorder;
  BOOL truncate=[(NSTabView *)view allowsTruncatedLabels];
  CGFloat total=0;
  for (NSTabViewItem *item in items) total+=vertical ? 28 : [item sizeOfLabel:truncate].width+24;
  CGFloat available=vertical ? NSHeight(bounds)-8 : NSWidth(bounds)-8;
  CGFloat scale=total>available && total>0 ? available/total : 1;
  CGFloat pos=vertical ? NSMinY(bounds)+4 : NSMidX(bounds)-total*scale/2;
  for (NSTabViewItem *item in items) {
    CGFloat length=(vertical ? 28 : [item sizeOfLabel:truncate].width+24)*scale;
    NSRect r;
    if (vertical) r=NSMakeRect(type==NSLeftTabsBezelBorder ? NSMinX(bounds)+4 : NSMaxX(bounds)-88,pos,84,length);
    else { BOOL top=type==NSTopTabsBezelBorder;
      CGFloat y=(top==[view isFlipped]) ? NSMinY(bounds)+2 : NSMaxY(bounds)-26;
      r=NSMakeRect(pos,y,length,24); }
    MacRound(r,6,MacGray(item==selected ? 1 : 0.9),item==selected ? MacBorder() : nil);
    [item drawLabel:truncate inRect:NSInsetRect(r,8,4)]; pos+=length;
  }
}

- (void) drawScrollerRect: (NSRect)rect
		   inView: (NSView *)view
		  hitPart: (NSScrollerPart)hitPart
	     isHorizontal: (BOOL)isHorizontal
{
NSScroller *scroller=(NSScroller *)view;
  [MacGray(0.96) set]; NSRectFill(NSIntersectionRect(rect,[view bounds]));
  NSRect knob=[scroller rectForPart:NSScrollerKnob];
  MacRound(NSInsetRect(knob,2,2),20,MacGray(hitPart==NSScrollerKnob ? 0.4 : 0.62),nil);
}

- (void) drawBrowserRect: (NSRect)rect
		  inView: (NSView *)view
	withScrollerRect: (NSRect)scrollerRect
	      columnSize: (NSSize)columnSize
{
  NSBrowser *browser = (NSBrowser *)view;
  NSRect bounds = [view bounds];

  // Load the first column if not already done
  if (![browser isLoaded])
    {
      [browser loadColumnZero];
    }

  // Draws titles
  if ([browser isTitled])
    {
      int i;

      for (i = [browser firstVisibleColumn];
	   i <= [browser lastVisibleColumn];
	   ++i)
        {
          NSRect titleRect = [browser titleFrameOfColumn: i];
          if (NSIntersectsRect (titleRect, rect) == YES)
            {
              [browser drawTitleOfColumn: i
                    inRect: titleRect];
            }
        }
    }

  // Draws scroller border

  if ([self browserUseBezels])
    {
      if ([browser hasHorizontalScroller] &&
	  [browser separatesColumns])
	{
	  NSRect scrollerBorderRect = scrollerRect;
	  NSSize bs = [self sizeForBorderType: NSBezelBorder];

	  scrollerBorderRect.origin.x = 0;
	  scrollerBorderRect.origin.y = 0;
	  scrollerBorderRect.size.width += 2 * bs.width;
	  scrollerBorderRect.size.height += (2 * bs.height) - 1;

	  if ((NSIntersectsRect (scrollerBorderRect, rect) == YES) && [view window])
	    {
	      [self drawGrayBezel: scrollerBorderRect withClip: rect];
	    }
	}

      if (![browser separatesColumns])
	{
	  NSPoint p1,p2;
	  int     i, visibleColumns;
	  float   hScrollerWidth = [browser hasHorizontalScroller] ?
	    [NSScroller scrollerWidth] : 0;

	  // Columns borders
	  [self drawGrayBezel: bounds withClip: rect];

	  [MacGray(0.83) set];
	  visibleColumns = [browser numberOfVisibleColumns];
	  for (i = 1; i < visibleColumns; i++)
	    {
	      p1 = NSMakePoint((columnSize.width * i) + 2 + (i-1),
                           columnSize.height + hScrollerWidth + 2);
	      p2 = NSMakePoint((columnSize.width * i) + 2 + (i-1),
			       hScrollerWidth + 2);
	      [NSBezierPath strokeLineFromPoint: p1 toPoint: p2];
	    }

	  // Horizontal scroller border
	  if ([browser hasHorizontalScroller])
	    {
	      p1 = NSMakePoint(2, hScrollerWidth + 2);
	      p2 = NSMakePoint(rect.size.width - 2, hScrollerWidth + 2);
	      [NSBezierPath strokeLineFromPoint: p1 toPoint: p2];
	    }
	}
    }

   if (![self browserUseBezels]
       && [self scrollViewScrollersOverlapBorders])
    {
      NSRect baseRect = NSMakeRect(0, 0, bounds.size.width, 1);
      NSRect colFrame = [browser frameOfColumn: [browser firstVisibleColumn]];
      NSRect scrollViewRect = NSUnionRect(baseRect, colFrame);

      GSDrawTiles *tiles = [self tilesNamed: @"NSScrollView"
				      state: GSThemeNormalState];

      [self fillRect: scrollViewRect
           withTiles: tiles];
    }
}

- (CGFloat) browserColumnSeparation
{
return 1;
}

- (CGFloat) browserVerticalPadding
{
return 0;
}

- (BOOL) browserUseBezels
{
return NO;
}

- (void) drawMenuRect: (NSRect)rect
	       inView: (NSView *)view
	 isHorizontal: (BOOL)horizontal
	    itemCells: (NSArray *)itemCells
{
  NSUInteger  i = 0;
  NSUInteger  howMany = [itemCells count];
  NSMenuView *menuView = (NSMenuView *)view;
  NSRect      bounds = [view bounds];

  [self drawBackgroundForMenuView: menuView
	withFrame: bounds
	dirtyRect: rect
	horizontal: horizontal];

  // Draw the menu cells.
  for (i = 0; i < howMany; i++)
    {
      NSRect aRect;
      NSMenuItemCell *aCell;

      aRect = [menuView rectOfItemAtIndex: i];
      if (NSIntersectsRect(rect, aRect) == YES)
        {
          aCell = [menuView menuItemCellForItemAtIndex: i];
          [aCell drawWithFrame: aRect inView: menuView];
        }
    }
}

- (void) drawScrollViewRect: (NSRect)rect
		     inView: (NSView *)view
{
  NSScrollView  *scrollView = (NSScrollView *)view;
  GSTheme	*theme = [GSTheme theme];
  NSColor	*color;
  NSString	*name;
  NSBorderType   borderType = [scrollView borderType];
  NSRect         bounds = [view bounds];
  BOOL hasInnerBorder = ![[NSUserDefaults standardUserDefaults]
			   boolForKey: @"GSScrollViewNoInnerBorder"];
  GSDrawTiles *tiles = nil;

  name = [theme nameForElement: self];
  if (name == nil)
    {
      name = @"NSScrollView";
    }
  color = [theme colorNamed: name state: GSThemeNormalState];
  tiles = [theme tilesNamed: name state: GSThemeNormalState];
  if (color == nil)
    {
      color = [NSColor controlDarkShadowColor];
    }

  if (tiles == nil)
    {
      switch (borderType)
	{
	case NSNoBorder:
	  break;

	case NSLineBorder:
	  [color set];
	  NSFrameRect(bounds);
	  break;

	case NSBezelBorder:
	  [theme drawGrayBezel: bounds withClip: rect];
	  break;

	case NSGrooveBorder:
	  [theme drawGroove: bounds withClip: rect];
	  break;
	}
    }
  else
    {
      [self fillRect: bounds
	   withTiles: tiles];
    }

  if (hasInnerBorder)
    {
      NSScroller *vertScroller = [scrollView verticalScroller];
      NSScroller *horizScroller = [scrollView horizontalScroller];
      CGFloat scrollerWidth = [NSScroller scrollerWidth];
      NSRect scrollerFrame;

      [color set];

      if ([scrollView hasVerticalScroller])
	{
	  NSInterfaceStyle style;
	  CGFloat xpos;

          scrollerFrame = [vertScroller frame];

	  style = NSInterfaceStyleForKey(@"NSScrollViewInterfaceStyle", nil);
	  if (style == NSMacintoshInterfaceStyle
	      || style == NSWindows95InterfaceStyle)
	    {
              xpos = scrollerFrame.origin.x - 1.0;
	    }
	  else
	    {
              xpos = scrollerFrame.origin.x + scrollerWidth;
	    }
          NSRectFill(NSMakeRect(xpos, scrollerFrame.origin.y,
                                1.0, scrollerFrame.size.height));
	}

      if ([scrollView hasHorizontalScroller])
	{
	  CGFloat ypos;

          scrollerFrame = [horizScroller frame];

	  if ([scrollView isFlipped])
	    {
	      ypos = scrollerFrame.origin.y - 1.0;
	    }
	  else
	    {
	      ypos = scrollerFrame.origin.y + scrollerWidth + 1.0;
	    }
          NSRectFill(NSMakeRect([horizScroller frame].origin.x, ypos,
                                scrollerFrame.size.width, 1.0));
	}
    }
}

- (void) drawSliderBorderAndBackground: (NSBorderType)aType
				 frame: (NSRect)cellFrame
				inCell: (NSCell *)cell
			  isHorizontal: (BOOL)horizontal
{
/* The track is drawn in drawBarInside:inCell:flipped:. */
}

- (void) drawBarInside: (NSRect)rect
		inCell: (NSCell *)cell
	       flipped: (BOOL)flipped
{
BOOL horizontal=NSWidth(rect)>NSHeight(rect);
  NSRect track=horizontal ? NSMakeRect(NSMinX(rect),NSMidY(rect)-2,NSWidth(rect),4)
    : NSMakeRect(NSMidX(rect)-2,NSMinY(rect),4,NSHeight(rect));
  MacRound(track,2,MacGray(0.8),nil);
  double span=[(NSSliderCell *)cell maxValue]-[(NSSliderCell *)cell minValue];
  double f=span>0 ? ([cell doubleValue]-[(NSSliderCell *)cell minValue])/span : 0;
  f=MAX(0,MIN(1,f)); NSRect fill=track;
  if (horizontal) fill.size.width*=f;
  else { fill.size.height*=f; if (flipped) fill.origin.y=NSMaxY(track)-NSHeight(fill); }
  MacRound(fill,2,[cell isEnabled] ? MacAccent() : MacGray(0.65),nil);
}

- (void) drawKnobInCell: (NSCell *)cell
{
NSRect r=[(NSSliderCell *)cell knobRectFlipped:[[cell controlView] isFlipped]];
  MacRound(NSInsetRect(r,0.5,0.5),MIN(NSWidth(r),NSHeight(r))/2,MacGray(1),MacBorder());
}

- (NSRect) tableHeaderCellDrawingRectForBounds: (NSRect)theRect
{
  NSSize borderSize;

  // This adjustment must match the drawn border
  borderSize = NSMakeSize(1, 1);

  return NSInsetRect(theRect, borderSize.width, borderSize.height);
}

- (void)drawTableHeaderRect: (NSRect)aRect
		     inView: (NSView *)view
{
  NSTableHeaderView *tableHeaderView = (NSTableHeaderView *)view;
  NSTableView *tableView = [tableHeaderView tableView];
  NSArray *columns;
  int firstColumnToDraw;
  int lastColumnToDraw;
  NSRect drawingRect;
  NSTableColumn *column;
  NSTableColumn *highlightedTableColumn;
  float width;
  int i;
  NSCell *cell;
  NSImage *indicatorImage;

  if (tableView == nil)
    return;

  firstColumnToDraw = [tableHeaderView columnAtPoint: NSMakePoint (aRect.origin.x,
                                                        aRect.origin.y)];
  if (firstColumnToDraw == -1)
    firstColumnToDraw = 0;

  lastColumnToDraw = [tableHeaderView columnAtPoint: NSMakePoint (NSMaxX (aRect),
                                                       aRect.origin.y)];
  if (lastColumnToDraw == -1)
    lastColumnToDraw = [tableView numberOfColumns] - 1;

  drawingRect = [tableHeaderView headerRectOfColumn: firstColumnToDraw];

  columns = [tableView tableColumns];
  highlightedTableColumn = [tableView highlightedTableColumn];

  for (i = firstColumnToDraw; i <= lastColumnToDraw; i++)
    {
      column = [columns objectAtIndex: i];
      width = [column width];
      drawingRect.size.width = width;
      cell = [column headerCell];
      if ((column == highlightedTableColumn)
          || [tableView isColumnSelected: i])
        {
          [cell setHighlighted: YES];
        }
      else
        {
          [cell setHighlighted: NO];
        }
      [cell drawWithFrame: drawingRect
                           inView: tableHeaderView];

      indicatorImage = [tableView indicatorImageInTableColumn: column];
      if (indicatorImage != nil)
        {
          NSSize size = [indicatorImage size];
          NSRect indicatorRect;

          indicatorRect.size = size;
          indicatorRect.origin.x = NSMaxX(drawingRect) - size.width - 4.0;
          indicatorRect.origin.y = drawingRect.origin.y
            + (drawingRect.size.height - size.height) / 2.0;
          [indicatorImage drawInRect: indicatorRect
                            fromRect: NSZeroRect
                           operation: NSCompositeSourceOver
                            fraction: 1.0
                      respectFlipped: YES
                               hints: nil];
        }
      drawingRect.origin.x += width;
    }
}

- (void) drawPopUpButtonCellInteriorWithFrame: (NSRect)cellFrame
				     withCell: (NSCell *)cell
				       inView: (NSView *)controlView
{
  // Default implementation of this method does nothing.
}

- (void) drawTableViewBackgroundInClipRect: (NSRect)aRect
				    inView: (NSView *)view
		       withBackgroundColor: (NSColor *)backgroundColor
{
  NSTableView *tableView = (NSTableView *)view;

  [backgroundColor set];
  NSRectFill (aRect);

  if ([tableView usesAlternatingRowBackgroundColors])
    {
      const CGFloat rowHeight = [tableView rowHeight];
      NSInteger startingRow = [tableView rowAtPoint: NSMakePoint(0, NSMinY(aRect))];
      NSInteger endingRow;
      NSInteger i;

      NSArray *rowColors = [NSColor controlAlternatingRowBackgroundColors];
      const NSUInteger rowColorCount = [rowColors count];

      NSRect rowRect;

      if (rowHeight <= 0
	  || rowColorCount == 0
	  || aRect.size.height <= 0)
	return;

      if (startingRow <= 0)
	startingRow = 0;

      rowRect = [tableView rectOfRow: startingRow];
      rowRect.origin.x = aRect.origin.x;
      rowRect.size.width = aRect.size.width;

      endingRow = startingRow + ceil(aRect.size.height / rowHeight);

      for (i = startingRow; i <= endingRow; i++)
	{
	  NSColor *color = [rowColors objectAtIndex: (i % rowColorCount)];

	  [color set];
	  NSRectFill(rowRect);

	  rowRect.origin.y += rowHeight;
	}
    }
}

- (void) drawTableViewGridInClipRect: (NSRect)aRect
			      inView: (NSView *)view
{
  NSTableView *tableView = (NSTableView *)view;

  // Cache some constants
  const CGFloat minX = NSMinX(aRect);
  const CGFloat maxX = NSMaxX(aRect);
  const CGFloat minY = NSMinY(aRect);
  const CGFloat maxY = NSMaxY(aRect);
  const NSInteger numberOfColumns = [tableView numberOfColumns];
  const NSInteger numberOfRows = [tableView numberOfRows];

  NSInteger startingRow = [tableView rowAtPoint: NSMakePoint(minX, minY)];
  NSInteger endingRow = [tableView rowAtPoint: NSMakePoint(minX, maxY)];
  NSInteger startingColumn = [tableView columnAtPoint: NSMakePoint(minX, minY)];
  NSInteger endingColumn = [tableView columnAtPoint: NSMakePoint(maxX, minY)];

  NSGraphicsContext *ctxt = GSCurrentContext();
  NSColor *gridColor = [tableView gridColor];


  if (startingRow == -1)
    startingRow = 0;
  if (endingRow == -1)
    endingRow = numberOfRows - 1;

  if (startingColumn == -1)
    startingColumn = 0;
  if (endingColumn == -1)
    endingColumn = numberOfColumns - 1;


  DPSgsave(ctxt);
  [gridColor set];

  // Draw horizontal lines
  if (numberOfRows > 0)
    {
      NSInteger i;
      for (i = startingRow; i <= endingRow; i++)
	{
	  NSRect rowRect = [tableView rectOfRow: i];
	  rowRect.origin.y += rowRect.size.height - 1;
	  rowRect.size.height = 1;
	  NSRectFill(rowRect);
	}
    }

  // Draw vertical lines
  if (numberOfColumns > 0)
    {
     NSInteger i;
      for (i = startingColumn; i <= endingColumn; i++)
	{
	  NSRect colRect = [tableView rectOfColumn: i];
	  colRect.origin.x += colRect.size.width - 1;
	  colRect.size.width = 1;
	  NSRectFill(colRect);
	}
    }

  DPSgrestore (ctxt);
}

- (void) drawTableViewRect: (NSRect)aRect
		    inView: (NSView *)view
{
  NSInteger startingRow;
  NSInteger endingRow;
  NSInteger i;
  NSTableView *tableView = (NSTableView *)view;
  NSInteger numberOfRows = [tableView numberOfRows];
  NSInteger numberOfColumns = [tableView numberOfColumns];
  BOOL drawsGrid = [tableView drawsGrid];

  /* Draw background */
  [tableView drawBackgroundInClipRect: aRect];

  if ((numberOfRows == 0) || (numberOfColumns == 0))
    {
      return;
    }

  /* Draw selection */
  [tableView highlightSelectionInClipRect: aRect];

  /* Draw grid */
  if (drawsGrid)
    {
      [tableView drawGridInClipRect: aRect];
    }

  /* Draw visible cells */
  /* Using rowAtPoint: here calls them only twice per drawn rect */
  startingRow = [tableView rowAtPoint: NSMakePoint (0, NSMinY (aRect))];
  endingRow   = [tableView rowAtPoint: NSMakePoint (0, NSMaxY (aRect))];

  if (startingRow == -1)
    {
      startingRow = 0;
    }
  if (endingRow == -1)
    {
      endingRow = numberOfRows - 1;
    }
  // NSLog(@"drawRect : %ld-%ld", startingRow, endingRow);
  {
    SEL sel = @selector(drawRow:clipRect:);
    void (*imp)(id, SEL, NSInteger, NSRect);

    imp = (void (*)(id, SEL, NSInteger, NSRect))[tableView methodForSelector: sel];

    for (i = startingRow; i <= endingRow; i++)
      {
        imp(tableView, sel, i, aRect);
      }
  }
}

- (void) highlightTableViewSelectionInClipRect: (NSRect)clipRect
					inView: (NSView *)view
			      selectingColumns: (BOOL)selectingColumns
{
  NSTableView *tableView = (NSTableView *)view;
  NSInteger numberOfRows = [tableView numberOfRows];
  NSInteger numberOfColumns = [tableView numberOfColumns];
  NSIndexSet *selectedRows = [tableView selectedRowIndexes];
  NSIndexSet *selectedColumns = [tableView selectedColumnIndexes];

  // Set the fill color
  {
    NSColor *selectionColor;

    selectionColor = [self colorNamed: @"highlightedTableRowBackgroundColor"
				state: GSThemeNormalState];

    if (selectionColor == nil)
      {
	selectionColor = MacAccent();
      }
    [selectionColor set];
  }

  if (selectingColumns == NO)
    {
      NSInteger selectedRowsCount;
      NSUInteger row;
      NSInteger startingRow, endingRow;

      selectedRowsCount = [selectedRows count];
      if (selectedRowsCount == 0)
	return;

      /* highlight selected rows */
      startingRow = [tableView rowAtPoint: NSMakePoint(0, NSMinY(clipRect))];
      endingRow   = [tableView rowAtPoint: NSMakePoint(0, NSMaxY(clipRect))];

      if (startingRow == -1)
	startingRow = 0;
      if (endingRow == -1)
	endingRow = numberOfRows - 1;

      row = [selectedRows indexGreaterThanOrEqualToIndex: startingRow];
      while ((row != NSNotFound) && (row <= endingRow))
	{
	  MacRound(NSInsetRect([tableView rectOfRow:row],3,1),5,MacAccent(),nil);
	  row = [selectedRows indexGreaterThanIndex: row];
	}
    }
  else // Selecting columns
    {
      NSUInteger selectedColumnsCount;
      NSUInteger column;
      NSInteger startingColumn, endingColumn;

      selectedColumnsCount = [selectedColumns count];

      if (selectedColumnsCount == 0)
	return;

      /* highlight selected columns */
      startingColumn = [tableView columnAtPoint: NSMakePoint(NSMinX(clipRect), 0)];
      endingColumn = [tableView columnAtPoint: NSMakePoint(NSMaxX(clipRect), 0)];

      if (startingColumn == -1)
	startingColumn = 0;
      if (endingColumn == -1)
	endingColumn = numberOfColumns - 1;

      column = [selectedColumns indexGreaterThanOrEqualToIndex: startingColumn];
      while ((column != NSNotFound) && (column <= endingColumn))
	{
	  NSRectFill(NSIntersectionRect([tableView rectOfColumn: column],
					clipRect));
	  column = [selectedColumns indexGreaterThanIndex: column];
	}
    }
}

- (void) drawTableViewRow: (NSInteger)rowIndex
		 clipRect: (NSRect)clipRect
		   inView: (NSTableView *)tableView
{
  NSInteger editedRow = [tableView editedRow];
  NSInteger editedColumn = [tableView editedColumn];
  NSArray *tableColumns = [tableView tableColumns];
  NSInteger startingColumn;
  NSInteger endingColumn;
  NSTableColumn *tb;
  NSRect drawingRect;
  NSCell *cell;
  NSInteger i;
  const BOOL rowSelected = [[tableView selectedRowIndexes] containsIndex: rowIndex];
  NSColor *tempColor = nil;
  NSColor *selectedTextColor = [self colorNamed: @"highlightedTableRowTextColor"
					  state: GSThemeNormalState];

  [tableView _calculatedStartingColumn: &startingColumn
			  endingColumn: &endingColumn
			    inClipRect: clipRect];

  /* Draw the row between startingColumn and endingColumn */
  for (i = startingColumn; i <= endingColumn; i++)
    {
      const BOOL columnSelected = [tableView isColumnSelected: i];
      const BOOL cellSelected = (rowSelected || columnSelected);

      tb = [tableColumns objectAtIndex: i];
      cell = [tb dataCellForRow: rowIndex];
      [tableView _willDisplayCell: cell
		 forTableColumn: tb
		 row: rowIndex];
      if (i == editedColumn && rowIndex == editedRow)
        {
          [cell _setInEditing: YES];
        }
      else
        {
          [cell setObjectValue: [tableView _objectValueForTableColumn: tb
                                                                  row: rowIndex]];
        }
      drawingRect = [tableView frameOfCellAtColumn: i
			       row: rowIndex];

      // Set the cell text color if the theme provides a custom highlighted
      // row color.
      //
      // FIXME: This could probably be done in a cleaner way. We should
      // probably do -setHighlighted: YES, and the implementation of
      // -textColor in NSCell could use that to return a highlighted text color.
      if (cellSelected && (selectedTextColor != nil)
	  && [cell isKindOfClass: [NSTextFieldCell class]])
	{
	  tempColor = [cell textColor];
	  [(NSTextFieldCell *)cell setTextColor: selectedTextColor];
	}

      [cell drawWithFrame: drawingRect inView: tableView];

      if (cellSelected && (selectedTextColor != nil)
	  && [cell isKindOfClass: [NSTextFieldCell class]])
	{
	  // Restore the cell's text color if we changed it
	  [(NSTextFieldCell *)cell setTextColor: tempColor];
	}

      if (i == editedColumn && rowIndex == editedRow)
	[cell _setInEditing: NO];
    }
}

- (NSRect) drawOutlineCell: (NSTableColumn *)tb
	       outlineView: (NSOutlineView *)outlineView
		      item: (id)item
	       drawingRect: (NSRect)inputRect
		  rowIndex: (NSInteger)rowIndex
{
  NSRect drawingRect = inputRect;
  NSImage *image = nil;
  NSInteger level = 0;
  CGFloat indentationFactor = 0.0;
  CGFloat indentationPerLevel = [outlineView indentationPerLevel];
  NSCell *imageCell = nil;
  NSRect imageRect;
  id delegate = [outlineView delegate];

  // display the correct arrow...
  if ([outlineView isItemExpanded: item])
    {
      image = [NSImage imageNamed: @"common_ArrowDownH"];
    }
  else
    {
      image = [NSImage imageNamed: @"common_ArrowRightH"];
    }

  if (![outlineView isExpandable: item])
    {
      image = AUTORELEASE([[NSImage alloc] initWithSize: NSMakeSize(14.0,14.0)]);
    }

  level = [outlineView levelForItem: item];
  indentationFactor = indentationPerLevel * level;
  imageCell = [[NSCell alloc] initImageCell: image];
  imageRect = [outlineView frameOfOutlineCellAtRow: rowIndex];

  if ([delegate respondsToSelector: @selector(outlineView:willDisplayOutlineCell:forTableColumn:item:)])
    {
      [delegate outlineView: outlineView
		willDisplayOutlineCell: imageCell
	     forTableColumn: tb
		       item: item];
    }

  /* Do not indent if the delegate set the image to nil. */
  if ([imageCell image])
    {
      imageRect.size.width = [image size].width;
      imageRect.size.height = [image size].height + 5;
      [imageCell drawWithFrame: imageRect inView: outlineView];
      drawingRect.origin.x
	+= indentationFactor + imageRect.size.width + 5;
      drawingRect.size.width
	-= indentationFactor + imageRect.size.width + 5;
    }
  else
    {
      drawingRect.origin.x += indentationFactor;
      drawingRect.size.width -= indentationFactor;
    }

  RELEASE(imageCell);

  return drawingRect;
}

- (void) drawOutlineViewRow: (NSInteger)rowIndex
		   clipRect: (NSRect)clipRect
		     inView: (NSOutlineView *)outlineView
{
  NSInteger editedRow = [outlineView editedRow];
  NSInteger editedColumn = [outlineView editedColumn];
  NSArray *tableColumns = [outlineView tableColumns];
  NSInteger numberOfRows = [outlineView numberOfRows];
  NSInteger startingColumn;
  NSInteger endingColumn;
  NSRect drawingRect;
  NSInteger i;
  NSTableColumn *outlineTableColumn = [outlineView outlineTableColumn];

  /* Using columnAtPoint: here would make it called twice per row per drawn
     rect - so we avoid it and do it natively */

  if (rowIndex >= numberOfRows)
    {
      return;
    }

  [outlineView _calculatedStartingColumn: &startingColumn
			    endingColumn: &endingColumn
			      inClipRect: clipRect];

  /* Draw the row between startingColumn and endingColumn */
  for (i = startingColumn; i <= endingColumn; i++)
    {
      id item = [outlineView itemAtRow: rowIndex];
      NSTableColumn *tb = [tableColumns objectAtIndex: i];
      NSCell *cell = [outlineView preparedCellAtColumn: i row: rowIndex];

      [outlineView _willDisplayCell: cell
		     forTableColumn: tb
				row: rowIndex];
      if (i == editedColumn && rowIndex == editedRow)
        {
          [cell _setInEditing: YES];
          [cell setShowsFirstResponder: YES];
        }
      else
        {
	  id value = [outlineView _objectValueForTableColumn: tb
							 row: rowIndex];
	  [cell setObjectValue: value];
        }

      drawingRect = [outlineView frameOfCellAtColumn: i
						 row: rowIndex];

      if (tb == outlineTableColumn)
        {
	  drawingRect = [self drawOutlineCell: tb
				  outlineView: outlineView
					 item: item
				  drawingRect: drawingRect
				     rowIndex: rowIndex];
	}

      [cell drawWithFrame: drawingRect inView: outlineView];
      if (i == editedColumn && rowIndex == editedRow)
        {
          [cell _setInEditing: NO];
          [cell setShowsFirstResponder: NO];
        }
    }
}

- (BOOL) isBoxOpaque: (NSBox *)box
{
  if ([box boxType] == NSBoxCustom)
    {
      return ![box isTransparent];
    }

  return YES;
}

- (void) drawBoxInClipRect: (NSRect)clipRect
		   boxType: (NSBoxType)boxType
		borderType: (NSBorderType)borderType
		    inView: (NSBox *)box
{
[NSGraphicsContext saveGraphicsState]; NSRectClip(clipRect);
  NSRect r=[box bounds];
  if (boxType==NSBoxSeparator) {
    if (NSWidth(r)>NSHeight(r)) MacLine(NSMakePoint(NSMinX(r),NSMidY(r)),NSMakePoint(NSMaxX(r),NSMidY(r)),MacGray(0.83),1);
    else MacLine(NSMakePoint(NSMidX(r),NSMinY(r)),NSMakePoint(NSMidX(r),NSMaxY(r)),MacGray(0.83),1);
  } else {
    NSRect content=[box borderRect];
    NSColor *fill=boxType==NSBoxCustom ? [box fillColor] : MacGray(0.97);
    NSColor *border=boxType==NSBoxCustom ? [box borderColor] : MacGray(0.83);
    MacRound(content,8,fill,borderType==NSNoBorder ? nil : border);
    if ([[box title] length] && [box titlePosition]!=NSNoTitle) {
      NSRect titleRect=[box titleRect];
      [[NSColor windowBackgroundColor] set]; NSRectFill(titleRect);
      [[box titleCell] drawWithFrame:titleRect inView:box];
    }
  }
  [NSGraphicsContext restoreGraphicsState];
}

- (void) drawEditorForCell: (NSCell *)cell
		 withFrame: (NSRect)cellFrame
		    inView: (NSView *)view
{
  [cell _drawEditorWithFrame: cellFrame
		      inView: view];
}


- (void) drawInCell: (NSCell *)cell
     attributedText: (NSAttributedString *)stringValue
	    inFrame: (NSRect)cellFrame
{
  [cell _drawAttributedText: stringValue
		    inFrame: cellFrame];
}

// NSBrowserCell
- (void) drawBrowserInteriorWithFrame: (NSRect)cellFrame
			     withCell: (NSBrowserCell *)cell
			       inView: (NSView *)controlView
			    withImage: (NSImage *)theImage
		       alternateImage: (NSImage *)alternateImage
			isHighlighted: (BOOL)isHighlighted
				state: (int)state
			       isLeaf: (BOOL)isLeaf
{
  NSRect	title_rect = cellFrame;
  NSImage	*branch_image = nil;
  NSImage	*cell_image = theImage;

  if (isHighlighted || state)
    {
      if (!isLeaf)
	branch_image = [self highlightedBranchImage];
      if (nil != alternateImage)
	[cell setImage: alternateImage];

      // If we are highlighted, fill the background
      [[cell highlightColorInView: controlView] setFill];
      NSRectFill(cellFrame);
    }
  else
    {
      if (!isLeaf)
	branch_image = [self branchImage];

      // (Don't fill the background)
    }

  // Draw the branch image if there is one
  if (branch_image)
    {
      NSRect imgRect;

      imgRect.size = [branch_image size];
      imgRect.origin.x = MAX(NSMaxX(title_rect) - imgRect.size.width - 4.0, 0.);
      imgRect.origin.y = MAX(NSMidY(title_rect) - (imgRect.size.height/2.), 0.);

      if (controlView != nil)
	{
	  imgRect = [controlView centerScanRect: imgRect];
	}

      [branch_image drawInRect: imgRect
		      fromRect: NSZeroRect
		     operation: NSCompositeSourceOver
		      fraction: 1.0
		respectFlipped: YES
			 hints: nil];

      title_rect.size.width -= imgRect.size.width + 8;
    }

  // Skip 2 points from the left border
  title_rect.origin.x += 2;
  title_rect.size.width -= 2;

  // Draw the cell image if there is one
  if (cell_image)
    {
      NSRect imgRect;

      imgRect.size = [cell_image size];
      imgRect.origin.x = NSMinX(title_rect);
      imgRect.origin.y = MAX(NSMidY(title_rect) - (imgRect.size.height/2.),0.);

      if (controlView != nil)
	{
	  imgRect = [controlView centerScanRect: imgRect];
	}

      [cell_image drawInRect: imgRect
		    fromRect: NSZeroRect
		   operation: NSCompositeSourceOver
		    fraction: 1.0
	      respectFlipped: YES
		       hints: nil];

      title_rect.origin.x += imgRect.size.width + 4;
      title_rect.size.width -= imgRect.size.width + 4;
   }

  // Draw the body of the cell
  if ([cell _inEditing])
    {
      [self drawEditorForCell: cell
		    withFrame: cellFrame
		       inView: controlView];
    }
  else
    {
      [self drawInCell: cell
	attributedText: [cell attributedStringValue]
	       inFrame: title_rect];
    }
}

- (NSImage *) branchImage
{
  return [NSImage imageNamed: @"common_3DArrowRight"];
}

- (NSImage *) highlightedBranchImage
{
  return [NSImage imageNamed: @"common_3DArrowRightH"];
}
@end
