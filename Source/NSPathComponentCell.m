/* Implementation of class NSPathComponentCell
   Copyright (C) 2020 Free Software Foundation, Inc.
   
   By: Gregory John Casamento
   Date: Wed Apr 22 18:19:21 EDT 2020

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

#import <Foundation/NSURL.h>
#import <Foundation/NSGeometry.h>

#import "AppKit/NSPathComponentCell.h"
#import "AppKit/NSImage.h"
#import "AppKit/NSFont.h"
#import "AppKit/NSStringDrawing.h"
#import "AppKit/NSAttributedString.h"

#import "GNUstepGUI/GSTheme.h"

@implementation NSPathComponentCell

- (void) dealloc
{
  RELEASE(_image);
  RELEASE(_url);
  [super dealloc];
}

- (NSImage *) image
{
  return _image;
}

- (void) setImage: (NSImage *)image
{
  ASSIGN(_image, image);
}

- (NSURL *) URL
{
  return _url;
}

- (void) setURL: (NSURL *)url
{
  ASSIGNCOPY(_url, url);
}

/* The title shown for this component: its own string value (from an
 * NSPathControlItem), otherwise the last component of its URL. */
- (NSString *) _displayTitle
{
  NSString *title = [self stringValue];

  if ([title length] == 0)
    {
      title = [[_url path] lastPathComponent];
    }
  return title ? title : @"";
}

/* Room for the icon, the title and the separator to the next component. */
- (NSSize) cellSize
{
  NSFont *font = [self font] ? [self font] : [NSFont systemFontOfSize: 0];
  NSDictionary *attributes = [NSDictionary dictionaryWithObject: font
                                                         forKey: NSFontAttributeName];
  NSSize text = [[self _displayTitle] sizeWithAttributes: attributes];
  CGFloat width = 4.0 + text.width + 4.0;

  if (_image != nil)
    {
      width += 16.0 + 4.0;
    }
  if (!_lastComponent)
    {
      width += 14.0;
    }
  return NSMakeSize(ceil(width), MAX(20.0, ceil(text.height) + 4.0));
}

- (void) drawInteriorWithFrame: (NSRect)f
                        inView: (NSView *)v
{
  /* The theme draws the whole component (icon, title, separator). */
  [[GSTheme theme] drawPathComponentCellWithFrame: f
                                           inView: (NSPathControl *)v
                                         withCell: self
                                  isLastComponent: _lastComponent];

}

@end
