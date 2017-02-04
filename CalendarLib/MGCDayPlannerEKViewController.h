//
//  MGCDayPlannerEKViewController.h
//  Graphical Calendars Library for iOS
//
//  Distributed under the MIT License
//  Get the latest version from here:
//
//	https://github.com/jumartin/Calendar
//
//  Copyright (c) 2014-2015 Julien Martin
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all
//  copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//  SOFTWARE.
//

#import <EventKit/EventKit.h>
#import <EventKitUI/EventKitUI.h>
#import "MGCDayPlannerViewController.h"


@protocol MGCDayPlannerEKViewControllerDelegate;


@interface MGCDayPlannerEKViewController : MGCDayPlannerViewController<UIPopoverPresentationControllerDelegate>

@property (nonatomic) NSCalendar *calendar;
@property (nonatomic) NSSet *visibleCalendars;
@property (nonatomic, readonly) EKEventStore *eventStore;
@property (nonatomic, weak) id<MGCDayPlannerEKViewControllerDelegate> delegate;

/** designated initializer */
- (instancetype)initWithEventStore:(EKEventStore*)eventStore;
- (void)reloadEvents;

- (EKEvent*)eventOfType:(MGCEventType)type atIndex:(NSUInteger)index date:(NSDate*)date;

@end


@protocol MGCDayPlannerEKViewControllerDelegate<NSObject>


@optional

- (void)dayPlannerEKEViewController:(MGCDayPlannerEKViewController*)vc willPresentEventViewController:(EKEventViewController*)eventViewController;                                     
- (UINavigationController*)dayPlannerEKViewController:(MGCDayPlannerEKViewController*)vc navigationControllerForPresentingEventViewController:(EKEventViewController*)eventViewController;

@end
