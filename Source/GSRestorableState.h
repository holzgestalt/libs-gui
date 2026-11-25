/* Private interface to window restoration
   Copyright (C) 2026 Free Software Foundation, Inc.

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

#ifndef _GSRestorableState_h_GNUSTEP_GUI_INCLUDE
#define _GSRestorableState_h_GNUSTEP_GUI_INCLUDE

#import <Foundation/NSObject.h>

/* The restorable state of the application and its windows is saved as a
   whole, a moment after something in it changed, and at the start of
   -[NSApplication terminate:].  Changes before the restoration at launch
   finished are not saved, so that the state of the last session is not
   overwritten before it was read.  */

/* Notes that the restorable state changed and schedules saving it. */
void GSRestorableStateInvalidate(void);

/* Restores the windows saved at the last quit.  Called by -finishLaunching
   after the application delegate was told that launching will finish.
   Returns YES when windows are being restored, in which case no untitled
   document is opened.  */
BOOL GSRestorableStateRestore(void);

/* Saves the state now and stops saving changes, so that closing the windows
   while quitting doesn't remove them from the saved state.  */
void GSRestorableStateBeginTermination(void);

/* The quit was cancelled: changes are saved again.  */
void GSRestorableStateCancelTermination(void);

/* The application quits.  Removes the saved state when the user doesn't want
   windows to be kept (NSQuitAlwaysKeepsWindows is NO).  */
void GSRestorableStateFinishTermination(void);

#endif /* _GSRestorableState_h_GNUSTEP_GUI_INCLUDE */
