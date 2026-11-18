#import "GSClassicTheme.h"
@implementation GSClassicTheme
- (NSString *)name { return @"Classic"; }
@end

Class GSThemeProvider_Classic(void)
{
  return [GSClassicTheme class];
}
