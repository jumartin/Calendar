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


typedef NS_OPTIONS(NSUInteger, MGCMonthHeaderStyle) {
    MGCMonthHeaderStyleDefault = 0,
    MGCMonthHeaderStyleShort = 1 << 0,
    MGCMonthHeaderStyleHidden = 1 << 1
};

typedef NS_OPTIONS(NSUInteger, MGCMonthPlannerGridStyle) {
    MGCMonthPlannerGridStyleFill = 1 << 0,
    MGCMonthPlannerGridStyleVerticalLines = 1 << 1,
    MGCMonthPlannerGridStyleHorizontalLines = 1 << 2,
    MGCMonthPlannerGridStyleBottomDayLabel = 1 << 3,
    MGCMonthPlannerGridStyleDefault = (MGCMonthPlannerGridStyleHorizontalLines|MGCMonthPlannerGridStyleVerticalLines)
};

typedef NS_ENUM(NSUInteger, MGCMonthPlannerStyle) {
    MGCMonthPlannerStyleEvents = 0,
    MGCMonthPlannerStyleDots = 1,
    MGCMonthPlannerStyleEmpty = 2
};

typedef NS_ENUM(NSUInteger, MGCMonthPlannerPagingMode) {
    MGCMonthPlannerPagingModeNone = 0,
    MGCMonthPlannerPagingModeHeaderTop = 1,
    MGCMonthPlannerPagingModeHeaderBottom = 2
};

typedef NS_ENUM(NSUInteger, MGCMonthPlannerScrollAlignment) {
    MGCMonthPlannerScrollAlignmentHeaderTop = 0,
    MGCMonthPlannerScrollAlignmentHeaderBottom = 1,
    MGCMonthPlannerScrollAlignmentWeekRow = 2
};


/*!
 * MGCMonthPlannerView is a view similar to the month view in the Calendar app on iOS.
 */

@interface MGCMonthPlannerView : UIView


/*!
	@group Configuration and appearance customization
 */


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
	@discussion If the value of this property is nil, a default format is used according to the current locale.
	@see		NSDateFormatter dateFormat
    @see        monthPlannerView:attributedStringForDayHeaderAtDate: delegate method
 */
@property (nonatomic, copy) NSString *dateFormat;

/*!
	@abstract	Returns the height of event cells.
	@discussion The default value is 16.
 */
@property (nonatomic) CGFloat itemHeight;

/*!
	@abstract	Background color for the whole calendar.
	@discussion The default color is white.
 */
@property (nonatomic, strong) UIColor *calendarBackgroundColor;

/*!
	@abstract	Background color for weekday cells.
	@discussion The default color is white.
 */
@property (nonatomic, strong) UIColor *weekDayBackgroundColor;

/*!
	@abstract	Background color for weekend day cells.
	@discussion The default color is light transparent gray.
 */
@property (nonatomic, strong) UIColor *weekendDayBackgroundColor;

/*!
	@abstract	Text color for the weekday headers on the top of the view.
	@discussion The default color is black.
 */
@property (nonatomic, strong) UIColor *weekdaysLabelTextColor;

/*!
	@abstract	Font used for the weekday headers.
 */
@property (nonatomic, strong) UIFont *weekdaysLabelFont;

/*!
	@abstract	Array of strings displayed for the weekday headers.
    @discussion String at index 0 is for Sunday
    @discussion If set to nil, default weekday abbreviations are used (like Mon. or M for Monday, depending of the available size)
 */
@property (nonatomic, strong) NSArray *weekDaysStringArray;

/*!
	@abstract	Text color for the month headers.
	@discussion The default color is black.
    @see        monthHeaderStyle
 */
@property (nonatomic, strong) UIColor *monthLabelTextColor;

/*!
	@abstract	Font used for the month headers.
    @discussion default is [UIFont preferredFontForTextStyle:UIFontTextStyleHeadline]
    @see        monthHeaderStyle
 */
@property (nonatomic, strong) UIFont *monthLabelFont;

/*!
	@abstract	Determines whether an event can be created with a long-press on the view.
	@discussion The default value is YES. This has no effect if the style property of the view is not set to MGCMonthPlannerStyleEvents.
 */
@property (nonatomic) BOOL canCreateEvents;

/*!
	@abstract	Determines whether an event can be moved around after a long-press on the view.
	@discussion The default value is YES. This has no effect if the style property of the view is not set to MGCMonthPlannerStyleEvents.
 */
@property (nonatomic) BOOL canMoveEvents;

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
	@abstract	Scrollable range of months. Default is nil, for 'infinite' scrolling.
	@discussion The range start date is set to the first day of the month, range end to the first day of the month followind end.
	@discussion If the currently visible month is outside the new range, the view scrolls to the range starting date.
 */
@property (nonatomic, copy) MGCDateRange *dateRange;


/*!
	@group Creating event views
 */

/*!
	@abstract	Registers a class for use in creating new event views for the month planner view.
	@param		viewClass	The class of the view that you want to use.
	@param		identifier	The reuse identifier to associate with the specified class.
                            This parameter must not be nil and must not be an empty string.
	@discussion	Prior to calling the dequeueReusableCellWithIdentifier:forEventAtIndex:date: method, you must use this method to tell the month planner how to create a new event view.
 */
- (void)registerClass:(Class)viewClass forEventCellReuseIdentifier:(NSString*)reuseIdentifier;

/*!
	@abstract	Returns a reusable event view object located by its identifier.
	@param		identifier	A string identifying the view object to be reused. This parameter must not be nil.
	@param		index		The index of the event.
	@param		date		The date of the event.
	@return		A valid MGCEventView object.
	@discussion	Call this method from your data source object when asked to provide a new event view for the month planner. This method dequeues an existing view if one is available or creates a new one based on the class you previously registered.
	@warning	You must register a class using the registerClass:forEventCellReuseIdentifier: method before calling this method.
 */
- (MGCEventView*)dequeueReusableCellWithIdentifier:(NSString*)reuseIdentifier forEventAtIndex:(NSUInteger)index date:(NSDate*)date;



/*!
	@group Scrolling and navigation
 */

/*!
	@abstract	The paging style for the view.
	@discussion If set MGCMonthPlannerPagingModeNone, paging is disabled.
                If set to MGCMonthPlannerPagingModeHeaderBottom, scrolling stops below the header.
                If set to MGCMonthPlannerPagingModeHeaderTop, scrolling stops above the header.
 */
@property (nonatomic) MGCMonthPlannerPagingMode pagingMode;


// deprecated: use scrollToDate:position:animated: instead
- (void)scrollToDate:(NSDate*)date animated:(BOOL)animated;

/*!
	@abstract	Scrolls the view to make a given date visible.
	@param		date		The date to scroll into view.
	@param		alignment   If set to MGCMonthPlannerScrollAlignmentWeekRow, the top of the view is aligned with the week row for given date.
                            If set to MGCMonthPlannerScrollAlignmentHeaderBottom, it is aligned with the first row of the month.
                            If set to MGCMonthPlannerScrollAlignmentHeaderTop, it is aligned with the top of the month header.
	@param		animated	Specify YES to animate the scrolling behavior or NO to adjust the visible content immediately.
	@warning	If `date` param is not in the scrollable range of dates, an exception is thrown.
 */
- (void)scrollToDate:(NSDate*)date alignment:(MGCMonthPlannerScrollAlignment)alignment animated:(BOOL)animated;



/*!
	@group Locating days and events
 */


/*!
	@abstract	Returns the date range of all visible days.
	@discussion Returns nil if no days are shown.
 */
@property (nonatomic, readonly) MGCDateRange *visibleDays;

/*!
	@abstract	Returns an array of all visible event views currently displayed by the month planner.
	@return		An array of MGCEventView objects. If no event view is visible, this method returns an empty array.
 */
- (NSArray*)visibleEventCells;


/*!
	@abstract	Returns the visible event view with specified index and date.
	@param		index		The index of the event.
	@param		date		The date of the event.
	@return		The event view or nil if the event view is not visible, or parameters are out of range.
 */
- (MGCEventView*)cellForEventAtIndex:(NSUInteger)index date:(NSDate*)date;

/*!
	@abstract	Returns the event view at the specified point in the month planner view.
	@param		point		A point in the month planner view’s coordinate system.
	@param		date		If not nil, it will contain on return the date of the event located at point.
    @param		index		If not nil, it will contain on return the index of the event located at point.
	@return		The event view at the specified point, or nil if no event was found at the specified point.
 */
- (MGCEventView*)eventCellAtPoint:(CGPoint)pt date:(NSDate**)date index:(NSUInteger*)index;

/*!
	@abstract	Returns the date at the specified point in the month planner view.
	@param		point		A point in the month planner view’s coordinate system.
	@return		The date at the specified point, or nil if the date can't be determined.
*/
- (NSDate*)dayAtPoint:(CGPoint)pt;


/*!
	@group Reloading events
 */

/*!
	@abstract	Reloads all events in the month planner view.
	@discussion The view discards any currently displayed visible event views and redisplays them.
 */
- (void)reloadEvents;

/*!
	@abstract	Reloads all events for given date.
	@param		date		The date for which to reload events.
	@discussion The view discards any currently displayed visible event views at date and redisplays them.
 */
- (void)reloadEventsAtDate:(NSDate*)date;


/*!
	@abstract	Reloads all events in given date range.
	@param		range
	@discussion The view discards any currently displayed visible event views in the range and redisplays them.
 */
- (void)reloadEventsInRange:(MGCDateRange*)range;


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

/*!
	@abstract	Call this method to hide the interactive cell, after an existing event or a new one has been dragged around.
 */
- (void)endInteraction;

@end


//////////////////////////////////////////////////////////////////////////////////////////////
// MGCMonthPlannerViewDataSource


/*!
 * An object that adopts the MGCMonthPlannerViewDataSource protocol is responsible for providing the data and views
 * required by a month planner view.
 */
@protocol MGCMonthPlannerViewDataSource<NSObject>

@required

/*!
	@abstract	Asks the data source for the number of events at specified date. (required)
 */
- (NSInteger)monthPlannerView:(MGCMonthPlannerView*)view numberOfEventsAtDate:(NSDate*)date;

/*!
	@abstract	Asks the data source for the date range of the specified event in the month planner view. (required)
 */
- (MGCDateRange*)monthPlannerView:(MGCMonthPlannerView*)view dateRangeForEventAtIndex:(NSUInteger)index date:(NSDate*)date;

/*!
	@abstract	Asks the data source for the view that corresponds to the specified event in the month planner view. (required)
 */
- (MGCEventView*)monthPlannerView:(MGCMonthPlannerView*)view cellForEventAtIndex:(NSUInteger)index date:(NSDate*)date;

@optional

/*!
	@abstract	Asks the data source for the view to be displayed when a new event is about to be created.
	@discussion	If this method is not implemented by the data source, a standard event view will be used.
 
 */
- (MGCEventView*)monthPlannerView:(MGCMonthPlannerView *)view cellForNewEventAtDate:(NSDate*)date;

/*!
	@abstract	Asks the data source if the specified event can be moved around. If the method returns YES, the
                event view can be dragged and dropped to a different date.
	@discussion	This method is not called if month planner view's canMoveEvents property is set to NO.
 
 */
- (BOOL)monthPlannerView:(MGCMonthPlannerView*)view canMoveCellForEventAtIndex:(NSUInteger)index date:(NSDate*)date;

@end

/*!
 * The MGCMonthPlannerViewDelegate protocol defines methods that allow you to manage the selection of events in
 * a month planner view and respond to operations like scrolling and changes in the display.
 * The methods of this protocol are all optional.
 */
@protocol MGCMonthPlannerViewDelegate<NSObject>

@optional

/*!
	@abstract   Asks the delegate for the attributed string of the day header for given date.
    @param		view		The month planner view requesting the information.
	@param		date		The date for the header.
	@return     The attributed string to draw.
 */
- (NSAttributedString*)monthPlannerView:(MGCMonthPlannerView*)view attributedStringForDayHeaderAtDate:(NSDate*)date;

/*!
	@abstract	Tells the delegate that the month planner view was scrolled.
 */
- (void)monthPlannerViewDidScroll:(MGCMonthPlannerView*)view;


/*!
	@abstract	Tells the delegate that a day cell was selected.
	@param		view		The month planner view object notifying about the selection change.
	@param		date		The date for the corresponding cell.
 */
- (void)monthPlannerView:(MGCMonthPlannerView*)view didSelectDayCellAtDate:(NSDate*)date;

/*!
	@abstract	Tells the delegate that a day cell was selected.
	@param		view		The month planner view object notifying about the selection change.
	@param		date		The date for the corresponding cell.
 */
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
