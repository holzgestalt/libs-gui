/* Opaque, simplified default GNUstep appearance. */
#ifndef _GNUstep_H_GSDefaultTheme
#define _GNUstep_H_GSDefaultTheme
#import <GNUstepGUI/GSTheme.h>
APPKIT_EXPORT_CLASS
@interface GSDefaultTheme : GSTheme
{
  NSColorList *_macColors;
  NSMutableArray *_macSymbols;
}
@end
#endif
