#import "Testing.h"
#import <AppKit/AppKit.h>

/* Prototype instances must own their controls and observe their own model. */
int main(void)
{
  START_SET("NSTableCellView prototype copies")
  [NSApplication sharedApplication];
  NSTableCellView *prototype = AUTORELEASE([[NSTableCellView alloc]
    initWithFrame: NSMakeRect(4, 5, 220, 30)]);
  NSTextField *field = AUTORELEASE([[NSTextField alloc] initWithFrame: NSMakeRect(0, 0, 100, 24)]);
  NSView *nested = AUTORELEASE([[NSView alloc] initWithFrame: NSMakeRect(110, 0, 100, 24)]);
  NSTextField *externalField = AUTORELEASE([[NSTextField alloc] initWithFrame: [nested bounds]]);
  NSObject *externalTarget = AUTORELEASE([NSObject new]);
  NSMutableDictionary *model = [NSMutableDictionary dictionaryWithObject: @"shared" forKey: @"name"];
  NSObject *uncodableValue = AUTORELEASE([NSObject new]);
  [prototype addSubview: field];
  [prototype addSubview: nested];
  [nested addSubview: externalField];
  [prototype setTextField: field];
  [prototype setIdentifier: @"List"];
  [prototype setObjectValue: [NSDictionary dictionaryWithObject: @"original" forKey: @"name"]];
  [field bind: NSValueBinding toObject: prototype withKeyPath: @"objectValue.name" options: nil];
  [field setTarget: externalTarget];
  [externalField bind: NSValueBinding toObject: model withKeyPath: @"name" options: nil];

  NSTableCellView *a = AUTORELEASE([prototype copy]);
  NSTableCellView *b = AUTORELEASE([prototype copy]);
  PASS([[a subviews] count] == 2 && [a textField] != field && [a textField] != [b textField],
       "copies independently duplicate the subview hierarchy");
  PASS([[a textField] superview] == a && [field superview] == prototype,
       "outlets point into the copy without moving original controls");
  PASS([[[a textField] infoForBinding: NSValueBinding] objectForKey: NSObservedObjectKey] == a,
       "internal bindings observe the copied cell");
  PASS([[a textField] target] == externalTarget, "external noncoding targets retain their identity");
  [a setObjectValue: [NSDictionary dictionaryWithObject: @"first" forKey: @"name"]];
  [b setObjectValue: [NSDictionary dictionaryWithObject: @"second" forKey: @"name"]];
  PASS([[[a textField] stringValue] isEqual: @"first"]
       && [[[b textField] stringValue] isEqual: @"second"]
       && [[field stringValue] isEqual: @"original"], "model changes stay within their own row");
  NSView *nestedCopy = [[a subviews] objectAtIndex: 1];
  NSTextField *externalCopy = [[nestedCopy subviews] objectAtIndex: 0];
  [model setObject: @"updated" forKey: @"name"];
  PASS([[externalCopy stringValue] isEqual: @"updated"], "nested bindings keep external model connections");
  [field unbind: NSValueBinding];
  [prototype setObjectValue: uncodableValue];
  NSTableCellView *plain = AUTORELEASE([prototype copy]);
  PASS([plain objectValue] == uncodableValue, "copying does not require the represented model to support coding");
  PASS([[a identifier] isEqual: @"List"] && NSEqualRects([a frame], [prototype frame]),
       "copying retains prototype identity and geometry");
  END_SET("NSTableCellView prototype copies")
  return 0;
}
