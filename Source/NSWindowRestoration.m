/* Implementation of window restoration
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

#import <Foundation/NSArray.h>
#import <Foundation/NSBundle.h>
#import <Foundation/NSData.h>
#import <Foundation/NSDebug.h>
#import <Foundation/NSDictionary.h>
#import <Foundation/NSError.h>
#import <Foundation/NSException.h>
#import <Foundation/NSFileManager.h>
#import <Foundation/NSKeyedArchiver.h>
#import <Foundation/NSKeyValueCoding.h>
#import <Foundation/NSNotification.h>
#import <Foundation/NSPathUtilities.h>
#import <Foundation/NSProcessInfo.h>
#import <Foundation/NSPropertyList.h>
#import <Foundation/NSRunLoop.h>
#import <Foundation/NSString.h>
#import <Foundation/NSURL.h>
#import <Foundation/NSUserDefaults.h>

#import "AppKit/NSApplication.h"
#import "AppKit/NSDocument.h"
#import "AppKit/NSDocumentController.h"
#import "AppKit/NSGraphics.h"
#import "AppKit/NSView.h"
#import "AppKit/NSWindow.h"
#import "AppKit/NSWindowController.h"
#import "AppKit/NSWindowRestoration.h"
#import "GSRestorableState.h"

/* Keys of the saved state file. */
static NSString *const GSStateVersionKey = @"Version";
static NSString *const GSStateApplicationKey = @"Application";
static NSString *const GSStateWindowsKey = @"Windows";
static NSString *const GSStateIdentifierKey = @"Identifier";
static NSString *const GSStateDataKey = @"State";
static NSString *const GSStateKeyWindowKey = @"KeyWindow";
static NSString *const GSStateMainWindowKey = @"MainWindow";

/* Keys of a window's state. */
static NSString *const GSRestorationClassKey = @"GSRestorationClass";
static NSString *const GSWindowFrameKey = @"NSWindowFrame";
static NSString *const GSWindowMiniaturizedKey = @"NSWindowMiniaturized";
static NSString *const GSWindowControllerStateKey = @"GSWindowControllerState";
static NSString *const GSDocumentStateKey = @"GSDocumentState";
static NSString *const GSViewStatesKey = @"GSViewStates";

/* Keys of a document's state. */
static NSString *const GSDocumentURLKey = @"NSDocumentURL";
static NSString *const GSDocumentAutosavedURLKey = @"NSDocumentAutosavedURL";
static NSString *const GSDocumentTypeKey = @"NSDocumentType";

static BOOL active = NO;      /* Changes are saved. */
static BOOL suspended = NO;   /* Quitting: changes are not saved. */
static BOOL scheduled = NO;   /* A save is scheduled. */
static BOOL dirty = NO;       /* Changed since the last save. */
static NSUInteger pendingRestorations = 0;
static NSWindow *restoredKeyWindow = nil;
static NSWindow *restoredMainWindow = nil;
static NSData *lastSavedState = nil;

@interface GSRestorableStateSaver : NSObject
+ (void) save;
+ (void) restorationTimedOut;
+ (void) windowDidChange: (NSNotification *)notification;
@end

static void finishRestoration(void);

static BOOL
quitKeepsWindows(void)
{
  NSUserDefaults *defs = [NSUserDefaults standardUserDefaults];

  if ([defs objectForKey: @"NSQuitAlwaysKeepsWindows"] == nil)
    {
      return YES;
    }
  return [defs boolForKey: @"NSQuitAlwaysKeepsWindows"];
}

static NSString *
stateFilePath(BOOL create)
{
  NSArray *dirs;
  NSString *dir;
  NSString *name;

  dirs = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory,
    NSUserDomainMask, YES);
  if ([dirs count] == 0)
    {
      return nil;
    }
  name = [[NSBundle mainBundle] bundleIdentifier];
  if ([name length] == 0)
    {
      name = [[NSProcessInfo processInfo] processName];
    }
  dir = [[dirs objectAtIndex: 0]
    stringByAppendingPathComponent: @"Saved Application State"];
  dir = [dir stringByAppendingPathComponent:
    [name stringByAppendingPathExtension: @"savedState"]];
  if (create)
    {
      [[NSFileManager defaultManager] createDirectoryAtPath: dir
                                withIntermediateDirectories: YES
                                                 attributes: nil
                                                      error: NULL];
    }
  return [dir stringByAppendingPathComponent: @"GSWindows.plist"];
}

/* Whether a responder has anything to encode, so that views with an
   identifier but no state are not archived. */
static BOOL
hasRestorableState(id responder)
{
  static IMP baseEncode = 0;

  if (baseEncode == 0)
    {
      baseEncode = [NSResponder instanceMethodForSelector:
        @selector(encodeRestorableStateWithCoder:)];
    }
  return [responder methodForSelector:
    @selector(encodeRestorableStateWithCoder:)] != baseEncode
    || [[[responder class] restorableStateKeyPaths] count] > 0;
}

static void
collectRestorableViews(NSView *view, NSMutableDictionary *views)
{
  NSEnumerator *e;
  NSView *subview;
  NSString *identifier = [view identifier];

  if ([identifier length] > 0 && [views objectForKey: identifier] == nil
    && hasRestorableState(view))
    {
      [views setObject: view forKey: identifier];
    }
  e = [[view subviews] objectEnumerator];
  while ((subview = [e nextObject]) != nil)
    {
      collectRestorableViews(subview, views);
    }
}

static NSData *
archiveRestorableState(id object)
{
  NSMutableData *data = [NSMutableData data];
  NSKeyedArchiver *coder;

  coder = [[NSKeyedArchiver alloc] initForWritingWithMutableData: data];
  [object encodeRestorableStateWithCoder: coder];
  [coder finishEncoding];
  RELEASE(coder);
  return data;
}

static void
unarchiveRestorableState(id object, NSData *data)
{
  NSKeyedUnarchiver *coder;

  if (object == nil || ![data isKindOfClass: [NSData class]])
    {
      return;
    }
  coder = [[NSKeyedUnarchiver alloc] initForReadingWithData: data];
  [object restoreStateWithCoder: coder];
  [coder finishDecoding];
  RELEASE(coder);
}

/* The windows to save, from back to front. */
static NSArray *
windowsToSave(void)
{
  NSMutableArray *ordered = [NSMutableArray array];
  NSMutableArray *result = [NSMutableArray array];
  NSMutableArray *sheets = [NSMutableArray array];
  NSArray *windows = [NSApp windows];
  NSEnumerator *e;
  NSWindow *win;

  /* Sheets are restored by whoever shows them. */
  e = [windows objectEnumerator];
  while ((win = [e nextObject]) != nil)
    {
      if ([win attachedSheet] != nil)
        {
          [sheets addObject: [win attachedSheet]];
        }
    }

  e = [GSOrderedWindows() reverseObjectEnumerator];
  while ((win = [e nextObject]) != nil)
    {
      if ([windows indexOfObjectIdenticalTo: win] != NSNotFound)
        {
          [ordered addObject: win];
        }
    }
  /* Miniaturized windows aren't on screen; put them at the back. */
  e = [windows objectEnumerator];
  while ((win = [e nextObject]) != nil)
    {
      if ([ordered indexOfObjectIdenticalTo: win] == NSNotFound)
        {
          [ordered insertObject: win atIndex: 0];
        }
    }

  e = [ordered objectEnumerator];
  while ((win = [e nextObject]) != nil)
    {
      if ([win isRestorable] && [win restorationClass] != Nil
        && ([win isVisible] || [win isMiniaturized])
        && [sheets indexOfObjectIdenticalTo: win] == NSNotFound)
        {
          [result addObject: win];
        }
    }
  return result;
}

static NSDictionary *
encodeState(void)
{
  NSMutableDictionary *state = [NSMutableDictionary dictionary];
  NSMutableArray *records = [NSMutableArray array];
  NSEnumerator *e;
  NSWindow *win;

  [state setObject: [NSNumber numberWithInt: 1] forKey: GSStateVersionKey];
  NS_DURING
    {
      [state setObject: archiveRestorableState(NSApp)
                forKey: GSStateApplicationKey];
    }
  NS_HANDLER
    {
      NSLog(@"Unable to encode the restorable state of the application: %@",
        localException);
    }
  NS_ENDHANDLER

  e = [windowsToSave() objectEnumerator];
  while ((win = [e nextObject]) != nil)
    {
      NS_DURING
        {
          NSMutableDictionary *record = [NSMutableDictionary dictionary];
          NSMutableData *data = [NSMutableData data];
          NSKeyedArchiver *coder;

          coder = [[NSKeyedArchiver alloc]
            initForWritingWithMutableData: data];
          [coder encodeObject: NSStringFromClass([win restorationClass])
                       forKey: GSRestorationClassKey];
          [win encodeRestorableStateWithCoder: coder];
          [coder finishEncoding];
          RELEASE(coder);

          if ([[win identifier] length] > 0)
            {
              [record setObject: [win identifier]
                         forKey: GSStateIdentifierKey];
            }
          [record setObject: data forKey: GSStateDataKey];
          if (win == [NSApp keyWindow])
            {
              [state setObject: [NSNumber numberWithUnsignedInteger:
                [records count]] forKey: GSStateKeyWindowKey];
            }
          if (win == [NSApp mainWindow])
            {
              [state setObject: [NSNumber numberWithUnsignedInteger:
                [records count]] forKey: GSStateMainWindowKey];
            }
          [records addObject: record];
        }
      NS_HANDLER
        {
          NSLog(@"Unable to encode the restorable state of %@: %@",
            win, localException);
        }
      NS_ENDHANDLER
    }
  [state setObject: records forKey: GSStateWindowsKey];
  return state;
}

static void
saveState(void)
{
  NSString *path;
  NSData *data;
  NSString *error = nil;

  dirty = NO;
  if (!quitKeepsWindows())
    {
      return;
    }
  data = [NSPropertyListSerialization
    dataFromPropertyList: encodeState()
                  format: NSPropertyListXMLFormat_v1_0
        errorDescription: &error];
  if (data == nil)
    {
      NSLog(@"Unable to save the restorable state: %@", error);
      return;
    }
  if ([data isEqual: lastSavedState])
    {
      return;
    }
  path = stateFilePath(YES);
  if (path != nil && [data writeToFile: path atomically: YES])
    {
      ASSIGN(lastSavedState, data);
    }
}

void
GSRestorableStateInvalidate(void)
{
  dirty = YES;
  if (!active || suspended || scheduled)
    {
      return;
    }
  scheduled = YES;
  [GSRestorableStateSaver performSelector: @selector(save)
                               withObject: nil
                               afterDelay: 1.0
                                  inModes: [NSArray arrayWithObjects:
    NSDefaultRunLoopMode, NSModalPanelRunLoopMode,
    NSEventTrackingRunLoopMode, nil]];
}

static void
startTracking(void)
{
  NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
  NSString *names[] = {
    NSWindowDidMoveNotification,
    NSWindowDidResizeNotification,
    NSWindowDidMiniaturizeNotification,
    NSWindowDidDeminiaturizeNotification,
    NSWindowDidBecomeKeyNotification,
    NSWindowDidBecomeMainNotification,
    NSWindowWillCloseNotification
  };
  unsigned i;

  for (i = 0; i < sizeof(names) / sizeof(names[0]); i++)
    {
      [nc addObserver: [GSRestorableStateSaver class]
             selector: @selector(windowDidChange:)
                 name: names[i]
               object: nil];
    }
  active = YES;
  GSRestorableStateInvalidate();
}

/* Called once for every window that restoration was started for. */
static void
windowRestored(NSWindow *window, NSKeyedUnarchiver *coder,
  BOOL makeKey, BOOL makeMain)
{
  if (window != nil)
    {
      NS_DURING
        {
          [window restoreStateWithCoder: coder];
        }
      NS_HANDLER
        {
          NSLog(@"Unable to restore the state of %@: %@",
            window, localException);
        }
      NS_ENDHANDLER
      [window orderFront: nil];
      if ([coder decodeBoolForKey: GSWindowMiniaturizedKey])
        {
          [window miniaturize: nil];
        }
      if (makeKey)
        {
          ASSIGN(restoredKeyWindow, window);
        }
      if (makeMain)
        {
          ASSIGN(restoredMainWindow, window);
        }
    }
  [coder finishDecoding];
  RELEASE(coder);
  [NSApp completeStateRestoration];
}

#if !__has_feature(blocks)
static NSWindow *
windowWithIdentifier(NSString *identifier)
{
  NSEnumerator *e = [[NSApp windows] objectEnumerator];
  NSWindow *win;

  if ([identifier length] == 0)
    {
      return nil;
    }
  while ((win = [e nextObject]) != nil)
    {
      if ([[win identifier] isEqualToString: identifier])
        {
          return win;
        }
    }
  return nil;
}
#endif

/* Starts restoring the window of a record.  Returns NO when it couldn't be
   started, for example because its restoration class is missing. */
static BOOL
restoreWindow(NSDictionary *record, BOOL makeKey, BOOL makeMain)
{
  NSString *identifier = [record objectForKey: GSStateIdentifierKey];
  NSData *data = [record objectForKey: GSStateDataKey];
  NSKeyedUnarchiver *coder = nil;
  BOOL started = NO;
#if __has_feature(blocks)
  __block BOOL done = NO;
  GSWindowRestorationHandler handler = nil;
#endif

  if (![data isKindOfClass: [NSData class]])
    {
      return NO;
    }
  [NSApp extendStateRestoration];
  NS_DURING
    {
      coder = [[NSKeyedUnarchiver alloc] initForReadingWithData: data];
#if __has_feature(blocks)
      handler = ^(NSWindow *window, NSError *error)
        {
          if (done)
            {
              return;
            }
          done = YES;
          if (window == nil && error != nil)
            {
              NSDebugLLog(@"NSWindowRestoration",
                @"Window %@ was not restored: %@", identifier, error);
            }
          windowRestored(window, coder, makeKey, makeMain);
        };
      /* The restoration class may call the handler later. */
      handler = AUTORELEASE([handler copy]);
      started = [NSApp restoreWindowWithIdentifier: identifier
                                             state: coder
                                 completionHandler: handler];
#else
      started = [NSApp restoreWindowWithIdentifier: identifier
                                             state: coder
                                 completionHandler: NULL];
      if (started)
        {
          /* Without blocks the restoration class can't report the window. */
          windowRestored(windowWithIdentifier(identifier), coder,
            makeKey, makeMain);
        }
#endif
    }
  NS_HANDLER
    {
      NSLog(@"Unable to restore window %@: %@", identifier, localException);
      started = NO;
    }
  NS_ENDHANDLER

  if (!started)
    {
#if __has_feature(blocks)
      if (done)
        {
          return NO;
        }
      done = YES;
#endif
      windowRestored(nil, coder, NO, NO);
    }
  return started;
}

BOOL
GSRestorableStateRestore(void)
{
  NSUserDefaults *defs = [NSUserDefaults standardUserDefaults];
  NSString *path = stateFilePath(NO);
  NSDictionary *state = nil;
  NSArray *records;
  NSNumber *keyIndex;
  NSNumber *mainIndex;
  NSUInteger i;
  NSUInteger count;
  BOOL started = NO;

  if (path != nil && !quitKeepsWindows())
    {
      [[NSFileManager defaultManager] removeFileAtPath: path handler: nil];
    }
  else if (path != nil && ![defs boolForKey: @"ApplePersistenceIgnoreState"])
    {
      NS_DURING
        {
          state = [NSDictionary dictionaryWithContentsOfFile: path];
        }
      NS_HANDLER
        {
          state = nil;
        }
      NS_ENDHANDLER
    }
  if (![state isKindOfClass: [NSDictionary class]])
    {
      startTracking();
      return NO;
    }

  pendingRestorations = 1;
  NS_DURING
    {
      unarchiveRestorableState(NSApp,
        [state objectForKey: GSStateApplicationKey]);
    }
  NS_HANDLER
    {
      NSLog(@"Unable to restore the state of the application: %@",
        localException);
    }
  NS_ENDHANDLER

  records = [state objectForKey: GSStateWindowsKey];
  if (![records isKindOfClass: [NSArray class]])
    {
      records = nil;
    }
  keyIndex = [state objectForKey: GSStateKeyWindowKey];
  mainIndex = [state objectForKey: GSStateMainWindowKey];
  count = [records count];
  for (i = 0; i < count; i++)
    {
      NSDictionary *record = [records objectAtIndex: i];

      if ([record isKindOfClass: [NSDictionary class]])
        {
          if (restoreWindow(record,
            keyIndex != nil && [keyIndex unsignedIntegerValue] == i,
            mainIndex != nil && [mainIndex unsignedIntegerValue] == i))
            {
              started = YES;
            }
        }
    }
  if (pendingRestorations > 1)
    {
      /* A restoration class that never calls its handler must not keep the
         state from being saved for the rest of the session. */
      [GSRestorableStateSaver performSelector: @selector(restorationTimedOut)
                                   withObject: nil
                                   afterDelay: 60.0];
    }
  [NSApp completeStateRestoration];
  return started;
}

static void
finishRestoration(void)
{
  [NSObject cancelPreviousPerformRequestsWithTarget:
    [GSRestorableStateSaver class]
                                           selector: @selector(restorationTimedOut)
                                             object: nil];
  if (restoredMainWindow != nil && [restoredMainWindow isVisible]
    && [restoredMainWindow canBecomeMainWindow])
    {
      [restoredMainWindow makeMainWindow];
    }
  if (restoredKeyWindow != nil && [restoredKeyWindow isVisible])
    {
      [restoredKeyWindow makeKeyAndOrderFront: nil];
    }
  DESTROY(restoredKeyWindow);
  DESTROY(restoredMainWindow);
  [[NSNotificationCenter defaultCenter]
    postNotificationName: NSApplicationDidFinishRestoringWindowsNotification
                  object: NSApp];
  if (!active)
    {
      startTracking();
    }
}

void
GSRestorableStateBeginTermination(void)
{
  if (active && !suspended)
    {
      if (scheduled)
        {
          [NSObject cancelPreviousPerformRequestsWithTarget:
            [GSRestorableStateSaver class]
                                                   selector: @selector(save)
                                                     object: nil];
          scheduled = NO;
        }
      saveState();
    }
  suspended = YES;
}

void
GSRestorableStateCancelTermination(void)
{
  suspended = NO;
  if (dirty)
    {
      GSRestorableStateInvalidate();
    }
}

void
GSRestorableStateFinishTermination(void)
{
  suspended = YES;
  if (!quitKeepsWindows())
    {
      NSString *path = stateFilePath(NO);

      if (path != nil)
        {
          [[NSFileManager defaultManager] removeFileAtPath: path handler: nil];
        }
    }
}

@implementation GSRestorableStateSaver

+ (void) save
{
  scheduled = NO;
  if (active && !suspended && dirty)
    {
      saveState();
    }
}

+ (void) restorationTimedOut
{
  if (pendingRestorations > 0)
    {
      NSLog(@"Window restoration did not finish; saving the state again.");
      pendingRestorations = 0;
      finishRestoration();
    }
}

+ (void) windowDidChange: (NSNotification *)notification
{
  if ([[notification object] restorationClass] != Nil)
    {
      GSRestorableStateInvalidate();
    }
}

@end


@implementation NSResponder (NSRestorableState)

+ (NSArray *) restorableStateKeyPaths
{
  return [NSArray array];
}

- (void) encodeRestorableStateWithCoder: (NSCoder *)coder
{
  NSEnumerator *e = [[[self class] restorableStateKeyPaths] objectEnumerator];
  NSString *keyPath;

  while ((keyPath = [e nextObject]) != nil)
    {
      id value = [self valueForKeyPath: keyPath];

      if (value != nil)
        {
          [coder encodeObject: value forKey: keyPath];
        }
    }
}

- (void) restoreStateWithCoder: (NSCoder *)coder
{
  NSEnumerator *e = [[[self class] restorableStateKeyPaths] objectEnumerator];
  NSString *keyPath;

  while ((keyPath = [e nextObject]) != nil)
    {
      if ([coder containsValueForKey: keyPath])
        {
          [self setValue: [coder decodeObjectForKey: keyPath]
              forKeyPath: keyPath];
        }
    }
}

- (void) invalidateRestorableState
{
  GSRestorableStateInvalidate();
}

@end


@implementation NSWindow (NSRestorableState)

- (BOOL) isRestorable
{
  return _f.is_restorable;
}

- (void) setRestorable: (BOOL)flag
{
  if (_f.is_restorable != (flag ? 1 : 0))
    {
      _f.is_restorable = flag;
      GSRestorableStateInvalidate();
    }
}

- (Class) restorationClass
{
  return _restorationClass;
}

- (void) setRestorationClass: (Class)restorationClass
{
  if (_restorationClass != restorationClass)
    {
      _restorationClass = restorationClass;
      GSRestorableStateInvalidate();
    }
}

- (void) disableSnapshotRestoration
{
}

- (void) enableSnapshotRestoration
{
}

- (void) encodeRestorableStateWithCoder: (NSCoder *)coder
{
  NSMutableDictionary *views = [NSMutableDictionary dictionary];
  NSMutableDictionary *viewStates = [NSMutableDictionary dictionary];
  NSWindowController *controller = [self windowController];
  NSDocument *document = [controller document];
  NSEnumerator *e;
  NSString *identifier;
  id delegate = [self delegate];

  [super encodeRestorableStateWithCoder: coder];
  [coder encodeObject: [self stringWithSavedFrame] forKey: GSWindowFrameKey];
  [coder encodeBool: [self isMiniaturized] forKey: GSWindowMiniaturizedKey];

  collectRestorableViews([self contentView], views);
  e = [views keyEnumerator];
  while ((identifier = [e nextObject]) != nil)
    {
      [viewStates setObject: archiveRestorableState(
        [views objectForKey: identifier]) forKey: identifier];
    }
  if ([viewStates count] > 0)
    {
      [coder encodeObject: viewStates forKey: GSViewStatesKey];
    }

  if (controller != nil)
    {
      [coder encodeObject: archiveRestorableState(controller)
                   forKey: GSWindowControllerStateKey];
    }
  if (document != nil)
    {
      [coder encodeObject: archiveRestorableState(document)
                   forKey: GSDocumentStateKey];
    }
  if ([delegate respondsToSelector:
    @selector(window:willEncodeRestorableState:)])
    {
      [delegate window: self willEncodeRestorableState: coder];
    }
}

- (void) restoreStateWithCoder: (NSCoder *)coder
{
  NSWindowController *controller = [self windowController];
  NSString *frame;
  NSDictionary *viewStates;
  id delegate = [self delegate];

  [super restoreStateWithCoder: coder];
  frame = [coder decodeObjectForKey: GSWindowFrameKey];
  if ([frame isKindOfClass: [NSString class]] && [frame length] > 0)
    {
      [self setFrameFromString: frame];
    }

  viewStates = [coder decodeObjectForKey: GSViewStatesKey];
  if ([viewStates isKindOfClass: [NSDictionary class]])
    {
      NSMutableDictionary *views = [NSMutableDictionary dictionary];
      NSEnumerator *e;
      NSString *identifier;

      collectRestorableViews([self contentView], views);
      e = [viewStates keyEnumerator];
      while ((identifier = [e nextObject]) != nil)
        {
          unarchiveRestorableState([views objectForKey: identifier],
            [viewStates objectForKey: identifier]);
        }
    }

  if (controller != nil)
    {
      unarchiveRestorableState(controller,
        [coder decodeObjectForKey: GSWindowControllerStateKey]);
      unarchiveRestorableState([controller document],
        [coder decodeObjectForKey: GSDocumentStateKey]);
    }
  if ([delegate respondsToSelector:
    @selector(window:didDecodeRestorableState:)])
    {
      [delegate window: self didDecodeRestorableState: coder];
    }
}

@end


@implementation NSApplication (NSWindowRestoration)

- (void) encodeRestorableStateWithCoder: (NSCoder *)coder
{
  id delegate = [self delegate];

  [super encodeRestorableStateWithCoder: coder];
  if ([delegate respondsToSelector:
    @selector(application:willEncodeRestorableState:)])
    {
      [delegate application: self willEncodeRestorableState: coder];
    }
}

- (void) restoreStateWithCoder: (NSCoder *)coder
{
  id delegate = [self delegate];

  [super restoreStateWithCoder: coder];
  if ([delegate respondsToSelector:
    @selector(application:didDecodeRestorableState:)])
    {
      [delegate application: self didDecodeRestorableState: coder];
    }
}

- (BOOL) restoreWindowWithIdentifier: (NSUserInterfaceItemIdentifier)identifier
                               state: (NSCoder *)state
                   completionHandler: (GSWindowRestorationHandler)handler
{
  NSString *className = [state decodeObjectForKey: GSRestorationClassKey];
  Class restorationClass = Nil;

  if ([className isKindOfClass: [NSString class]])
    {
      restorationClass = NSClassFromString(className);
    }
  if (restorationClass == Nil || ![restorationClass respondsToSelector:
    @selector(restoreWindowWithIdentifier:state:completionHandler:)])
    {
      NSDebugLLog(@"NSWindowRestoration",
        @"No restoration class %@ for window %@", className, identifier);
      return NO;
    }
  [restorationClass restoreWindowWithIdentifier: identifier
                                          state: state
                              completionHandler: handler];
  return YES;
}

- (void) extendStateRestoration
{
  pendingRestorations++;
}

- (void) completeStateRestoration
{
  if (pendingRestorations == 0)
    {
      return;
    }
  pendingRestorations--;
  if (pendingRestorations == 0)
    {
      finishRestoration();
    }
}

@end


@implementation NSDocument (NSRestorableState)

+ (NSArray *) restorableStateKeyPaths
{
  return [NSArray array];
}

- (void) restoreDocumentWindowWithIdentifier: (NSUserInterfaceItemIdentifier)identifier
                                       state: (NSCoder *)state
                           completionHandler: (GSWindowRestorationHandler)handler
{
  NSArray *controllers = [self windowControllers];
  NSEnumerator *e;
  NSWindowController *controller;
  NSWindow *found = nil;
  NSWindow *untagged = nil;
  NSError *error = nil;

  if ([controllers count] == 0)
    {
      [self makeWindowControllers];
      controllers = [self windowControllers];
    }
  e = [controllers objectEnumerator];
  while ((controller = [e nextObject]) != nil)
    {
      NSWindow *win = [controller window];

      if (win == nil)
        {
          continue;
        }
      if ([identifier length] > 0
        && [[win identifier] isEqualToString: identifier])
        {
          found = win;
          break;
        }
      if (untagged == nil && [[win identifier] length] == 0)
        {
          untagged = win;
        }
    }
  if (found == nil)
    {
      found = untagged;
      if ([identifier length] > 0)
        {
          [found setIdentifier: identifier];
        }
    }
  if (found == nil)
    {
      error = [NSError errorWithDomain: NSCocoaErrorDomain
                                  code: NSFileReadUnknownError
                              userInfo: nil];
    }
  CALL_BLOCK(handler, found, error);
}

- (void) encodeRestorableStateWithCoder: (NSCoder *)coder
{
  NSEnumerator *e = [[[self class] restorableStateKeyPaths] objectEnumerator];
  NSString *keyPath;

  if ([self fileURL] != nil)
    {
      [coder encodeObject: [[self fileURL] absoluteString]
                   forKey: GSDocumentURLKey];
    }
  if ([self autosavedContentsFileURL] != nil)
    {
      [coder encodeObject: [[self autosavedContentsFileURL] absoluteString]
                   forKey: GSDocumentAutosavedURLKey];
    }
  if ([self fileType] != nil)
    {
      [coder encodeObject: [self fileType] forKey: GSDocumentTypeKey];
    }
  while ((keyPath = [e nextObject]) != nil)
    {
      id value = [self valueForKeyPath: keyPath];

      if (value != nil)
        {
          [coder encodeObject: value forKey: keyPath];
        }
    }
}

- (void) restoreStateWithCoder: (NSCoder *)coder
{
  NSEnumerator *e = [[[self class] restorableStateKeyPaths] objectEnumerator];
  NSString *keyPath;

  while ((keyPath = [e nextObject]) != nil)
    {
      if ([coder containsValueForKey: keyPath])
        {
          [self setValue: [coder decodeObjectForKey: keyPath]
              forKeyPath: keyPath];
        }
    }
}

- (void) invalidateRestorableState
{
  GSRestorableStateInvalidate();
}

@end


@implementation NSDocumentController (NSWindowRestoration)

+ (void) restoreWindowWithIdentifier: (NSUserInterfaceItemIdentifier)identifier
                               state: (NSCoder *)state
                   completionHandler: (GSWindowRestorationHandler)handler
{
  NSDocumentController *controller = [self sharedDocumentController];
  NSFileManager *fm = [NSFileManager defaultManager];
  NSData *data = [state decodeObjectForKey: GSDocumentStateKey];
  NSString *location = nil;
  NSString *autosavedLocation = nil;
  NSString *type = nil;
  NSURL *url;
  NSURL *autosavedURL;
  NSDocument *document = nil;
  NSError *error = nil;

  if ([data isKindOfClass: [NSData class]])
    {
      NSKeyedUnarchiver *coder;

      coder = [[NSKeyedUnarchiver alloc] initForReadingWithData: data];
      location = [coder decodeObjectForKey: GSDocumentURLKey];
      autosavedLocation = [coder decodeObjectForKey: GSDocumentAutosavedURLKey];
      type = [coder decodeObjectForKey: GSDocumentTypeKey];
      AUTORELEASE(RETAIN(location));
      AUTORELEASE(RETAIN(autosavedLocation));
      AUTORELEASE(RETAIN(type));
      [coder finishDecoding];
      RELEASE(coder);
    }
  url = [location length] > 0 ? [NSURL URLWithString: location] : nil;
  autosavedURL = [autosavedLocation length] > 0
    ? [NSURL URLWithString: autosavedLocation] : nil;

  if (url != nil)
    {
      document = [controller documentForURL: url];
    }
  if (document == nil && autosavedURL != nil
    && [fm fileExistsAtPath: [autosavedURL path]])
    {
      if (type == nil)
        {
          type = [controller typeForContentsOfURL: autosavedURL error: &error];
        }
      if (type != nil)
        {
          document = [controller makeDocumentForURL: url
                                  withContentsOfURL: autosavedURL
                                             ofType: type
                                              error: &error];
          if (document != nil)
            {
              [controller addDocument: document];
            }
        }
    }
  if (document == nil && url != nil
    && (![url isFileURL] || [fm fileExistsAtPath: [url path]]))
    {
      document = [controller openDocumentWithContentsOfURL: url
                                                   display: NO
                                                     error: &error];
    }
  if (document == nil)
    {
      if (error == nil)
        {
          error = [NSError errorWithDomain: NSCocoaErrorDomain
                                      code: NSFileReadNoSuchFileError
                                  userInfo: nil];
        }
      CALL_BLOCK(handler, nil, error);
      return;
    }
  [document restoreDocumentWindowWithIdentifier: identifier
                                          state: state
                              completionHandler: handler];
}

@end
