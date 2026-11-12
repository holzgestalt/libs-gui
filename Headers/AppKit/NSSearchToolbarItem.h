/* Definition of class NSSearchToolbarItem
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

#ifndef _GNUstep_H_NSSearchToolbarItem
#define _GNUstep_H_NSSearchToolbarItem
#import <AppKit/NSToolbarItem.h>
#if OS_API_VERSION(MAC_OS_X_VERSION_10_15, GS_API_LATEST)

#if defined(__cplusplus)
extern "C" {
#endif

@class NSSearchField;
APPKIT_EXPORT_CLASS
@interface NSSearchToolbarItem : NSToolbarItem
- (NSSearchField *) searchField;
- (void) setSearchField: (NSSearchField *)searchField;
- (void) beginSearchInteraction;
- (void) endSearchInteraction;
@end

#if defined(__cplusplus)
}
#endif

#endif /* OS_API_VERSION */
#endif
