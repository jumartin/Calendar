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


typedef enum : NSUInteger {
    MGCMonthHeaderStyleDefault = 0,
    MGCMonthHeaderStyleShort = 1 << 0,
    MGCMonthHeaderStyleHidden = 1 << 1
} MGCMonthHeaderStyle;

typedef enum : NSUInteger {
    MGCMonthPlannerGridStyleFill = 1 << 0,
    MGCMonthPlannerGridStyleVerticalLines = 1 << 1,
    MGCMonthPlannerGridStyleHorizontalLines = 1 << 2,
    MGCMonthPlannerGridStyleDefault = (MGCMonthPlannerGridStyleHorizontalLines|MGCMonthPlannerGridStyleVerticalLines)
} MGCMonthPlannerGridStyle;

typedef enum : NSUInteger {
    MGCMonthPlannerStyleEvents = 0,
    MGCMonthPlannerStyleDots = 1,
    MGCMonthPlannerStyleEmpty = 2
} MGCMonthPlannerStyle;


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
	@abstract	Returns the height of the header in day cells which displays the date.
	@discussion The default value is 30.
 */
@property (nonatomic) CGFloat dayCellHeaderHeight;

/*!
	@abstract	The distance between each months and between the months and the edge of the view.
 */
@property (nonatomic) UIEdgeInsets monthInsets;

/*!
	@abstract	Returns the style for the months headers.
	@discussion If set to MGCMonthHeaderStyleDefault, the header displays the month name and the year.
                If set to MGCMonthHeaderStyleShort, the header only displays the month name.
                If set to MGCMonthHeaderStyleHidden, the header is hidden
    @discussion The alignment of the header changes depending on the value of the gridStyle property.
    @see        gridStyle
 
 */
@property (nonatomic) MGCMonthHeaderStyle monthHeaderStyle;

/*!
	@abstract	Returns the style of the month planner view.
    @discussion If set to MGCMonthPlannerStyleEvents, the view displays events cells, similar to the month view in Apple's Calendar app on iPad.
                If set to MGCMonthPlannerStyleDots, the view only displays dots for days with events, similar to the month view in Apple's Calendar app on iPhone.
                If set to MGCMonthPlannerStyleEmpty, the view does not display events nor dots.
	@discussion The default value is MGCMonthPlannerStyleEvents on regular horizontal size, MGCMonthPlannerStyleDots otherwise.
 */
@property (nonatomic) MGCMonthPlannerStyle style;

/*!
	@abstract	Returns the color of the dot displayed when the month planner view style is set to MGCMonthPlannerStyleDots.
 */
@property (nonatomic) UIColor *eventsDotColor;

/*!
	@abstract	Returns the style of the months' background grid.
    @discussion If MGCMonthPlannerGridStyleFill is set, the view fills the grid for the first and last week of the month, and the month header, if displayed, is center-aligned.
                Otherwise, the grid covers only the days of the months, and the month header, if displayed, is aligned on the first day.
*/
@property (nonatomic) MGCMonthPlannerGridStyle gridStyle;

/*!
	@abstract	String format for dates displayed on top of day cells.
	@discussion If the value of this property is nil, a default format of @"d MMM YYYY" is used.
	@see		NSDateFormatter dateFormat
 */
@property (nonatomic, copy) NSString *dateFormat;

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
- (void)reloadEventsAtDate:(NSDate*)date;
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

/*!
	@abstract   Asks the delegate for the attributed string of the day header for given date.
    @param		view		The month planner view requesting the information.
	@param		date		The date for the header.
	@return     The attributed string to draw.
 */
- (NSAttributedString*)monthPlannerView:(MGCMonthPlannerView*)view attributedStringForDayHeaderAtDate:(NSDate*)date;

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
