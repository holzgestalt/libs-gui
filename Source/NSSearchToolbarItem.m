/* Implementation of class NSSearchToolbarItem
   Copyright (C) 2026 Free Software Foundation, Inc.

   By: Gregory John Casamento
   Date: Mon 20 Jul 2026 12:55:02 AM EDT

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

#import "AppKit/NSSearchToolbarItem.h"
#import "AppKit/NSSearchField.h"
#import "AppKit/NSWindow.h"

@implementation NSSearchToolbarItem
- (id) initWithItemIdentifier: (NSString *)identifier
{
  self = [super initWithItemIdentifier: identifier];
  if (self != nil)
    {
      NSSearchField *field = [[NSSearchField alloc]
        initWithFrame: NSZeroRect];
      NSSize size;

      [field sizeToFit];
      size = [field frame].size;
      [field setFrameSize: NSMakeSize(220, size.height)];
      [self setSearchField: field];
      RELEASE(field);
      [self setMinSize: NSMakeSize(120, size.height)];
      [self setMaxSize: NSMakeSize(400, size.height)];
    }
  return self;
}
- (id) initWithCoder: (NSCoder *)coder
{
  self = [super initWithCoder: coder];
  if (self != nil && [[self view] isKindOfClass: [NSSearchField class]])
    [self setSearchField: (NSSearchField *)[self view]];
  return self;
}
- (NSSearchField *) searchField
{
  return (NSSearchField *)[self view];
}
- (void) setSearchField: (NSSearchField *)field
{
  id target = [self target];
  SEL action = [self action];
  BOOL enabled = [self isEnabled];

  [self setView: field];
  [field setTarget: target];
  [field setAction: action];
  [self setEnabled: enabled];
}
- (void) beginSearchInteraction
{
  [[[self searchField] window] makeFirstResponder: [self searchField]];
}
- (void) endSearchInteraction
{
  NSSearchField *field = [self searchField];
  NSWindow *window = [field window];
  id responder = [window firstResponder];

  if (responder == field || (responder != nil && responder == [field currentEditor]))
    [window makeFirstResponder: nil];
}
@end
