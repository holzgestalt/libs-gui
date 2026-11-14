/* Representation selection follows the destination CTM, including live scale
 * changes. These checks do not need a display server or cached image windows. */
#import "Testing.h"
#import <AppKit/AppKit.h>

@interface ScaleContext : NSObject
{
  NSAffineTransform *transform;
}
- (void) setTransform: (NSAffineTransform *)value;
- (NSAffineTransform *) GSCurrentCTM;
@end
@implementation ScaleContext
- (void) setTransform: (NSAffineTransform *)value
{
  ASSIGN(transform, value);
}
- (NSAffineTransform *) GSCurrentCTM { return transform; }
- (void) dealloc { RELEASE(transform); [super dealloc]; }
@end

static NSImageRep *
bitmap(NSInteger width, NSInteger height)
{
  NSBitmapImageRep *rep = AUTORELEASE([[NSBitmapImageRep alloc]
    initWithBitmapDataPlanes: NULL pixelsWide: width pixelsHigh: height
    bitsPerSample: 8 samplesPerPixel: 4 hasAlpha: YES isPlanar: NO
    colorSpaceName: NSDeviceRGBColorSpace bytesPerRow: 0 bitsPerPixel: 0]);
  [rep setSize: NSMakeSize(16, 16)];
  return rep;
}

int main(void)
{
  START_SET("NSImage scale selection")
  ScaleContext *context = AUTORELEASE([ScaleContext new]);
  NSImage *image = AUTORELEASE([[NSImage alloc] initWithSize: NSMakeSize(16, 16)]);
  NSImageRep *one = bitmap(16, 16);
  NSImageRep *two = bitmap(32, 32);
  NSImageRep *three = bitmap(48, 48);
  NSRect rect = NSMakeRect(0, 0, 16, 16);
  NSAffineTransform *transform;
  CGFloat scales[] = {1, 2, 1.5, 3, 4, 1};
  NSImageRep *expected[] = {one, two, two, three, three, one};
  unsigned i;

  /* Deliberately shuffled to catch selection based on insertion order. */
  [image addRepresentations: [NSArray arrayWithObjects: three, one, two, nil]];
  for (i = 0; i < sizeof(scales) / sizeof(scales[0]); i++)
    {
      transform = [NSAffineTransform transform];
      [transform scaleBy: scales[i]];
      [context setTransform: transform];
      PASS([image bestRepresentationForRect: rect
        context: (NSGraphicsContext *)context hints: nil] == expected[i],
        "scale %g chooses the appropriate source pixels", (double)scales[i]);
    }
  transform = [NSAffineTransform transform];
  [transform rotateByDegrees: 45];
  [transform scaleXBy: -2 yBy: 2];
  [context setTransform: transform];
  PASS([image bestRepresentationForRect: rect
    context: (NSGraphicsContext *)context hints: nil] == two,
    "rotation and reflection preserve the 2x density");

  transform = [NSAffineTransform transform];
  [transform scaleXBy: 1 yBy: 2];
  [context setTransform: transform];
  PASS([image bestRepresentationForRect: rect
    context: (NSGraphicsContext *)context hints: nil] == two,
    "both axes must have enough pixels for nonuniform scaling");

  NSImageRep *vector = AUTORELEASE([NSImageRep new]);
  [vector setSize: NSMakeSize(16, 16)];
  [vector setPixelsWide: NSImageRepMatchesDevice];
  [vector setPixelsHigh: NSImageRepMatchesDevice];
  [image addRepresentation: vector];
  [image setUsesEPSOnResolutionMismatch: YES];
  transform = [NSAffineTransform transform];
  [transform scaleBy: 1.5];
  [context setTransform: transform];
  PASS([image bestRepresentationForRect: rect
    context: (NSGraphicsContext *)context hints: nil] == vector,
    "a device-independent rep is preferred to resampling at fractional scale");
  [transform scaleBy: 2.0 / 1.5];
  PASS([image bestRepresentationForRect: rect
    context: (NSGraphicsContext *)context hints: nil] == two,
    "an exact bitmap match remains preferred");
  [image setUsesEPSOnResolutionMismatch: NO];
  [transform scaleBy: 1.5 / 2.0];
  PASS([image bestRepresentationForRect: rect
    context: (NSGraphicsContext *)context hints: nil] == two,
    "the vector preference can be disabled");
  [image removeRepresentation: one];
  [image removeRepresentation: two];
  [image removeRepresentation: three];
  PASS([image bestRepresentationForRect: rect
    context: (NSGraphicsContext *)context hints: nil] == vector,
    "a vector-only image remains usable without the preference");
  [image removeRepresentation: vector];
  PASS([image bestRepresentationForRect: rect
    context: (NSGraphicsContext *)context hints: nil] == nil,
    "an empty image has no representation");
  END_SET("NSImage scale selection")
  return 0;
}
