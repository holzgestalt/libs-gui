#import <Foundation/Foundation.h>
int main(void)
{
  NSAutoreleasePool *pool=[NSAutoreleasePool new];
  NSLog(@"Foundation-only tool");
  [pool drain];
  return 0;
}
