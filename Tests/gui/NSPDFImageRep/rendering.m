#import "Testing.h"
#import "../../../Source/config.h"
#import "../GSDrawTest.h"

/* A half-point line tests re-rendering rather than magnifying a 72-dpi raster.
 * The red lower-left square also checks the PDF/bitmap coordinate conversion. */
static NSData *pdfData(void)
{
  NSString *stream = @"0 0 0 rg 4.25 0 0.5 16 re f\n1 0 0 rg 0 0 2 2 re f\nq /GS1 gs 0.2 0.4 0.6 rg 8 0 4 4 re f Q\n";
  NSArray *objects = [NSArray arrayWithObjects:
    @"<< /Type /Catalog /Pages 2 0 R >>",
    @"<< /Type /Pages /Kids [3 0 R] /Count 1 >>",
    @"<< /Type /Page /Parent 2 0 R /MediaBox [0 0 16 16] /Resources << /ExtGState << /GS1 << /Type /ExtGState /ca 0.5 /CA 0.5 >> >> >> /Contents 4 0 R >>",
    [NSString stringWithFormat: @"<< /Length %lu >>\nstream\n%@endstream",
      (unsigned long)[stream length], stream], nil];
  NSMutableString *pdf = [NSMutableString stringWithString: @"%PDF-1.4\n"];
  NSMutableArray *offsets = [NSMutableArray array];
  NSUInteger i;
  for (i = 0; i < [objects count]; i++)
    {
      [offsets addObject: [NSNumber numberWithUnsignedInteger: [pdf length]]];
      [pdf appendFormat: @"%lu 0 obj\n%@\nendobj\n", (unsigned long)i + 1,
        [objects objectAtIndex: i]];
    }
  NSUInteger xref = [pdf length];
  [pdf appendString: @"xref\n0 5\n0000000000 65535 f \n"];
  for (i = 0; i < [offsets count]; i++)
    [pdf appendFormat: @"%010lu 00000 n \n",
      (unsigned long)[[offsets objectAtIndex: i] unsignedIntegerValue]];
  [pdf appendFormat: @"trailer\n<< /Size 5 /Root 1 0 R >>\nstartxref\n%lu\n%%%%EOF\n",
    (unsigned long)xref];
  return [pdf dataUsingEncoding: NSASCIIStringEncoding];
}

static NSBitmapImageRep *render(NSImage *image, CGFloat scale)
{
  NSImage *canvas = GSDrawBegin(64, 64);
  NSAffineTransform *transform = [NSAffineTransform transform];
  [[NSColor whiteColor] set];
  NSRectFill(NSMakeRect(0, 0, 64, 64));
  [[NSColor blackColor] set];
  [NSGraphicsContext saveGraphicsState];
  [transform scaleBy: scale];
  [transform concat];
  [image drawInRect: NSMakeRect(0, 0, 16, 16)];
  [NSGraphicsContext restoreGraphicsState];
  return GSDrawEnd(canvas, 64, 64);
}

int main(void)
{
  START_SET("PDF loading and rendering")
#if !HAVE_POPPLER
  SKIP("Poppler PDF image support is not enabled")
#endif
  [NSApplication sharedApplication];
  if (!GSCanDrawOffscreen())
    SKIP("backend cannot read offscreen pixels")
  NSData *data = pdfData();
  PASS(![NSPDFImageRep canInitWithData: [NSData data]], "empty input is safe");
  PASS(![NSPDFImageRep canInitWithData: [@"%P" dataUsingEncoding: NSASCIIStringEncoding]],
    "a short PDF header is safe");
  PASS([NSImageRep imageRepClassForData: data] == [NSPDFImageRep class],
    "the image registry recognizes PDF without ImageMagick");
  NSImage *image = AUTORELEASE([[NSImage alloc] initWithData: data]);
  NSPDFImageRep *rep = [[image representations] firstObject];
  PASS([rep isKindOfClass: [NSPDFImageRep class]] && [rep pageCount] == 1,
    "NSImage loads a PDF page");
  PASS(NSEqualSizes([image size], NSMakeSize(16, 16)), "the PDF media box sets the point size");
  PASS([rep pixelsWide] == NSImageRepMatchesDevice && [rep pixelsHigh] == NSImageRepMatchesDevice,
    "PDF representations stay device independent");
  PASS([[rep PDFRepresentation] isEqual: data], "original PDF data is retained");
  NSBitmapImageRep *pixels = render(image, 1);
  PASS(GSPixelIs(pixels, 0, 63, 255, 0, 0), "the lower-left red square has the right orientation");
  PASS(GSPixelIs(pixels, 10, 55, 255, 255, 255), "unpainted PDF areas stay transparent");
  PASS(GSPixelIs(pixels, 9, 62, 153, 179, 204),
    "translucent PDF colors retain premultiplied alpha when composited");
  pixels = render(image, 4);
  PASS(GSPixelIs(pixels, 17, 32, 0, 0, 0) && GSPixelIs(pixels, 18, 32, 0, 0, 0),
    "a half-point PDF line is two sharp pixels at 4x");
  PASS(GSPixelIs(pixels, 16, 32, 255, 255, 255) && GSPixelIs(pixels, 19, 32, 255, 255, 255),
    "the 4x line has no enlarged 1x raster fringe");
  pixels = render(image, 1);
  PASS(GSPixelIs(pixels, 0, 63, 255, 0, 0), "returning to 1x renders correctly");
  NSImage *copy = [image copy];
  [image removeRepresentation: rep];
  pixels = render(copy, 4);
  PASS(GSPixelIs(pixels, 17, 32, 0, 0, 0), "a copied PDF image retains a usable page");
  [copy setTemplate: YES];
  pixels = render(copy, 4);
  PASS(GSPixelIs(pixels, 17, 32, 0, 0, 0) && GSPixelIs(pixels, 18, 32, 0, 0, 0),
    "PDF template masks render the line at the destination density");
  PASS(GSPixelIs(pixels, 16, 32, 255, 255, 255) && GSPixelIs(pixels, 19, 32, 255, 255, 255),
    "PDF template masks do not blur a magnified 72-dpi raster");
  RELEASE(copy);
  END_SET("PDF loading and rendering")
  return 0;
}
