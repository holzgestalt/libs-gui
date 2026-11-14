/* Scoped test doubles for application-linked themes. Production setTheme:
   intentionally cannot replace an application's compiled provider. */
#ifndef GSThemeTest_h
#define GSThemeTest_h
#import <GNUstepGUI/GSTheme.h>
#include <objc/runtime.h>
#include <stdlib.h>

static GSTheme *gsTestTheme;
static IMP gsOriginalThemeGetter;
static id gsThemeForTest(id receiver, SEL selector) { return gsTestTheme; }

static inline void GSTestSetTheme(GSTheme *theme)
{
  if (!gsOriginalThemeGetter)
    gsOriginalThemeGetter = method_setImplementation(class_getClassMethod([GSTheme class], @selector(theme)), (IMP)gsThemeForTest);
  ASSIGN(gsTestTheme, theme);
}
static inline void GSTestRestoreTheme(void)
{
  if (gsOriginalThemeGetter)
    method_setImplementation(class_getClassMethod([GSTheme class], @selector(theme)), gsOriginalThemeGetter);
  gsOriginalThemeGetter = NULL;
  DESTROY(gsTestTheme);
}
/* Hooks must not add instance state: the real drawing provider is the base. */
static inline Class GSTestThemeSubclass(Class provider, Class hooks, const char *name)
{
  NSCAssert(class_getInstanceSize(hooks) == class_getInstanceSize(class_getSuperclass(hooks)),
    @"Theme hook classes must not add instance state");
  Class result = objc_allocateClassPair(provider, name, 0);
  unsigned count = 0, i;
  Method *methods = class_copyMethodList(hooks, &count);
  for (i = 0; i < count; i++)
    class_addMethod(result, method_getName(methods[i]), method_getImplementation(methods[i]), method_getTypeEncoding(methods[i]));
  free(methods);
  objc_registerClassPair(result);
  return result;
}
#endif
