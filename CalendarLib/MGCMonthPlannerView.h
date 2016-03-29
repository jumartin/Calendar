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

@property (nonatomic, strong) UIColor *calendarBackgroundColor; //Default: [UIColor whiteColor]

@property (nonatomic, strong) UIColor *weekDayBackgroundColor; //Default: [UIColor whiteColor]
@property (nonatomic, strong) UIColor *weekendDayBackgroundColor; //Default: [UIColor colorWithWhite:.97 alpha:.8]

@property (nonatomic, strong) UIColor *weekdaysLabelTextColor; //Default: [UIColor blackColor]
@property (nonatomic, strong) UIColor *monthLabelTextColor; //Default: [UIColor blackColor]
@property (nonatomic, strong) UIFont *monthLabelFont; //Default: [UIFont preferredFontForTextStyle:UIFontTextStyleHeadline];

@property (nonatomic, strong) UIFont *weekdaysLabelFont;
@property (nonatomic, strong) NSArray *weekDaysStringArray;

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

/*!
	@group Managing the selection
 */

/*!
	@abstract	Determines whether users can select events in the month planner view.
	@discussion The default value is YES.
                For more control over the selection of items, you can provide a delegate object and implement the
                monthPlannerView:shouldSelectEventAtIndex:date: methods of the MGCMonthPlannerViewDelegate protocol.
 */
@property (nonatomic) BOOL allowsSelection;

/*!
	@abstract	Returns the date of the selected event, or nil if no event is selected.
 */
@property (nonatomic, readonly) NSDate *selectedEventDate;

/*!
	@abstract	Returns the index of the selected event at the date given by selectedEventDate.
 */
@property (nonatomic, readonly) NSUInteger selectedEventIndex;

/*!
	@abstract	Returns the event view for the current selection, or nil if no event is selected.
 */
@property (nonatomic, readonly) MGCEventView *selectedEventView;

/*!
	@abstract	Selects the visible event view at specified index and date.
	@param		index		The index of the event.
	@param		date		The date of the event.
	@discussion If the allowsSelection property is NO, calling this method has no effect.
                If there is an existing selection, calling this method replaces the previous selection.
	@discussion	This method does not cause any selection-related delegate methods to be called.
 */
- (void)selectEventCellAtIndex:(NSUInteger)index date:(NSDate*)date;

/*!
	@abstract	Cancels current selection.
	@discussion If the allowsSelection property is NO, calling this method has no effect.
	@discussion	This method does not cause any selection-related delegate methods to be called.
 */
- (void)deselectEvent;

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
- (void)monthPlannerView:(MGCMonthPlannerView*)view didSelectDayCellAtDate:(NSDate*)date;
- (void)monthPlannerView:(MGCMonthPlannerView*)view didShowCell:(MGCEventView*)cell forNewEventAtDate:(NSDate*)date;
- (void)monthPlannerView:(MGCMonthPlannerView*)view willStartMovingEventAtIndex:(NSUInteger)index date:(NSDate*)date;
- (void)monthPlannerView:(MGCMonthPlannerView*)view didMoveEventAtIndex:(NSUInteger)index date:(NSDate*)dateOld toDate:(NSDate*)dayNew;

/*!
	@group Managing the selection of events
 */

/*!
	@abstract	Asks the delegate if the specified event should be selected.
	@param		view		The month planner view object making the request.
	@param		index		The index of the event.
	@param		date		The day of the event.
	@return		YES if the event should be selected or NO if it should not.
	@discussion	The month planner view calls this method when the user tries to select an event. 
                It does not call this method when you programmatically set the selection.
	@discussion	If you do not implement this method, the default return value is YES.
 */
- (BOOL)monthPlannerView:(MGCMonthPlannerView*)view shouldSelectEventAtIndex:(NSUInteger)index date:(NSDate*)date;

/*!
	@abstract	Tells the delegate that the specified event was selected.
	@param		view		The month planner view object notifying about the selection change.
	@param		index		The index of the event.
	@param		date		The day of the event.
	@return		YES if the event should be selected or NO if it should not.
	@discussion	The month planner view calls this method when the user successfully selects an event. 
                It does not call this method when you programmatically set the selection.
 */
- (void)monthPlannerView:(MGCMonthPlannerView*)view didSelectEventAtIndex:(NSUInteger)index date:(NSDate*)date;

/*!
	@abstract	Asks the delegate if the specified event should be deselected.
	@param		view		The month planner view object notifying about the selection change.
	@param		index		The index of the event.
	@param		date		The day of the event.
	@return		YES if the event should be selected or NO if it should not.
	@discussion	The month planner view calls this method when the user tries to deselect an already selected event.
                It does not call this method when you programmatically set the selection.
 */
- (BOOL)monthPlannerView:(MGCMonthPlannerView*)view shouldDeselectEventAtIndex:(NSUInteger)index date:(NSDate*)date;

/*!
	@abstract	Tells the delegate that the specified event was deselected.
	@param		view		The month planner view object notifying about the selection change.
	@param		index		The index of the event.
	@param		date		The day of the event.
	@return		YES if the event should be selected or NO if it should not.
	@discussion This does not get called when you programmatically deselect an event with the deselectEvent method
 */
- (void)monthPlannerView:(MGCMonthPlannerView*)view didDeselectEventAtIndex:(NSUInteger)index date:(NSDate*)date;

@end
