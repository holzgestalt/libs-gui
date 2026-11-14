/* Implementation of class NSPDFImageRep
   Copyright (C) 2019 Free Software Foundation, Inc.
   
   By: Gregory Casamento <greg.casamento@gmail.com>
   Date: Fri Nov 15 04:24:27 EST 2019

   This file is part of the GNUstep Library.
   
   This library is free software; you can redistribute it and/or
   modify it under the terms of the GNU Lesser General Public
   License as published by the Free Software Foundation; either
   version 2 of the License, or (at your option) any later version.
   
   This library is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
   Lesser General Public License for more details.
   
   You should have received a copy of the GNU Lesser General Public
   License along with this library; if not, write to the Free
   Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
   Boston, MA 02110 USA.
*/

#import "config.h"

#import <Foundation/NSString.h>
#import <Foundation/NSData.h>
#import "AppKit/NSPasteboard.h"
#import "AppKit/NSPDFImageRep.h"
#import <GNUstepGUI/GSImageMagickImageRep.h>
#import <Foundation/NSArray.h>
#import "AppKit/NSAffineTransform.h"
#import "AppKit/NSBitmapImageRep.h"
#import "AppKit/NSColor.h"
#import "AppKit/NSGraphicsContext.h"
#import "AppKit/NSGraphics.h"
#include <math.h>
#include <string.h>
#include <limits.h>
#include <stdint.h>

#if HAVE_POPPLER
#include <poppler.h>

/* Keep the page as vector data. NSImageRep's drawing machinery supplies a
 * context at the destination density, including scaling and source crops. */
@interface GSPDFPageImageRep : NSImageRep
{
  PopplerPage *_page;
  PopplerDocument *_document;
}
- (id) initWithPage: (PopplerPage *)page document: (PopplerDocument *)document;
@end

@implementation GSPDFPageImageRep
- (id) initWithPage: (PopplerPage *)page document: (PopplerDocument *)document
{
  self = [super init];
  if (self != nil)
    {
      double width, height;
      _page = g_object_ref(page);
      _document = g_object_ref(document);
      poppler_page_get_size(page, &width, &height);
      [self setSize: NSMakeSize(width, height)];
      [self setPixelsWide: NSImageRepMatchesDevice];
      [self setPixelsHigh: NSImageRepMatchesDevice];
      [self setBitsPerSample: 8];
      [self setColorSpaceName: NSDeviceRGBColorSpace];
      [self setAlpha: YES];
    }
  return self;
}

- (void) dealloc
{
  g_object_unref(_page);
  g_object_unref(_document);
  [super dealloc];
}

- (id) copyWithZone: (NSZone *)zone
{
  GSPDFPageImageRep *copy = [super copyWithZone: zone];
  copy->_page = g_object_ref(_page);
  copy->_document = g_object_ref(_document);
  return copy;
}

- (BOOL) draw
{
  NSGraphicsContext *context = [NSGraphicsContext currentContext];
  NSAffineTransformStruct matrix;
  NSSize size = [self size];
  double width, height;
  cairo_surface_t *surface;
  cairo_t *cr;
  NSBitmapImageRep *bitmap;
  unsigned char *destination;
  unsigned char *source;
  NSInteger x, y, stride;

  if (context == nil || size.width <= 0 || size.height <= 0)
    return NO;
  matrix = [[context GSCurrentCTM] transformStruct];
  width = ceil(size.width * hypot(matrix.m11, matrix.m12));
  height = ceil(size.height * hypot(matrix.m21, matrix.m22));
  if (!isfinite(width) || !isfinite(height) || width <= 0 || height <= 0
      || width > INT_MAX / 4 || height > INT_MAX
      || (long double)width * height > (long double)NSUIntegerMax / 4)
    return NO;

  surface = cairo_image_surface_create(CAIRO_FORMAT_ARGB32, width, height);
  if (cairo_surface_status(surface) != CAIRO_STATUS_SUCCESS)
    {
      cairo_surface_destroy(surface);
      return NO;
    }
  cr = cairo_create(surface);
  cairo_scale(cr, width / size.width, height / size.height);
  poppler_page_render(_page, cr);
  BOOL rendered = cairo_status(cr) == CAIRO_STATUS_SUCCESS;
  cairo_destroy(cr);
  if (!rendered)
    {
      cairo_surface_destroy(surface);
      return NO;
    }
  cairo_surface_flush(surface);
  bitmap = [[NSBitmapImageRep alloc]
    initWithBitmapDataPlanes: NULL pixelsWide: width pixelsHigh: height
    bitsPerSample: 8 samplesPerPixel: 4 hasAlpha: YES isPlanar: NO
    colorSpaceName: NSDeviceRGBColorSpace bytesPerRow: 0 bitsPerPixel: 0];
  if (bitmap == nil)
    {
      cairo_surface_destroy(surface);
      return NO;
    }
  source = cairo_image_surface_get_data(surface);
  stride = cairo_image_surface_get_stride(surface);
  destination = [bitmap bitmapData];
  /* Both Cairo and NSBitmapImageRep's default format use premultiplied
   * alpha. Only reorder native-endian ARGB into RGBA; do not unpremultiply. */
  for (y = 0; y < (NSInteger)height; y++)
    for (x = 0; x < (NSInteger)width; x++)
      {
        uint32_t pixel;
        unsigned char *out = destination + y * [bitmap bytesPerRow] + x * 4;
        memcpy(&pixel, source + y * stride + x * 4, sizeof(pixel));
        out[0] = (pixel >> 16) & 255;
        out[1] = (pixel >> 8) & 255;
        out[2] = pixel & 255;
        out[3] = pixel >> 24;
      }
  cairo_surface_destroy(surface);
  [bitmap setSize: size];
  BOOL result = [bitmap drawInRect: NSMakeRect(0, 0, size.width, size.height)];
  RELEASE(bitmap);
  return result;
}
@end
#endif

@implementation NSPDFImageRep

+ (BOOL) canInitWithData: (NSData *)imageData
{
  return [imageData length] >= 4
    && memcmp([imageData bytes], "%PDF", 4) == 0;
}

+ (NSArray *) imagePasteboardTypes
{
  return [NSArray arrayWithObject: NSPDFPboardType];
}

+ (NSArray *) imageUnfilteredPasteboardTypes
{
  return [self imagePasteboardTypes];
}

+ (NSArray *) imageFileTypes
{
  return [NSArray arrayWithObjects: @"pdf", @"PDF", nil];
}

+ (NSArray *) imageUnfilteredFileTypes
{
  return [self imageFileTypes];
}

+ (instancetype) imageRepWithData: (NSData *)imageData
{
  return AUTORELEASE([[[self class] alloc] initWithData: imageData]);
}

- (instancetype) initWithData: (NSData *)imageData
{
  self = [super init];
  if(self != nil)
    {
#if HAVE_POPPLER
      NSMutableArray *pages = [NSMutableArray array];
      GError *error = NULL;
      GBytes *bytes = g_bytes_new([imageData bytes], [imageData length]);
      PopplerDocument *document = poppler_document_new_from_bytes(bytes, NULL, &error);
      g_bytes_unref(bytes);
      if (document != NULL)
        {
          int count = poppler_document_get_n_pages(document);
          int i;
          for (i = 0; i < count; i++)
            {
              PopplerPage *page = poppler_document_get_page(document, i);
              if (page != NULL)
                {
                  id rep = [[GSPDFPageImageRep alloc] initWithPage: page document: document];
                  [pages addObject: rep];
                  RELEASE(rep);
                  g_object_unref(page);
                }
            }
          g_object_unref(document);
        }
      if (error != NULL)
        g_error_free(error);
      ASSIGN(_pageReps, pages);
      _size = [pages count] ? [[pages objectAtIndex: 0] size] : NSZeroSize;
      [self setPixelsWide: NSImageRepMatchesDevice];
      [self setPixelsHigh: NSImageRepMatchesDevice];
      [self setBitsPerSample: 8];
      [self setColorSpaceName: NSDeviceRGBColorSpace];
      [self setAlpha: YES];
      _currentPage = 0;
#elif HAVE_IMAGEMAGICK
      ASSIGN(_pageReps, [GSImageMagickImageRep imageRepsWithData: imageData]);
      if ([_pageReps count] > 0)
        {
          _size = [[_pageReps objectAtIndex: 0] size];
        }
      else
        {
          _size = NSMakeSize(0, 0);
        }
      _currentPage = 0;
#else
      ASSIGN(_pageReps, [NSArray array]);
      _size = NSMakeSize(0,0);
      _currentPage = 0;
#endif
      ASSIGNCOPY(_pdfRepresentation, imageData);
    }
  return self;
}

- (void) dealloc
{
  RELEASE(_pageReps);
  RELEASE(_pdfRepresentation);
  [super dealloc];
}

- (id) copyWithZone: (NSZone *)zone
{
  NSPDFImageRep *copy = [super copyWithZone: zone];
  copy->_pageReps = [_pageReps copyWithZone: zone];
  copy->_pdfRepresentation = [_pdfRepresentation copyWithZone: zone];
  return copy;
}

- (NSRect) bounds
{
  NSSize size = [self size];
  NSRect rect = NSMakeRect(0, 0, size.width, size.height);
  return rect;
}

- (NSInteger) currentPage
{
  return _currentPage;
}

- (void) setCurrentPage: (NSInteger)currentPage
{
  NSUInteger count = [_pageReps count];
  NSImageRep *page;

  if (count == 0)
    {
      _currentPage = 0;
      return;
    }

  if (currentPage < 0)
    {
      currentPage = 0;
    }
  else if ((NSUInteger)currentPage >= count)
    {
      currentPage = count - 1;
    }
  _currentPage = currentPage;

  page = [_pageReps objectAtIndex: _currentPage];
  [self setSize: [page size]];
  [self setPixelsWide: [page pixelsWide]];
  [self setPixelsHigh: [page pixelsHigh]];
}

- (NSInteger) pageCount
{
  return [_pageReps count];
}

- (NSData *) PDFRepresentation
{
  return _pdfRepresentation;
}

// Override to draw the specified page...
- (BOOL) draw
{
  if ([_pageReps count] == 0
      || [NSGraphicsContext currentContext] == nil)
    {
      return NO;
    }
  return [[_pageReps objectAtIndex: _currentPage] drawInRect: [self bounds]];
}
@end

