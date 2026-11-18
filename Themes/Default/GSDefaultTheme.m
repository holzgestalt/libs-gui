/* Opaque default GNUstep provider. No material/compositor dependency. */
#import "GSDefaultTheme.h"
#import "GSDefaultDrawing.h"

/* Custom reps draw at the destination resolution, rather than scaling bitmaps.
 * Keep their delegates alive in the provider for as long as the image cache. */
@interface GSDefaultSymbol : NSObject
{
  NSString *_symbol;
}
- (id)initWithName:(NSString *)name;
- (BOOL)drawSymbol:(NSCustomImageRep *)rep;
@end

@implementation GSDefaultSymbol
- (id)initWithName:(NSString *)name
{
  if ((self=[super init])) _symbol=[name copy];
  return self;
}
- (void)dealloc { [_symbol release]; [super dealloc]; }
- (BOOL)drawSymbol:(NSCustomImageRep *)rep
{
  NSRect r=NSMakeRect(1,1,[rep size].width-2,[rep size].height-2);
  BOOL selected=[_symbol rangeOfString:@"Selected"].location!=NSNotFound;
  BOOL mixed=[_symbol rangeOfString:@"Mixed"].location!=NSNotFound;
  if ([_symbol hasPrefix:@"GSSwitch"] || [_symbol hasPrefix:@"GSRadio"])
    {
      BOOL radio=[_symbol hasPrefix:@"GSRadio"];
      MacRound(r,radio ? NSHeight(r)/2 : 4,selected || mixed ? MacAccent() : MacGray(1),
        selected || mixed ? MacAccent() : MacBorder());
      if (radio && selected) MacRound(NSInsetRect(r,4,4),20,MacGray(1),nil);
      else if (mixed) MacLine(NSMakePoint(NSMinX(r)+3,NSMidY(r)),NSMakePoint(NSMaxX(r)-3,NSMidY(r)),MacGray(1),2);
      else if (selected) {
        MacLine(NSMakePoint(NSMinX(r)+3,NSMidY(r)),NSMakePoint(NSMidX(r)-1,NSMinY(r)+4),MacGray(1),1.8);
        MacLine(NSMakePoint(NSMidX(r)-1,NSMinY(r)+4),NSMakePoint(NSMaxX(r)-3,NSMaxY(r)-4),MacGray(1),1.8);
      }
    }
  else if ([_symbol hasPrefix:@"MacWindow"])
    {
      NSColor *c=[_symbol hasSuffix:@"Close"] ? [NSColor colorWithCalibratedRed:1 green:0.37 blue:0.34 alpha:1]
        : [_symbol hasSuffix:@"Minimize"] ? [NSColor colorWithCalibratedRed:1 green:0.74 blue:0.18 alpha:1]
        : [NSColor colorWithCalibratedRed:0.16 green:0.79 blue:0.26 alpha:1];
      MacRound(r,NSHeight(r)/2,c,[c blendedColorWithFraction:0.15 ofColor:MacGray(0)]);
    }
  else if ([_symbol isEqual:@"GSMenuSelected"])
    {
      MacLine(NSMakePoint(3,7),NSMakePoint(6,4),MacGray(0.25),1.7);
      MacLine(NSMakePoint(6,4),NSMakePoint(12,11),MacGray(0.25),1.7);
    }
  else if ([_symbol isEqual:@"GSMenuMixed"])
    MacLine(NSMakePoint(3,7),NSMakePoint(12,7),MacGray(0.25),1.7);
  else if ([_symbol rangeOfString:@"Slider"].location!=NSNotFound)
    MacRound(r,MIN(NSWidth(r),NSHeight(r))/2,MacGray(1),MacBorder());
  else if ([_symbol isEqual:@"GSComboArrow"] || [_symbol isEqual:@"common_Nibble"])
    { MacChevron(NSOffsetRect(r,0,3),YES,NO,MacGray(0.35)); MacChevron(NSOffsetRect(r,0,-3),NO,NO,MacGray(0.35)); }
  else if ([_symbol rangeOfString:@"Down"].location!=NSNotFound || [_symbol hasSuffix:@"Expanded"])
    MacChevron(r,NO,NO,MacGray(0.4));
  else if ([_symbol rangeOfString:@"Up"].location!=NSNotFound)
    MacChevron(r,YES,NO,MacGray(0.4));
  else
    {
      CGFloat x=NSMidX(r),y=NSMidY(r);
      CGFloat d=[_symbol rangeOfString:@"Left"].location!=NSNotFound ? -1 : 1;
      MacLine(NSMakePoint(x-1.5*d,y-3),NSMakePoint(x+1.5*d,y),MacGray(0.4),1.5);
      MacLine(NSMakePoint(x+1.5*d,y),NSMakePoint(x-1.5*d,y+3),MacGray(0.4),1.5);
    }
  return YES;
}
@end

@implementation GSDefaultTheme
- (NSString *)name { return @"Default"; }
- (NSDictionary *)infoDictionary
{
  return @{ @"GSThemeDomain": @{
    @"NSInterfaceStyleDefault": @"NSWindows95InterfaceStyle",
    @"NSMenuInterfaceStyle": @"NSWindows95InterfaceStyle",
    @"GSSuppressAppIcon": @YES,
    @"GSBackHandlesWindowDecorations": @YES } };
}
- (NSColorList *)colors
{
  if (!_macColors) {
    _macColors=[[NSColorList alloc] initWithName:@"System"];
    NSDictionary *colors=@{
      @"windowBackgroundColor":MacGray(0.96), @"controlColor":MacGray(0.96),
      @"controlBackgroundColor":MacGray(1), @"textBackgroundColor":MacGray(1),
      @"controlTextColor":MacGray(0.13), @"textColor":MacGray(0.13), @"labelColor":MacGray(0.13),
      @"secondaryLabelColor":MacGray(0.43), @"tertiaryLabelColor":MacGray(0.6), @"quaternaryLabelColor":MacGray(0.72),
      @"disabledControlTextColor":MacGray(0.62), @"controlShadowColor":MacGray(0.8),
      @"controlDarkShadowColor":MacGray(0.7), @"controlHighlightColor":MacGray(0.97),
      @"controlLightHighlightColor":MacGray(1), @"selectedControlColor":MacAccent(),
      @"alternateSelectedControlColor":MacAccent(), @"selectedControlTextColor":MacGray(1),
      @"alternateSelectedControlTextColor":MacGray(1), @"secondarySelectedControlColor":MacGray(0.87),
      @"selectedMenuItemColor":MacAccent(), @"selectedMenuItemTextColor":MacGray(1),
      @"selectedTextBackgroundColor":[NSColor colorWithCalibratedRed:0.72 green:0.84 blue:1 alpha:1],
      @"selectedTextColor":MacGray(0.13), @"keyboardFocusIndicatorColor":MacAccent(),
      @"headerColor":MacGray(0.95), @"headerTextColor":MacGray(0.4), @"gridColor":MacGray(0.89),
      @"scrollBarColor":MacGray(0.95), @"knobColor":MacGray(0.6), @"selectedKnobColor":MacGray(0.45),
      @"windowFrameColor":MacGray(0.94), @"windowFrameTextColor":MacGray(0.2),
      @"_sourceListBackgroundColor":MacGray(0.94), @"separatorColor":MacGray(0.83),
      @"rowBackgroundColor":MacGray(1), @"alternateRowBackgroundColor":MacGray(0.97),
      @"highlightColor":MacGray(1), @"shadowColor":MacGray(0.75),
      @"toolTipColor":MacGray(0.98), @"toolTipTextColor":MacGray(0.18)
    };
    for (NSString *key in colors) [_macColors setColor:[colors objectForKey:key] forKey:key];
  }
  return _macColors;
}
- (NSColor *)colorNamed:(NSString *)name state:(GSThemeControlState)state
{
  if ([name isEqual:@"highlightedTableRowBackgroundColor"]) return MacAccent();
  if ([name isEqual:@"highlightedTableRowTextColor"]) return MacGray(1);
  if ([name isEqual:@"windowBorderColor"]) return MacBorder();
  return [super colorNamed:name state:state];
}
- (void)activate
{
  [super activate];
  if (!_macSymbols) _macSymbols=[NSMutableArray new];
  NSArray *names=@[@"GSSwitch",@"GSSwitchSelected",@"GSSwitchMixed",@"GSRadio",@"GSRadioSelected",
    @"GSMenuArrow",@"NSHighlightedMenuArrow",@"GSMenuSelected",@"GSMenuMixed",@"GSComboArrow",
    @"common_Nibble",@"common_3DArrowDown",@"common_3DArrowUp",@"common_3DArrowLeft",
    @"common_ArrowDown",@"common_ArrowDownH",@"common_ArrowUp",@"common_ArrowUpH",
    @"common_ArrowRight",@"common_ArrowRightH",@"common_ArrowLeft",@"common_ArrowLeftH",
    @"common_outlineCollapsed",@"common_outlineExpanded",@"common_SliderHoriz",@"common_SliderVert",
    @"common_CircularSlider",@"MacWindowClose",@"MacWindowMinimize",@"MacWindowZoom"];
  for (NSString *name in names) {
    GSDefaultSymbol *symbol=[[GSDefaultSymbol alloc] initWithName:name];
    NSCustomImageRep *rep=[[NSCustomImageRep alloc] initWithDrawSelector:@selector(drawSymbol:) delegate:symbol];
    NSSize size=NSMakeSize(16,16); [rep setSize:size];
    NSImage *image=[[NSImage alloc] initWithSize:size];
    [image addRepresentation:rep];
    [image setName:name]; [_macSymbols addObject:image]; [_macSymbols addObject:symbol];
    [image release]; [rep release]; [symbol release];
  }
}
/* The base cell retains all text placement and attributed-title handling.
 * Only the default action's foreground must change with its blue surface. */
- (NSRect)_overrideNSButtonCellMethod_drawTitle:(NSAttributedString *)title
                                    withFrame:(NSRect)frame inView:(NSView *)view
{
  NSButtonCell *cell=(NSButtonCell *)self;
  NSAttributedString *text=title;
  if ([cell isEnabled] && [cell isBordered]
    && ([[cell keyEquivalent] isEqual:@"\r"] || [[cell keyEquivalent] isEqual:@"\n"])) {
    NSMutableAttributedString *colored=[[title mutableCopy] autorelease];
    [colored addAttribute:NSForegroundColorAttributeName value:MacGray(1) range:NSMakeRange(0,[colored length])]; text=colored;
  }
  typedef NSRect (*DrawTitle)(id,SEL,id,NSRect,id);
  DrawTitle original=(DrawTitle)[[GSTheme theme] overriddenMethod:_cmd for:self];
  return original(self,_cmd,text,frame,view);
}
- (void)dealloc { [_macColors release]; [_macSymbols release]; [super dealloc]; }
@end

Class GSThemeProvider_Default(void)
{
  return [GSDefaultTheme class];
}
