/* Definition of class NSWindowRestoration
   Copyright (C) 2020 Free Software Foundation, Inc.
   
   By: Gregory John Casamento
   Date: Tue Apr  7 14:35:13 EDT 2020

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

#ifndef _NSWindowRestoration_h_GNUSTEP_GUI_INCLUDE
#define _NSWindowRestoration_h_GNUSTEP_GUI_INCLUDE

#import <Foundation/NSObject.h>
#import <Foundation/NSCoder.h>
#import "AppKit/NSUserInterfaceItemIdentification.h"
#import <AppKit/NSResponder.h>
#import <AppKit/AppKitDefines.h>
// The categories below need the classes' interfaces.
#import <AppKit/NSApplication.h>
#import <AppKit/NSDocument.h>
#import <AppKit/NSDocumentController.h>
#import <AppKit/NSWindow.h>

#if OS_API_VERSION(MAC_OS_X_VERSION_10_7, GS_API_LATEST)

#if	defined(__cplusplus)
extern "C" {
#endif

@class NSApplication;
@class NSDocument;
@class NSDocumentController;
@class NSError;
@class NSResponder;
@class NSWindow;

DEFINE_BLOCK_TYPE(GSWindowRestorationHandler, void, NSWindow*, NSError*);

/**
 * <p>Implemented by the restoration class of a window (see
 * -[NSWindow setRestorationClass:]).  When the application launches, the
 * class is asked to recreate each window it saved.  It must create the window
 * (or find it), give it the saved identifier, and call the handler with it, or
 * with nil and an error.  The window then restores its own state, which
 * includes its frame, the state of its window controller, document and of the
 * views that have an identifier.</p>
 * <p>Without blocks support the handler is NULL.  The window is then looked up
 * by its identifier after the method returns.</p>
 */
@protocol NSWindowRestoration

+ (void)restoreWindowWithIdentifier: (NSUserInterfaceItemIdentifier)identifier 
                              state: (NSCoder *)state 
                  completionHandler: (GSWindowRestorationHandler)handler;

@end

/** Posted after all windows saved at the last quit were restored. */
APPKIT_EXPORT NSString *NSApplicationDidFinishRestoringWindowsNotification;

/**
 * <p>Restorable state.  A responder encodes what it needs to be shown again as
 * it is now, and invalidates its state when that changes, so that it is saved
 * again.  The base implementation encodes the values of the key paths that
 * +restorableStateKeyPaths returns.</p>
 * <p>Views encode their state only when they have an identifier.</p>
 */
@interface NSResponder (NSRestorableState)
+ (NSArray *) restorableStateKeyPaths;
- (void) encodeRestorableStateWithCoder: (NSCoder *)coder;
- (void) restoreStateWithCoder: (NSCoder *)coder;
- (void) invalidateRestorableState;
@end

@interface NSWindow (NSRestorableState)
/** Whether the window is saved at quit and reopened at launch.  The default
 * is YES, but a window is only saved when it also has a restoration class. */
- (BOOL) isRestorable;
- (void) setRestorable: (BOOL)flag;
/** The class that recreates the window at launch.  It must conform to the
 * NSWindowRestoration protocol.  Windows of a document get the class of the
 * shared document controller. */
- (Class) restorationClass;
- (void) setRestorationClass: (Class)restorationClass;
- (void) disableSnapshotRestoration;
- (void) enableSnapshotRestoration;
@end

@interface NSApplication (NSWindowRestoration)
/** Asks the restoration class encoded in state to recreate the window with
 * identifier.  Returns NO when the state names no usable class. */
- (BOOL) restoreWindowWithIdentifier: (NSUserInterfaceItemIdentifier)identifier
                               state: (NSCoder *)state
                   completionHandler: (GSWindowRestorationHandler)handler;
/** Keeps restoration from finishing until -completeStateRestoration. */
- (void) extendStateRestoration;
- (void) completeStateRestoration;
@end

@interface NSDocument (NSRestorableState)
+ (NSArray *) restorableStateKeyPaths;
/** Finds the window with identifier among the document's window controllers,
 * making them first if needed, and passes it to the handler. */
- (void) restoreDocumentWindowWithIdentifier: (NSUserInterfaceItemIdentifier)identifier
                                       state: (NSCoder *)state
                           completionHandler: (GSWindowRestorationHandler)handler;
/** Encodes the document's location, so that it can be reopened. */
- (void) encodeRestorableStateWithCoder: (NSCoder *)coder;
- (void) restoreStateWithCoder: (NSCoder *)coder;
- (void) invalidateRestorableState;
@end

/** Reopens the document of a document window and restores the window. */
@interface NSDocumentController (NSWindowRestoration) <NSWindowRestoration>
@end

#if	defined(__cplusplus)
}
#endif

#endif	/* GS_API_MACOSX */

#endif	/* _NSWindowRestoration_h_GNUSTEP_GUI_INCLUDE */

