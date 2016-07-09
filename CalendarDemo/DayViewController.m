//
//  DayViewController.h
//  Calendar
//
//  Copyright © 2016 Julien Martin. All rights reserved.
//

#import "DayViewController.h"
#import "MGCDateRange.h"
#import "NSCalendar+MGCAdditions.h"
#import "NSAttributedString+MGCAdditions.h"
#import "Constant.h"
#import "MGCCalendarHeaderView.h"

@implementation DayViewController

@dynamic delegate;

#pragma mark - UIViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.dayPlannerView.backgroundColor = [UIColor clearColor];
    self.dayPlannerView.backgroundView = [UIView new];
    self.dayPlannerView.backgroundView.backgroundColor = [UIColor whiteColor];
    
    if (isiPad) {
        //NSLog(@"---------------- iPAD ------------------");
        self.dayPlannerView.dateFormat = @"eee\nd MMM";
        self.dayPlannerView.dayHeaderHeight = 50;
    }
    else{
        //NSLog(@"---------------- iPhone ------------------");
        self.dayPlannerView.dateFormat = @"eee\nd \nMMM";
        self.dayPlannerView.dayHeaderHeight = 60;
    }
}

#pragma mark - MGCDayPlannerViewController

- (BOOL)dayPlannerView:(MGCDayPlannerView*)view canCreateNewEventOfType:(MGCEventType)type atDate:(NSDate*)date
{
    NSDateComponents *comps = [self.calendar components:NSCalendarUnitWeekday fromDate:date];
    return comps.weekday != 1;
}

- (void)dayPlannerView:(MGCDayPlannerView*)view didScroll:(MGCDayPlannerScrollType)scrollType
{
    NSDate *date = [view dateAtPoint:view.center rounded:YES];
    if (date && [self.delegate respondsToSelector:@selector(calendarViewController:didShowDate:)]) {
        [self.delegate calendarViewController:self didShowDate:date];
    }
}

- (BOOL)dayPlannerView:(MGCDayPlannerView*)view canMoveEventOfType:(MGCEventType)type atIndex:(NSUInteger)index date:(NSDate*)date toType:(MGCEventType)targetType date:(NSDate*)targetDate
{
    NSDateComponents *comps = [self.calendar components:NSCalendarUnitWeekday fromDate:targetDate];
    return (comps.weekday != 1 && comps.weekday != 7);
}

- (NSAttributedString*)dayPlannerView:(MGCDayPlannerView *)view attributedStringForDayHeaderAtDate:(NSDate *)date
{
    
    static NSDateFormatter *dateFormatter = nil;
    if (dateFormatter == nil) {
        dateFormatter = [NSDateFormatter new];
        dateFormatter.dateFormat = @"eee d";
    }
    
    NSString *dayStr = [dateFormatter stringFromDate:date];
    
    UIFont *font = [UIFont systemFontOfSize:15];
    NSMutableAttributedString *attrStr = [[NSMutableAttributedString alloc]initWithString:dayStr attributes:@{ NSFontAttributeName: font }];
    
    if ([self.calendar mgc_isDate:date sameDayAsDate:[NSDate date]]) {
        UIFont *boldFont = [UIFont boldSystemFontOfSize:15];
        
        MGCCircleMark *mark = [MGCCircleMark new];
        mark.yOffset = boldFont.descender - mark.margin;
        
        NSUInteger dayStringStart = [dayStr rangeOfString:@" "].location + 1;
        [attrStr addAttributes:@{ NSFontAttributeName: boldFont, NSForegroundColorAttributeName: [UIColor whiteColor], MGCCircleMarkAttributeName: mark } range:NSMakeRange(dayStringStart, dayStr.length - dayStringStart)];
        
        [attrStr processCircleMarksInRange:NSMakeRange(0, attrStr.length)];
    }
    
    NSMutableParagraphStyle *para = [NSMutableParagraphStyle new];
    para.alignment = NSTextAlignmentCenter;
    [attrStr addAttribute:NSParagraphStyleAttributeName value:para range:NSMakeRange(0, attrStr.length)];
    
    return attrStr;
}

#pragma mark - CalendarControllerNavigation

- (void)moveToDate:(NSDate*)date animated:(BOOL)animated
{
    if (!self.dayPlannerView.dateRange || [self.dayPlannerView.dateRange containsDate:date]) {
        [self.dayPlannerView scrollToDate:date options:MGCDayPlannerScrollDateTime animated:animated];
    }
}

- (void)moveToNextPageAnimated:(BOOL)animated
{
    NSDate *date;
    [self.dayPlannerView pageForwardAnimated:animated date:&date];
    //NSLog(@"paging forward to %@", date);
}

- (void)moveToPreviousPageAnimated:(BOOL)animated
{
    NSDate *date;
    [self.dayPlannerView pageBackwardsAnimated:animated date:&date];
    //NSLog(@"paging backwards to %@", date);
}

- (NSDate*)centerDate
{
    NSDate *date = [self.dayPlannerView dateAtPoint:self.dayPlannerView.center rounded:NO];
    return date;
}

@end
