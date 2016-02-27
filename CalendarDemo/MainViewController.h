//
//  MainViewController.h
//  CalendarDemo - Graphical Calendars Library for iOS
//
//  Copyright (c) 2014-2015 Julien Martin. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <EventKitUI/EventKitUI.h>


@protocol CalendarViewControllerNavigation <NSObject>

@property (nonatomic, readonly) NSDate* centerDate;

- (void)moveToDate:(NSDate*)date animated:(BOOL)animated;
- (void)moveToNextPageAnimated:(BOOL)animated;
- (void)moveToPreviousPageAnimated:(BOOL)animated;

@optional

@property (nonatomic) NSSet* visibleCalendars;

@end


typedef  UIViewController<CalendarViewControllerNavigation> CalendarViewController;


@protocol CalendarViewControllerDelegate <NSObject>

@optional

- (void)calendarViewController:(CalendarViewController*)controller didShowDate:(NSDate*)date;
- (void)calendarViewController:(CalendarViewController*)controller didSelectEvent:(EKEvent*)event;

@end



@interface MainViewController : UIViewController<CalendarViewControllerDelegate, EKCalendarChooserDelegate>

@property (nonatomic) CalendarViewController* calendarViewController;

@property (nonatomic, weak) IBOutlet UIView *containerView;
@property (nonatomic, weak) IBOutlet UILabel *currentDateLabel;
@property (nonatomic, weak) IBOutlet UIBarButtonItem *settingsButtonItem;
@property (nonatomic, weak) IBOutlet UISegmentedControl *viewChooser;

@property (nonatomic) NSCalendar *calendar;
@property (nonatomic) EKEventStore *eventStore;

@end
