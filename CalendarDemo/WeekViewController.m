//
//  WeekViewController.m
//  CalendarDemo - Graphical Calendars Library for iOS
//
//  Copyright (c) 2014-2015 Julien Martin. All rights reserved.
//

#import "WeekViewController.h"
#import "MGCDateRange.h"


@implementation WeekViewController


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
