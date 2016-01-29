//
//  WeekViewController.m
//  CalendarDemo - Graphical Calendars Library for iOS
//
//  Copyright (c) 2014-2015 Julien Martin. All rights reserved.
//

#import "WeekViewController.h"
#import "MGCDateRange.h"
#import "NSCalendar+MGCAdditions.h"
#import "NSAttributedString+MGCAdditions.h"


@implementation WeekViewController


#pragma mark - UIViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	    
	self.dayPlannerView.backgroundColor = [UIColor clearColor];
	self.dayPlannerView.backgroundView = [UIView new];
	self.dayPlannerView.backgroundView.backgroundColor = [UIColor whiteColor];
	self.dayPlannerView.dateFormat = @"eeeee\nd MMM";
	self.dayPlannerView.dayHeaderHeight = 50;
}

#pragma mark - MGCDayPlannerViewController

- (BOOL)dayPlannerView:(MGCDayPlannerView*)view canCreateNewEventOfType:(MGCEventType)type atDate:(NSDate*)date
{
	NSDateComponents *comps = [self.calendar components:NSWeekdayCalendarUnit fromDate:date];
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
	NSDateComponents *comps = [self.calendar components:NSWeekdayCalendarUnit fromDate:targetDate];
	return (comps.weekday != 1 && comps.weekday != 7);
}

/*
// test for custom time drawing
- (NSAttributedString*)dayPlannerView:(MGCDayPlannerView *)view attributedStringForTimeMark:(MGCDayPlannerTimeMark)mark time:(NSTimeInterval)ti
{
    if (mark == MGCDayPlannerTimeMarkFloating) return nil;
    
    NSDate *date = [NSDate dateWithTimeInterval:ti sinceDate:[self.calendar mgc_startOfDayForDate:[NSDate date]]];
    
    NSMutableParagraphStyle *style = [NSMutableParagraphStyle new];
    style.alignment = NSTextAlignmentRight;
   
    UIColor *color = mark == MGCDayPlannerTimeMarkHeader ? [UIColor lightGrayColor] : [UIColor redColor];
 
    static NSDateFormatter *dateFormatter = nil;
    if (dateFormatter == nil) {
        dateFormatter = [NSDateFormatter new];
    }
    dateFormatter.dateFormat = mark == MGCDayPlannerTimeMarkHeader ? @"h a" : @"h:mm a";
    
    
    NSString *s = [dateFormatter stringFromDate:date];
    return [[NSAttributedString alloc]initWithString:s attributes:@{ NSParagraphStyleAttributeName: style, NSFontAttributeName: [UIFont systemFontOfSize:12], NSForegroundColorAttributeName: color }];
}
*/

- (NSAttributedString*)dayPlannerView:(MGCDayPlannerView *)view attributedStringForDayHeaderAtDate:(NSDate *)date
{
    UIFont *font = [UIFont systemFontOfSize:15];
 
    static NSDateFormatter *dateFormatter = nil;
    if (dateFormatter == nil) {
        dateFormatter = [NSDateFormatter new];
        dateFormatter.dateFormat = @"eee d";
    }
    
    NSString *dayStr = [dateFormatter stringFromDate:date];
    
    NSMutableAttributedString *attrStr = [[NSMutableAttributedString alloc]initWithString:dayStr attributes:@{ NSFontAttributeName: font }];
    
    if ([self.calendar mgc_isDate:date sameDayAsDate:[NSDate date]]) {
        UIFont *boldFont = [UIFont boldSystemFontOfSize:15];
        
        NSMutableParagraphStyle *para = [NSMutableParagraphStyle new];
        para.alignment = NSTextAlignmentCenter;
        
        MGCCircleMark *mark = [MGCCircleMark new];
        mark.yOffset = boldFont.descender - mark.margin;
 
        [attrStr addAttributes:@{ NSFontAttributeName: boldFont, NSForegroundColorAttributeName: [UIColor whiteColor], MGCCircleMarkAttributeName: mark, NSParagraphStyleAttributeName: para } range:NSMakeRange(4, dayStr.length - 4)];

        [attrStr processCircleMarksInRange:NSMakeRange(0, attrStr.length)];
    }
    
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
