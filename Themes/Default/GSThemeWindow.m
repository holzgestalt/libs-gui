#import "GSDefaultTheme.h"
/** <title>GSThemeWindow</title>

   <abstract>The theme methods for window specific functions</abstract>

   Copyright (C) 2015 Free Software Foundation, Inc.

   Author: Gregory Casamento <greg.casamento@gmail.com>
   Date: Jun 2015

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

#import "AppKit/NSWindow.h"
#import "AppKit/NSImage.h"
#import "AppKit/NSButton.h"

#import "GNUstepGUI/GSTheme.h"
#import "GNUstepGUI/GSWindowDecorationView.h"
#import "GSThemePrivate.h"
#import "GNUstepGUI/GSDisplayServer.h"

@implementation GSDefaultTheme (NSWindow)
- (NSButton *) standardWindowButton: (NSWindowButton)buttonType
		       forStyleMask: (NSUInteger) mask
{
NSButton *button=[[[NSButton alloc] initWithFrame:NSMakeRect(0,0,14,14)] autorelease];
  [button setBordered:NO]; [button setRefusesFirstResponder:YES];
  [button setButtonType:NSMomentaryChangeButton]; [button setImagePosition:NSImageOnly]; [button setTag:buttonType];
  switch (buttonType) {
    case NSWindowCloseButton: [button setImage:[NSImage imageNamed:@"MacWindowClose"]]; [button setAction:@selector(performClose:)]; break;
    case NSWindowMiniaturizeButton: [button setImage:[NSImage imageNamed:@"MacWindowMinimize"]]; [button setAction:@selector(miniaturize:)]; break;
    case NSWindowZoomButton: [button setImage:[NSImage imageNamed:@"MacWindowZoom"]]; [button setAction:@selector(zoom:)]; break;
    case NSWindowToolbarButton: [button setTitle:@"…"]; [button setImagePosition:NSNoImage]; [button setAction:@selector(toggleToolbarShown:)]; break;
    default: break;
  }
  return button;
}

- (void) didSetDefaultButtonCell: (NSButtonCell *)aCell
{
  // default implementation does nothing...
}

- (id<GSWindowDecorator>) windowDecorator
{
  if ([GSCurrentServer() handlesWindowDecorations])
    return [GSBackendWindowDecorationView self];
  else
    return [GSStandardWindowDecorationView self];
}

@end
