//
//  MonthViewController.h
//  CalendarDemo - Graphical Calendars Library for iOS
//
//  Copyright (c) 2014-2015 Julien Martin. All rights reserved.
//

#import "MGCMonthPlannerEKViewController.h"
#import "MainViewController.h"


@interface MonthViewController : MGCMonthPlannerEKViewController <CalendarViewControllerNavigation>

@property (nonatomic, weak) id<CalendarViewControllerDelegate> delegate;

@end
