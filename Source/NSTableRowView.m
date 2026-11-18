/* Implementation of class NSTableRowView
   Copyright (C) 2022 Free Software Foundation, Inc.

   By: Gregory John Casamento
   Date: 03-09-2022

   This file is part of the GNUstep Library.

   This library is free software; you can redistribute it and/or
   modify it under the terms of the GNU Lesser General Public
   License as published by the Free Software Foundation; either
   version 2.1 of the License, or (at your option) any later version.

   This library is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
   Lesser General Public License for more details.

   You should have received a copy of the GNU Lesser General Public
   License along with this library; if not, write to the Free
   Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
   Boston, MA 02110 USA.
*/

#import "AppKit/NSTableRowView.h"
#import "AppKit/NSColor.h"
#import "AppKit/NSGraphics.h"

@implementation NSTableRowView

- (BOOL) isFlipped
{
  return YES;
}

- (void) drawRect: (NSRect)dirtyRect
{
  [self drawBackgroundInRect: dirtyRect];
  if (_selected && _selectionHighlightStyle != NSTableViewSelectionHighlightStyleNone)
    [self drawSelectionInRect: dirtyRect];
  [self drawSeparatorInRect: dirtyRect];
}

- (void) dealloc
{
  RELEASE(_backgroundColor);
  DEALLOC
}

- (BOOL) isEmphasized
{
  return _emphasized;
}

- (void) setEmphasized: (BOOL)flag
{
  if (_emphasized == flag) return;
  _emphasized = flag;
  [self setNeedsDisplay: YES];
}

- (NSBackgroundStyle) interiorBackgroundStyle
{
  return _selected && _emphasized ? NSBackgroundStyleDark : NSBackgroundStyleLight;
}

- (BOOL) isFloating
{
  return _floating;
}

- (void) setFloating: (BOOL)flag
{
  _floating = flag;
}

- (BOOL) isSelected
{
  return _selected;
}

- (void) setSelected: (BOOL)flag
{
  if (_selected == flag) return;
  _selected = flag;
  [self setNeedsDisplay: YES];
}

- (NSTableViewSelectionHighlightStyle) selectionHighlightStyle
{
  return _selectionHighlightStyle;
}

- (void) setSelectionHighlightStyle: (NSTableViewSelectionHighlightStyle) selectionHighlightStyle
{
  if (_selectionHighlightStyle == selectionHighlightStyle) return;
  _selectionHighlightStyle = selectionHighlightStyle;
  [self setNeedsDisplay: YES];
}

- (NSTableViewDraggingDestinationFeedbackStyle) draggingDestinationFeedbackStyle
{
  return _draggingDestinationFeedbackStyle;
}

- (void) setDraggingDestinationFeedbackStyle: (NSTableViewDraggingDestinationFeedbackStyle) draggingDestinationFeedbackStyle
{
  _draggingDestinationFeedbackStyle = draggingDestinationFeedbackStyle;
}

- (CGFloat) indentationForDropOperation
{
  return _indentationForDropOperation;
}

- (void) setIndentationForDropOperation: (CGFloat)indentationForDropOperation
{
  _indentationForDropOperation = indentationForDropOperation;
}

- (BOOL) isTargetForDropOperation
{
  return _targetForDropOperation;
}

- (void) setTargetForDropOperation: (BOOL)flag
{
  _targetForDropOperation = flag;
}

- (BOOL) isGroupRowStyle
{
  return _groupRowStyle;
}

- (void) setGroupRowStyle: (BOOL)flag
{
  _groupRowStyle = flag;
}

- (NSInteger) numberOfColumns
{
  if ([[self superview] isKindOfClass: [NSTableView class]])
    return [(NSTableView *)[self superview] numberOfColumns];
  return [[self subviews] count];
}

- (NSColor *) backgroundColor
{
  return _backgroundColor;
}

- (void) setBackgroundColor: (NSColor *)color
{
  ASSIGN(_backgroundColor, color);
  [self setNeedsDisplay: YES];
}

- (void) drawBackgroundInRect: (NSRect)dirtyRect
{
  if (_backgroundColor != nil)
    {
      [_backgroundColor setFill];
      NSRectFill(dirtyRect);
    }
}

- (void) drawDraggingDestinationFeedbackInRect: (NSRect)dirtyRect
{
}

- (void) drawSelectionInRect: (NSRect)dirtyRect
{
  [(_emphasized ? [NSColor selectedControlColor]
                : [NSColor secondarySelectedControlColor]) setFill];
  NSRectFill(dirtyRect);
}

- (void) drawSeparatorInRect: (NSRect)dirtyRect
{
}

- (id) viewAtColumn: (NSInteger)column
{
  if ([[self superview] isKindOfClass: [NSTableView class]])
    {
      NSTableView *table = (NSTableView *)[self superview];
      return [table viewAtColumn: column row: [table rowForView: self] makeIfNecessary: NO];
    }
  NSArray *views = [self subviews];
  return column >= 0 && column < [views count] ? [views objectAtIndex: column] : nil;
}

- (BOOL) isNextRowSelected
{
  return _nextRowSelected;
}

- (void) setNextRowSelected: (BOOL)flag
{
  _nextRowSelected = flag;
}

- (BOOL) isPreviousRowSelected
{
  return _previousRowSelected;
}

- (void) setPreviousRowSelected: (BOOL)flag
{
  _previousRowSelected = flag;
}

@end
