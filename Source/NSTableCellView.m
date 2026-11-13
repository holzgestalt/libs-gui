/* Implementation of class NSTableCellView
   Copyright (C) 2022 Free Software Foundation, Inc.
   
   By: Gregory John Casamento <greg.casamento@gmail.com>
   Date: 12-12-2022

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

#import "AppKit/NSTableCellView.h"
#import "AppKit/NSImageView.h"
#import "AppKit/NSTextField.h"
#import "AppKit/NSKeyValueBinding.h"
#import "AppKit/NSLayoutConstraint.h"
#import <Foundation/NSKeyedArchiver.h>
#import <Foundation/NSMapTable.h>
#import <Foundation/NSHashTable.h>
#import <Foundation/NSNull.h>

/* Targets outside the copied hierarchy are connections, not part of the
   prototype. They may not support NSCoding. Restore them after decoding. */
@interface GSTableCellViewCopyDelegate : NSObject
{
@public
  NSHashTable *externalTargets;
}
@end

@implementation GSTableCellViewCopyDelegate
- (id) archiver: (NSKeyedArchiver *)archiver willEncodeObject: (id)object
{
  return [externalTargets containsObject: object] ? nil : object;
}
@end

static void
mapCopiedViews(NSView *source, NSView *copy, NSMapTable *map)
{
  NSArray *children = [source subviews];
  NSArray *copies = [copy subviews];
  NSUInteger i;

  [map setObject: copy forKey: source];
  if ([source isKindOfClass: [NSControl class]])
    [map setObject: [(NSControl *)copy cell]
           forKey: [(NSControl *)source cell]];
  for (i = 0; i < [children count]; i++)
    mapCopiedViews([children objectAtIndex: i], [copies objectAtIndex: i], map);
}

@implementation NSTableCellView

- (instancetype) initWithFrame: (NSRect)frame
{
  self = [super initWithFrame: frame];
  if (self != nil)
    {
      _rowSizeStyle = NSTableViewRowSizeStyleCustom;
      _backgroundStyle = NSBackgroundStyleLight;
    }
  return self;
}

- (instancetype) init
{
  return [self initWithFrame: NSZeroRect];
}

- (void) dealloc
{
  RELEASE(_objectValue);
  RELEASE(_imageView);
  RELEASE(_textField);
  RELEASE(_draggingImageComponents);

  [super dealloc];
}

- (id) objectValue
{
  return _objectValue;
}

- (void) setObjectValue: (id)objectValue
{
  ASSIGN(_objectValue, objectValue);
}

- (NSImageView *) imageView
{
  return _imageView;
}

- (void) setImageView: (NSImageView *)imageView
{
  ASSIGN(_imageView, imageView);
}

- (NSTextField *) textField
{
  return _textField;
}

- (void) setTextField: (NSTextField *)textField
{
  ASSIGN(_textField, textField);
}

- (NSBackgroundStyle) backgroundStyle
{
  return _backgroundStyle;
}

- (void) setBackgroundStyle: (NSBackgroundStyle)backgroundStyle
{
  _backgroundStyle = backgroundStyle;
}

- (NSTableViewRowSizeStyle) rowSizeStyle
{
  return _rowSizeStyle;
}

- (void) setRowSizeStyle: (NSTableViewRowSizeStyle)rowSizeStyle
{
  _rowSizeStyle = rowSizeStyle;
}

- (NSArray *) draggingImageComponents
{
  return _draggingImageComponents;
}

- (void) setDraggingImageComponents: (NSArray *)draggingImageComponents
{
  ASSIGNCOPY(_draggingImageComponents, draggingImageComponents);
}

- (void) encodeWithCoder: (NSCoder *)coder
{
  [super encodeWithCoder: coder];
  if ([coder allowsKeyedCoding])
    {
      [coder encodeObject: [self objectValue]
		   forKey: @"NSObjectValue"];
      [coder encodeObject: [self imageView]
		   forKey: @"NSImageView"];
      [coder encodeObject: [self textField]
		   forKey: @"NSTextField"];
      [coder encodeInt: [self backgroundStyle]
		forKey: @"NSBackgroundStyle"];
      [coder encodeInt: [self rowSizeStyle]
		forKey: @"NSTableViewRowSizeStyle"];
      [coder encodeObject: [self draggingImageComponents]
		   forKey: @"NSDraggingImageComponents"];
    }
  else
    {
      [coder encodeObject: _objectValue];
      [coder encodeObject: _imageView];
      [coder encodeObject: _textField];
      [coder encodeObject: _draggingImageComponents];

      [coder encodeValueOfObjCType: @encode(NSBackgroundStyle)
				at: &_backgroundStyle];
      [coder encodeValueOfObjCType: @encode(NSTableViewRowSizeStyle)
				at: &_rowSizeStyle];
    }
}

- (id) initWithCoder: (NSCoder *)coder
{
  self = [super initWithCoder: coder];
  if (self != nil)
    {
      if ([coder allowsKeyedCoding])
	{
	  if ([coder containsValueForKey: @"NSObjectValue"])
	    {
	      [self setObjectValue: [coder decodeObjectForKey: @"NSObjectValue"]];	      
	    }

	  if ([coder containsValueForKey: @"NSImageView"])
	    {
	      [self setImageView: [coder decodeObjectForKey: @"NSImageView"]];	      
	    }

	  if ([coder containsValueForKey: @"NSTextField"])
	    {
	      [self setTextField: [coder decodeObjectForKey: @"NSTextField"]];	      
	    }
	  
	  if ([coder containsValueForKey: @"NSBackgroundStyle"])
	    {
	      [self setBackgroundStyle: [coder decodeIntForKey: @"NSBackgroundStyle"]];
	    }

	  if ([coder containsValueForKey: @"NSTableViewRowSizeStyle"])
	    {
	      [self setRowSizeStyle: [coder decodeIntForKey: @"NSTableViewRowSizeStyle"]];
	    }

	  if ([coder containsValueForKey: @"NSDraggingImageComponents"])
	    {
	      [self setDraggingImageComponents: [coder decodeObjectForKey: @"NSDraggingImageComponents"]];
	    }
	}
      else
	{
	  [self setObjectValue: [coder decodeObject]];
	  [self setImageView: [coder decodeObject]];
	  [self setTextField: [coder decodeObject]];
	  [self setDraggingImageComponents: [coder decodeObject]];
	  
	  [coder decodeValueOfObjCType: @encode(NSBackgroundStyle)
				    at: &_backgroundStyle];
	  [coder decodeValueOfObjCType: @encode(NSTableViewRowSizeStyle)
				    at: &_rowSizeStyle];	  
	}
    }
  return self;
}

- (id) copyWithZone: (NSZone *)zone
{
  NSTableCellView *copy = [[[self class] allocWithZone: zone] initWithFrame: [self frame]];
  NSArray *parts = [NSArray arrayWithObjects: [self subviews],
    [self textField] ?: (id)[NSNull null],
    [self imageView] ?: (id)[NSNull null], nil];
  NSMutableArray *views = [NSMutableArray arrayWithArray: [self subviews]];
  NSHashTable *targets = [NSHashTable hashTableWithOptions:
    NSPointerFunctionsObjectPointerPersonality];
  GSTableCellViewCopyDelegate *delegate = [GSTableCellViewCopyDelegate new];
  NSMutableData *data = [NSMutableData data];
  NSKeyedArchiver *coder = [[NSKeyedArchiver alloc] initForWritingWithMutableData: data];
  NSArray *decoded;
  NSMapTable *map;
  NSEnumerator *enumerator;
  id source;
  NSUInteger i;

  if ([self textField] && ![views containsObject: [self textField]])
    [views addObject: [self textField]];
  if ([self imageView] && ![views containsObject: [self imageView]])
    [views addObject: [self imageView]];
  for (i = 0; i < [views count]; i++)
    {
      NSView *view = [views objectAtIndex: i];
      for (NSView *child in [view subviews])
        if (![views containsObject: child]) [views addObject: child];
    }
  for (NSView *view in views)
    if ([view isKindOfClass: [NSControl class]])
      {
        id target = [(NSControl *)view target];
        if (target && ![views containsObject: target]) [targets addObject: target];
      }
  delegate->externalTargets = targets;
  [coder setDelegate: delegate];
  [coder encodeObject: parts forKey: @"root"];
  [coder finishEncoding];
  RELEASE(coder);
  RELEASE(delegate);
  decoded = [NSKeyedUnarchiver unarchiveObjectWithData: data];

  [copy setSubviews: [decoded objectAtIndex: 0]];
  [copy setTextField: [self textField] ? [decoded objectAtIndex: 1] : nil];
  [copy setImageView: [self imageView] ? [decoded objectAtIndex: 2] : nil];
  map = [NSMapTable mapTableWithKeyOptions: NSPointerFunctionsObjectPointerPersonality
                            valueOptions: NSPointerFunctionsStrongMemory];
  mapCopiedViews(self, copy, map);
  if ([self textField]) mapCopiedViews([self textField], [copy textField], map);
  if ([self imageView]) mapCopiedViews([self imageView], [copy imageView], map);

  [copy setIdentifier: [self identifier]];
  [copy setAutoresizingMask: [self autoresizingMask]];
  [copy setAutoresizesSubviews: [self autoresizesSubviews]];
  [copy setHidden: [self isHidden]];
  [copy setBounds: [self bounds]];
  [copy setTranslatesAutoresizingMaskIntoConstraints: [self translatesAutoresizingMaskIntoConstraints]];
  for (NSLayoutConstraint *constraint in [self constraints])
    {
      id first = [map objectForKey: [constraint firstItem]];
      id second = [map objectForKey: [constraint secondItem]];
      if (first != nil && ([constraint secondItem] == nil || second != nil))
        {
          NSLayoutConstraint *cloned = [NSLayoutConstraint constraintWithItem: first
            attribute: [constraint firstAttribute] relatedBy: [constraint relation]
            toItem: second attribute: [constraint secondAttribute]
            multiplier: [constraint multiplier] constant: [constraint constant]];
          [cloned setPriority: [constraint priority]];
          [cloned setIdentifier: [constraint identifier]];
          [copy addConstraint: cloned];
        }
    }
  [copy setObjectValue: [self objectValue]];
  [copy setDraggingImageComponents: [self draggingImageComponents]];
  [copy setBackgroundStyle: [self backgroundStyle]];
  [copy setRowSizeStyle: [self rowSizeStyle]];

  /* Bindings are not part of NSView's archive. Reconnect copied controls to
     their own cell, while keeping connections to external models intact. */
  enumerator = [map keyEnumerator];
  while ((source = [enumerator nextObject]) != nil)
    {
      id destination = [map objectForKey: source];
      if ([source respondsToSelector: @selector(target)])
        {
          id target = [source target];
          [destination setTarget: [map objectForKey: target] ?: target];
          [destination setAction: [source action]];
        }
      for (NSString *binding in [source exposedBindings])
        {
          NSDictionary *info = [source infoForBinding: binding];
          id observed = [info objectForKey: NSObservedObjectKey];
          if (observed != nil)
            [destination bind: binding
                     toObject: [map objectForKey: observed] ?: observed
                  withKeyPath: [info objectForKey: NSObservedKeyPathKey]
                      options: [info objectForKey: NSOptionsKey]];
        }
    }

  return copy;
}

@end
