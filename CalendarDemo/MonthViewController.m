//
//  MonthViewController.m
//  CalendarDemo - Graphical Calendars Library for iOS
//
//  Copyright (c) 2014-2015 Julien Martin. All rights reserved.
//

#import "MonthViewController.h"
#import "NSCalendar+MGCAdditions.h"


@implementation MonthViewController

#pragma mark - UIViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.monthPlannerView.dayCellHeaderHeight = 30;
}

#pragma mark - MGCMonthPlannerViewController

- (void)monthPlannerViewDidScroll:(MGCMonthPlannerView *)view
{
	[super monthPlannerViewDidScroll:view];
	
	NSDate *date = [self.monthPlannerView dayAtPoint:self.monthPlannerView.center];
	if (date && [self.delegate respondsToSelector:@selector(calendarViewController:didShowDate:)]) {
		[self.delegate calendarViewController:self didShowDate:date];
	}
}

#pragma mark - CalendarViewControllerNavigation

- (NSDate*)centerDate
{
	MGCDateRange *visibleRange = [self.monthPlannerView visibleDays];
	if (visibleRange)
	{
		NSUInteger dayCount = [self.calendar components:NSCalendarUnitDay fromDate:visibleRange.start toDate:visibleRange.end options:0].day;
		NSDateComponents *comp = [NSDateComponents new];
		comp.day = dayCount / 2;
		NSDate *centerDate = [self.calendar dateByAddingComponents:comp toDate:visibleRange.start options:0];
		return [self.calendar mgc_startOfWeekForDate:centerDate];
	}
	return nil;
}

- (void)moveToDate:(NSDate*)date animated:(BOOL)animated
{
	if ([self.monthPlannerView.dateRange containsDate:date]) {
		return;
	}
	
	[self.monthPlannerView scrollToDate:date animated:animated];
}

- (void)moveToNextPageAnimated:(BOOL)animated
{
	NSDate *date = [self.calendar mgc_nextStartOfMonthForDate:self.monthPlannerView.visibleDays.start];
	[self moveToDate:date animated:animated];
}

- (void)moveToPreviousPageAnimated:(BOOL)animated
{
	NSDate *date = [self.calendar mgc_startOfMonthForDate:self.monthPlannerView.visibleDays.start];
	if ([self.monthPlannerView.visibleDays.start isEqualToDate:date]) {
		NSDateComponents *comps = [NSDateComponents new];
		comps.month = -1;
		date = [self.calendar dateByAddingComponents:comps toDate:date options:0];
	}
	[self moveToDate:date animated:animated];
}

@end
