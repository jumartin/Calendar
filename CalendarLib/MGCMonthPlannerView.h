//
//  MGCMonthPlannerView.h
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

#import <UIKit/UIKit.h>
#import "MGCDateRange.h"


@class MGCEventView;

@protocol MGCMonthPlannerViewDataSource;
@protocol MGCMonthPlannerViewDelegate;


//////////////////////////////////////////////////////////////////////////////////////////////
// MGCMonthPlannerView
@interface MGCMonthPlannerView : UIView

/*!
	@abstract	The calendar used for formatting the months and dates.
	@discussion The default value is the logical calendar for the current user (as returned by `[NSCalendar currentCalendar]`)
 */
@property (nonatomic) NSCalendar *calendar;

/*!
	@abstract	Returns the height of a row of days in the month planner view.
	@discussion The default value is 140.
 */
@property (nonatomic) CGFloat rowHeight;

/*!
	@abstract	Returns the height of the header showing days of week.
	@discussion The default value is 35.
				It can be set to 0 to hide the header.
 */
@property (nonatomic) CGFloat headerHeight;

/*!
	@abstract	Returns the height of event cells.
	@discussion The default value is 16.
 */
@property (nonatomic) CGFloat itemHeight;


/*!
	@abstract	The object that provides the data for the month planner view
	@discussion The data source must adopt the `MGCMonthPlannerViewDataSource` protocol.
				The month planner view view maintains a weak reference to the data source object.
 */
@property (nonatomic, weak) id<MGCMonthPlannerViewDataSource> dataSource;

/*!
	@abstract	The object acting as the delegate of the month planner View.
	@discussion The delegate must adopt the `MGCMonthPlannerViewDelegate` protocol. 
				The Calendar View maintains a weak reference to the delegate object.
 */
@property (nonatomic, weak) id<MGCMonthPlannerViewDelegate> delegate;

/*!
	@abstract	Returns the date range of all visible days.
	@discussion Returns nil if no days are shown.
 */
@property (nonatomic, readonly) MGCDateRange *visibleDays;

/*!
	@abstract	Scrollable range of months. Default is nil, for 'infinite' scrolling.
	@discussion The range start date is set to the first day of the month, range end to the first day of the month followind end.
	@discussion If the currently visible month is outside the new range, the view scrolls to the range starting date.
 */
@property (nonatomic, copy) MGCDateRange *dateRange;


- (void)registerClass:(Class)objectClass forEventCellReuseIdentifier:(NSString*)reuseIdentifier;
- (MGCEventView*)dequeueReusableCellWithIdentifier:(NSString*)reuseIdentifier forEventAtIndex:(NSUInteger)index date:(NSDate*)date;
- (void)scrollToDate:(NSDate*)date animated:(BOOL)animated;
- (void)reloadEvents;
- (void)reloadEventsInRange:(MGCDateRange*)range;
- (NSArray*)visibleEventCells;
- (MGCEventView*)cellForEventAtIndex:(NSUInteger)index date:(NSDate*)date;
- (MGCEventView*)eventCellAtPoint:(CGPoint)pt date:(NSDate**)date index:(NSUInteger*)index;
- (NSDate*)dayAtPoint:(CGPoint)pt;
- (void)selectEventCellAtIndex:(NSUInteger)index date:(NSDate*)date;
- (void)deselectEventCellAtIndex:(NSUInteger)index date:(NSDate*)date;
- (void)endInteraction;

@end

//////////////////////////////////////////////////////////////////////////////////////////////
// MGCMonthPlannerViewDataSource
@protocol MGCMonthPlannerViewDataSource<NSObject>

@required

- (NSInteger)monthPlannerView:(MGCMonthPlannerView*)view numberOfEventsAtDate:(NSDate*)date;
- (MGCDateRange*)monthPlannerView:(MGCMonthPlannerView*)view dateRangeForEventAtIndex:(NSUInteger)index date:(NSDate*)date;
- (MGCEventView*)monthPlannerView:(MGCMonthPlannerView*)view cellForEventAtIndex:(NSUInteger)index date:(NSDate*)date;
- (MGCEventView*)monthPlannerView:(MGCMonthPlannerView *)view cellForNewEventAtDate:(NSDate*)date;

@optional

- (BOOL)monthPlannerView:(MGCMonthPlannerView*)view canMoveCellForEventAtIndex:(NSUInteger)index date:(NSDate*)date;

@end

//////////////////////////////////////////////////////////////////////////////////////////////
// MGCMonthPlannerViewDelegate
@protocol MGCMonthPlannerViewDelegate<NSObject>

@optional

- (void)monthPlannerViewDidScroll:(MGCMonthPlannerView*)view;
- (BOOL)monthPlannerView:(MGCMonthPlannerView*)view shouldSelectEventAtIndex:(NSUInteger)index date:(NSDate*)date;
- (void)monthPlannerView:(MGCMonthPlannerView*)view didSelectEventAtIndex:(NSUInteger)index date:(NSDate*)date;
- (BOOL)monthPlannerView:(MGCMonthPlannerView*)view shouldDeselectEventAtIndex:(NSUInteger)index date:(NSDate*)date;
- (void)monthPlannerView:(MGCMonthPlannerView*)view didDeselectEventAtIndex:(NSUInteger)index date:(NSDate*)date;
- (void)monthPlannerView:(MGCMonthPlannerView*)view didSelectDayCellAtDate:(NSDate*)date;
- (void)monthPlannerView:(MGCMonthPlannerView*)view didShowCell:(MGCEventView*)cell forNewEventAtDate:(NSDate*)date;
- (void)monthPlannerView:(MGCMonthPlannerView*)view willStartMovingEventAtIndex:(NSUInteger)index date:(NSDate*)date;
- (void)monthPlannerView:(MGCMonthPlannerView*)view didMoveEventAtIndex:(NSUInteger)index date:(NSDate*)dateOld toDate:(NSDate*)dayNew;

@end
