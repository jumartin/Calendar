//
//  MonthSettingsViewController.h
//  CalendarDemo - Graphical Calendars Library for iOS
//
//  Copyright (c) 2014-2015 Julien Martin. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MGCMonthPlannerView.h"

@protocol MonthSettingsViewControllerDelegate;


@interface MonthSettingsViewController : UITableViewController

@property (nonatomic) MGCMonthPlannerView *monthPlannerView;

@end
