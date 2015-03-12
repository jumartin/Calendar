//
//  WeekViewController.h
//  CalendarDemo - Graphical Calendars Library for iOS
//
//  Copyright (c) 2014-2015 Julien Martin. All rights reserved.
//

#import "MGCDayPlannerEKViewController.h"
#import "MainViewController.h"


@interface WeekViewController : MGCDayPlannerEKViewController <CalendarViewControllerNavigation>

@property (nonatomic, weak) id<CalendarViewControllerDelegate> delegate;

@end
