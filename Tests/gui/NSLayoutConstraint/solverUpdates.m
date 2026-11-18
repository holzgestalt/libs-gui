#import "Testing.h"
#import "../../../Source/GSCassowarySolver.h"

@interface GSCassowarySolver (OptimizationTest)
- (void) optimize: (GSCSVariable *)objective;
@end

@interface CountingSolver : GSCassowarySolver
{
@public
  NSUInteger optimizations;
}
@end
@implementation CountingSolver
- (void) optimize: (GSCSVariable *)objective
{
  optimizations++;
  [super optimize: objective];
}
@end

int main(void)
{
  START_SET("Cassowary grouped geometry updates")
  CountingSolver *solver = AUTORELEASE([CountingSolver new]);
  [solver enablePriorityLevels];
  GSCSVariable *x = [GSCSVariable variableWithValue: 0 name: @"x"];
  GSCSVariable *y = [GSCSVariable variableWithValue: 0 name: @"y"];
  GSCSConstraint *old = [GSCSConstraint constraintWithLeftVariable: x
    operator: GSCSConstraintOperatorEqual rightConstant: 10];
  [solver addConstraint: old];
  GSCSConstraint *same = [GSCSConstraint constraintWithLeftVariable: y
    operator: GSCSConstraintOperatorEqual rightVariable: x];
  GSCSConstraint *replacement = [GSCSConstraint constraintWithLeftVariable: x
    operator: GSCSConstraintOperatorEqual rightConstant: 20];
  GSCSConstraint *preference = [GSCSConstraint constraintWithLeftVariable: y
    operator: GSCSConstraintOperatorEqual rightConstant: 5];
  [preference setStrength: [GSCSStrength strengthWeak]];
  solver->optimizations = 0;
  [solver beginUpdates];
  [solver removeConstraint: old];
  [solver beginUpdates];
  [solver addConstraint: same];
  [solver addConstraint: replacement];
  [solver endUpdates];
  [solver addConstraint: preference];
  PASS(solver->optimizations == 0, "nested geometry updates defer objective optimization")
  [solver endUpdates];
  GSCSSolution *result = [solver solve];
  PASS(solver->optimizations == 1
    && fabs([[result resultForVariable: x] doubleValue] - 20) < .01
    && fabs([[result resultForVariable: y] doubleValue] - 20) < .01,
    "mixed removals/additions optimize once and preserve required constraints")
  [solver beginUpdates];
  [solver endUpdates];
  PASS(solver->optimizations == 1, "unchanged geometry does not trigger another optimization")
  [solver removeConstraint: replacement];
  result = [solver solve];
  PASS(fabs([[result resultForVariable: y] doubleValue] - 5) < .01,
    "the ordinary solver path still optimizes after grouped updates")
  END_SET("Cassowary grouped geometry updates")
  return 0;
}
