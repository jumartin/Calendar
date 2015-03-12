//
//  YearViewController.h
//  CalendarDemo - Graphical Calendars Library for iOS
//
//  Copyright (c) 2014-2015 Julien Martin. All rights reserved.
//

#import "MGCYearCalendarView.h"
#import "MainViewController.h"


@class YearViewController;

@protocol YearViewControllerDelegate<CalendarViewControllerDelegate>

@optional

- (void)yearViewController:(YearViewController*)controller didSelectMonthAtDate:(NSDate*)date;

@end

/////////////
@interface YearViewController : UIViewController <CalendarViewControllerNavigation, MGCYearCalendarViewDelegate>

@property (nonatomic, readonly) MGCYearCalendarView* yearCalendarView;

@property (nonatomic) NSCalendar *calendar;
@property (nonatomic, weak) id<YearViewControllerDelegate> delegate;

@end


