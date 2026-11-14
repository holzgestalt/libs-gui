#import "Testing.h"
#import "../GSDrawTest.h"

@interface ScaleVectorRep : NSImageRep
{
@public
  NSUInteger draws;
}
@end
@implementation ScaleVectorRep
- (BOOL) draw
{
  draws++;
  [[NSColor blueColor] set];
  NSRectFill(NSMakeRect(0, 0, 16, 16));
  return YES;
}
@end

static NSImageRep *bitmap(NSInteger pixels, BOOL red)
{
  NSBitmapImageRep *rep = AUTORELEASE([[NSBitmapImageRep alloc]
    initWithBitmapDataPlanes: NULL pixelsWide: pixels pixelsHigh: pixels
    bitsPerSample: 8 samplesPerPixel: 4 hasAlpha: YES isPlanar: NO
    colorSpaceName: NSDeviceRGBColorSpace bytesPerRow: 0 bitsPerPixel: 0]);
  NSInteger x, y;
  NSUInteger rgba[] = {red ? 255 : 0, red ? 0 : 255, 0, 255};
  for (y = 0; y < pixels; y++)
    for (x = 0; x < pixels; x++)
      [rep setPixel: rgba atX: x y: y];
  [rep setSize: NSMakeSize(16, 16)];
  return rep;
}

static NSBitmapImageRep *render(NSImage *image, CGFloat scale, BOOL crop)
{
  NSImage *canvas = GSDrawBegin(64, 64);
  NSAffineTransform *transform = [NSAffineTransform transform];
  [NSGraphicsContext saveGraphicsState];
  [transform scaleBy: scale];
  [transform concat];
  [image drawInRect: NSMakeRect(0, 0, 16, 16)
    fromRect: crop ? NSMakeRect(0, 0, 8, 8) : NSZeroRect
    operation: NSCompositeSourceOver fraction: 1];
  [NSGraphicsContext restoreGraphicsState];
  return GSDrawEnd(canvas, 64, 64);
}

int main(void)
{
  START_SET("NSImage scale drawing")
  [NSApplication sharedApplication];
  if (!GSCanDrawOffscreen())
    SKIP("backend cannot read offscreen pixels")
  NSImage *image = AUTORELEASE([[NSImage alloc] initWithSize: NSMakeSize(16, 16)]);
  [image addRepresentation: bitmap(16, YES)];
  [image addRepresentation: bitmap(32, NO)];
  NSBitmapImageRep *result = render(image, 1, NO);
  PASS(GSPixelIs(result, 8, 55, 255, 0, 0), "1x draws the 16-pixel red rep");
  result = render(image, 2, NO);
  PASS(GSPixelIs(result, 16, 47, 0, 255, 0), "2x draws the 32-pixel green rep");
  result = render(image, 1, NO);
  PASS(GSPixelIs(result, 8, 55, 255, 0, 0), "returning to 1x restores the red rep");
  result = render(image, 1, YES);
  PASS(GSPixelIs(result, 8, 55, 0, 255, 0), "a magnified source crop selects the higher-resolution rep");

  NSImage *vectorImage = AUTORELEASE([[NSImage alloc] initWithSize: NSMakeSize(16, 16)]);
  ScaleVectorRep *vector = AUTORELEASE([ScaleVectorRep new]);
  [vector setSize: NSMakeSize(16, 16)];
  [vector setPixelsWide: NSImageRepMatchesDevice];
  [vector setPixelsHigh: NSImageRepMatchesDevice];
  [vectorImage addRepresentation: vector];
  render(vectorImage, 1, NO);
  NSUInteger first = vector->draws;
  result = render(vectorImage, 2, NO);
  PASS(first > 0 && vector->draws > first,
    "a vector representation renders again after the context changes scale");
  PASS(GSPixelIs(result, 16, 47, 0, 0, 255), "the vector rep draws at the new scale");
  END_SET("NSImage scale drawing")
  return 0;
}
