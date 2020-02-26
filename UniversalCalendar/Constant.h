

#ifndef CalendarDemo_Constant_h
#define CalendarDemo_Constant_h

//=========================================================================================
/* CREATE ALL CONSTANT FOR APP */
//=========================================================================================


#define APP_NAME  @"CalendarDemo"

#define IS_IPHONE_4S        [[UIScreen mainScreen] bounds].size.height == 480
#define IS_IPHONE_5         [[UIScreen mainScreen] bounds].size.height == 568
#define IS_IPHONE_6         [[UIScreen mainScreen] bounds].size.height == 667
#define IS_IPHONE_6_PLUS    [[UIScreen mainScreen] bounds].size.height == 736

#define DeviceHeight   [UIScreen mainScreen].bounds.size.height
#define DeviceWidth    [UIScreen mainScreen].bounds.size.width
#define IOS7VERSION ([[[UIDevice currentDevice] systemVersion] floatValue]>=7.0?YES:NO)


#define SYSTEM_VERSION_EQUAL_TO(v)                  ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] == NSOrderedSame)
#define SYSTEM_VERSION_GREATER_THAN(v)              ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] == NSOrderedDescending)
#define SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(v)  ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] != NSOrderedAscending)
#define SYSTEM_VERSION_LESS_THAN(v)                 ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] == NSOrderedAscending)
#define SYSTEM_VERSION_LESS_THAN_OR_EQUAL_TO(v)     ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] != NSOrderedDescending)

#define RGBCOLOR(r, g, b)       [UIColor colorWithRed:(r)/255.0f green:(g)/255.0f blue:(b)/255.0f alpha:1]
#define RGBA(r, g, b, a) [UIColor colorWithRed:(float)r / 255.0f green:(float)g / 255.0f blue:(float)b / 255.0f alpha:a]
#define UIColorFromRGB(rgbValue) [UIColor colorWithRed:((float)((rgbValue & 0xFF0000) >> 16))/255.0 green:((float)((rgbValue & 0xFF00) >> 8))/255.0 blue:((float)(rgbValue & 0xFF))/255.0 alpha:1.0]



//define font
#define font10 [UIFont systemFontOfSize:10.0];
#define font12 [UIFont systemFontOfSize:12.0];
#define font13 [UIFont systemFontOfSize:13.0];
#define font14 [UIFont systemFontOfSize:14.0];
#define font15 [UIFont systemFontOfSize:15.0];
#define font16 [UIFont systemFontOfSize:16.0];
#define font17 [UIFont systemFontOfSize:17.0];
#define font18 [UIFont systemFontOfSize:18.0];
#define font24 [UIFont systemFontOfSize:24.0];
#define font12Bold [UIFont fontWithName:@"Helvetica-Bold" size:12.0];
#define font13Bold [UIFont fontWithName:@"Helvetica-Bold" size:13.0];
#define font14Bold [UIFont fontWithName:@"Helvetica-Bold" size:14.0];
#define font15Bold [UIFont fontWithName:@"Helvetica-Bold" size:15.0];
#define font17Bold [UIFont fontWithName:@"Helvetica-Bold" size:17.0];
#define font18Bold [UIFont fontWithName:@"Helvetica-Bold" size:18.0];
#define APPEngine  [IMEngine shareEngine]


#define IDIOM    UI_USER_INTERFACE_IDIOM()
#define IPAD     UIUserInterfaceIdiomPad


#define isiPad (IDIOM == IPAD ? YES:NO)

#define kHeaderHeight 100


#endif
