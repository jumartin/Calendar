//
//  MGCDayPlannerView.h
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

@class MGCEventView;
@class MGCDateRange;

@protocol MGCDayPlannerViewDataSource;
@protocol MGCDayPlannerViewDelegate;


typedef NS_ENUM(NSUInteger, MGCEventType) {
	MGCAllDayEventType = 0,
	MGCTimedEventType
};


typedef NS_ENUM(NSUInteger, MGCDayPlannerScrollType) {
	MGCDayPlannerScrollDateTime = 0,
	MGCDayPlannerScrollDate = 1,
	MGCDayPlannerScrollTime = 2
};


typedef NS_ENUM(NSUInteger, MGCDayPlannerTimeMark) {
    MGCDayPlannerTimeMarkHeader = 0,
    MGCDayPlannerTimeMarkCurrent = 1,
    MGCDayPlannerTimeMarkFloating = 2,
};


/*!
 * You can use an instance of MGCDayPlannerView to display events as a schedule.
 *
 * This view displays a grid with days as columns and time slots as rows.
 * User can scroll infinitely through days or swipe through pages of several days.
 * Events are displayed in cells, which are subclasses of `MGCEventView` and can
 * contain any subviews according to the type of the event.
 * 
 * The view also displays a bar at the top with full-day events.
 */
@interface MGCDayPlannerView : UIView

/*! 
	@group Configuring a day planner view
*/
	
/*!
	@abstract	Returns the calendar used for formating the day headers, and manipulating dates.
	@discussion The default value is the logical calendar for the current user
*/
@property (nonatomic) NSCalendar *calendar;

/*!
	@abstract	Returns the number of days the view shows at once, i.e the number of columns displayed.
	@discussion The default value is 7.
	@discussion If a date range is specified and the total number of scrollable days is less than the value of `numberOfVisibleDays`, 
				then this number is used instead.
	@see		calendar
	@see		dateRange
*/
@property (nonatomic) NSUInteger numberOfVisibleDays;

/*!
	@abstract	Returns the size of a column (readonly).
	@discussion The width is calculated by dividing the view width by the number of visible days.
				The height does not include the header height nor the height of the full-day events bar.
	@see		numberOfVisibleDays
*/
@property (nonatomic, readonly) CGSize dayColumnSize;

/*!
	@abstract	Returns the height of a one-hour slot.
	@discussion The default value is 65.
*/
@property (nonatomic) CGFloat hourSlotHeight;
	
/*!
	@abstract	Returns the width of the left column showing hours.
	@discussion The default value is 60.
				To hide the time column, you can set this value to 0.
*/
@property (nonatomic) CGFloat timeColumnWidth;

/*!
	@abstract	Returns the height of the top row showing days.
	@discussion The default value is 40.
				To hide the day header, you can set this value to 0.
*/
@property (nonatomic) CGFloat dayHeaderHeight;

/*!
	@abstract	Returns the color of the vertical separator lines between days.
	@discussion The default value is light gray.
 */
@property (nonatomic) UIColor *daySeparatorsColor;

/*!
	@abstract	Returns the color of the horizontal separator lines between time slots.
	@discussion The default value is light gray.
                The color is also used for time labels. 
    @see        dayPlannerView:attributedStringForTimeMark:time: delegate method
 */
@property (nonatomic) UIColor *timeSeparatorsColor;

/*!
	@abstract	Returns the color of the current time line and label.
	@discussion The default value is red.
    @see        dayPlannerView:attributedStringForTimeMark:time: delegate method
 */
@property (nonatomic) UIColor *currentTimeColor;

/*!
	@abstract	Returns the color of the dot in the header indicating that a day has events.
	@discussion The default value is blue.
 */
@property (nonatomic) UIColor *eventIndicatorDotColor;

/*!
	@abstract	Determines whether the day planner view shows all-day events.
	@discussion If the value of this property is YES, the view displays a bar at the top with all-day events.
				The default value is YES.
	@see		numberOfVisibleDays
 */
@property (nonatomic) BOOL showsAllDayEvents;

/*!
	@abstract	The view that provides the background appearance.
	@discussion The view (if any) in this property is positioned underneath all of the other content 
				and sized automatically to fill the entire bounds of the day planner view.
				The background view does not scroll with the view’s other content.
				The day planner view maintains a strong reference to the background view object.
	@discussion	This property is nil by default, which displays the background color of the day planner view.
*/
@property (nonatomic) UIView *backgroundView;

/*!
	@abstract	String format for dates displayed on top of day columns.
	@discussion If the value of this property is nil, a default format of @"d MMM\neeeee" is used.
	@see		NSDateFormatter dateFormat
 */
@property (nonatomic, copy) NSString *dateFormat;

/*!
	@abstract	Scrollable range of days. Default is nil, for 'infinite' scrolling.
	@discussion	Upon assignement, `start` and `end` properties of `dateRange` are adjusted
				so that they fall on day boundary (starting at 00:00)
	@discussion If the currently visible day is outside the new range, the calendar view scrolls to the range starting date.
 */
@property (nonatomic, copy) MGCDateRange *dateRange;

/*!
	@abstract	Displayable range of hours. Default is {0, 24}.
    @discussion Range length must be >= 1

 */
@property (nonatomic) NSRange hourRange;

/*!
	@abstract	Determines whether zooming is enabled for this day planner view.
				If set to YES, the user can decrease or increase the height of the one-hour slot by pinching in and out on the view.
	@discussion The default value is YES.
	@see		hourSlotHeight
 */
@property(nonatomic, getter=isZoomingEnabled) BOOL zoomingEnabled;

/*!
	@abstract	Determines whether an event can be created with a long-press on the view.
	@discussion The default value is YES.
	@see		canMoveEvents
 */
@property (nonatomic) BOOL canCreateEvents;

/*!
	@abstract	Determines whether an event can be moved around after a long-press on the view.
	@discussion The default value is YES.
	@see		canCreateEvents
 */
@property (nonatomic) BOOL canMoveEvents;

/*!
	@abstract	The object that acts as the delegate of the day planner view.
	@discussion The delegate must adopt the `MGCDayPlannerViewDelegate` protocol.
				The day planner view view maintains a weak reference to the delegate object.
				The delegate object is responsible for managing selection behavior and interactions with events cells.
 */
@property (nonatomic, weak) id<MGCDayPlannerViewDelegate> delegate;

/*!
	@abstract	The object that provides the data for the day planner view
	@discussion The data source must adopt the `MGCDayPlannerViewDataSource` protocol.
				The day planner view view maintains a weak reference to the data source object.
 */
@property (nonatomic, weak) id<MGCDayPlannerViewDataSource> dataSource;


/*!
	@group Navigating through a day planner view
 */

/*!
	@abstract	Determines whether paging is enabled for this day planner view.
	@discussion If the value of this property is YES and the number of visible days is equal or greater than 7
				(i.e. the view is showing at least a week), the day planner view stops on the current calendar starting day of
				the week when the user scrolls.
				If set to YES but the view is showing less than a week, it stops on multiples of the view’s bounds.
				If paging is enabled, the view also snaps to day boundaries.
				The default value is YES.
	@see		numberOfVisibleDays
 */
@property(nonatomic, getter=isPagingEnabled) BOOL pagingEnabled;

/*!
	@abstract	Scrolls the view until a certain date is visible.
	@param		date		The date to scroll into view. It will be the first visible date on the left of the view.
	@param		options		Specify if scrolling through dates only (MGCDayPlannerScrollDate), 
							time only (MGCDayPlannerScrollTime), or both (MGCDayPlannerScrollDateTime).
	@param		animated	Specify YES to animate the scrolling behavior or NO to adjust the visible content immediately.
	@warning	If `date` param is not in the scrollable range of dates, an exception is thrown.
	@warning	If the view is already curently scrolling, this will have no effect.
 */
- (void)scrollToDate:(NSDate*)date options:(MGCDayPlannerScrollType)options animated:(BOOL)animated;

/*!
	@abstract	Scrolls the view to the next "logical" date.
				If the view shows at least 7 days, it is the next start of a week,
				otherwise it is the first day not currently visible.
	@param		animated	Specify YES to animate the scrolling behavior or NO to adjust the visible content immediately.
	@param		date		If not nil, it will contain on return the date that was scrolled into view.
	@warning	If the view is already curently scrolling, this will have no effect.
 */
- (void)pageForwardAnimated:(BOOL)animated date:(NSDate**)date;

/*!
	@abstract	Scrolls the view to the previous "logical" date.
				If the view shows at least 7 days, it is the previous start of a week,
				otherwise it is the first day not currently visible.
	@param		animated	Specify YES to animate the scrolling behavior or NO to adjust the visible content immediately.
	@param		date		If not nil, it will contain on return the date that was scrolled into view.
	@warning	If the view is already curently scrolling, this will have no effect.
 */
- (void)pageBackwardsAnimated:(BOOL)animated date:(NSDate**)date;


/*!
	@group Creating event views
 */

/*!
	@abstract	Registers a class for use in creating new event cells for the day planner view.
	@param		viewClass	The class of the view that you want to use.
	@param		identifier	The reuse identifier to associate with the specified class. 
							This parameter must not be nil and must not be an empty string.
	@discussion	Prior to calling the dequeueReusableViewWithIdentifier:forEventOfType:atIndex:date: method, you must use this method to tell the day planer view how to create a new event cell of the given type.
 */
- (void)registerClass:(Class)viewClass forEventViewWithReuseIdentifier:(NSString*)identifier;

/*!
	@abstract	Returns a reusable event view cell object located by its identifier.
	@param		identifier	A string identifying the cell object to be reused. This parameter must not be nil.
	@param		type		The type of event for which the view is requested.
	@param		index		The index of the event.
	@param		date		The date of the event.
	@return		A valid MGCEventView object.
	@discussion	Call this method from your data source object when asked to provide a new event view for the day planner. 
				This method dequeues an existing view if one is available or creates a new one based on the class you 
				previously registered.
	@warning	You must register a class using the registerClass:forEventViewWithReuseIdentifier: method before calling this method.
 */
- (MGCEventView*)dequeueReusableViewWithIdentifier:(NSString*)identifier forEventOfType:(MGCEventType)type atIndex:(NSUInteger)index date:(NSDate*)date;


/*!
	@group Getting the state of the day planner view
 */


/*!
	@abstract	The date range of all currently visible days in the day planner view.
	@see		numberOfVisibleDays
 */
@property (nonatomic, readonly) MGCDateRange *visibleDays;

/*!
	@abstract	The first visible time in the day planner view.
	@see		lastVisibleTime
 */
@property (nonatomic, readonly) NSTimeInterval firstVisibleTime;

/*!
	@abstract	The last visible time in the day planner view.
	@see		firstVisibleTime
 */
@property (nonatomic, readonly) NSTimeInterval lastVisibleTime;

/*!
	@abstract	Returns the number of timed events at the specified day.
	@param		date	Day for which events are requested (time portion is ignored)
	@discussion	
 */
- (NSInteger)numberOfTimedEventsAtDate:(NSDate*)date;

/*!
	@abstract	Returns the number of all-day events at the specified date.
	@param		date	Day for which events are requested (time portion is ignored)
	@discussion
 */
- (NSInteger)numberOfAllDayEventsAtDate:(NSDate*)date;

/*!
	@abstract	Returns an array of visible event views currently displayed by the day planner view.
	@param		type	The type of event for which the views are requested.
	@return		An array of MGCEventView objects. If no event view is visible, this method returns an empty array.
 */
- (NSArray*)visibleEventViewsOfType:(MGCEventType)type;


/*!
	@group Locating days and events
 */

/*!
	@abstract	Returns the date at the specified point in the day planner view.
	@param		point		A point in the day planner view’s coordinate system.
	@param		rounded		If set to YES, the returned date is rounded to the nearest 15-minutes slot.
	@return		The date at the specified point, or nil if the date can't be determined.
	@discussion	If `point` lies in the timed-event part, then the returned date contains information about day and time.
				If `point` lies outside the timed-event part, like within the header or all-day events part, 
				then the returned date contains only day/month/year information (time part is set to 00:00).
 */
- (NSDate*)dateAtPoint:(CGPoint)point rounded:(BOOL)rounded;

/*!
	@abstract	Returns the event view at the specified point in the day planner view.
	@param		point		A point in the day planner view’s coordinate system.
	@param		type		If not nil, it will contain on return the type of the event located at point.
	@param		index		If not nil, it will contain on return the index of the event located at point.
	@param		date		If not nil, it will contain on return the date of the event located at point.
	@return		The event view at the specified point, or nil if no event was found at the specified point.
 */
- (MGCEventView*)eventViewAtPoint:(CGPoint)point type:(MGCEventType*)type index:(NSUInteger*)index date:(NSDate**)date;

/*!
	@abstract	Returns the visible event view with specified type, index and date.
	@param		type		The type of the event.
	@param		index		The index of the event.
	@param		date		The date of the event.
	@return		The event view or nil if the event view is not visible, or parameters are out of range.
 */
- (MGCEventView*)eventViewOfType:(MGCEventType)type atIndex:(NSUInteger)index date:(NSDate*)date;

/*!
	@abstract	Returns the area of the cell shown when a new event is created.
	@param		type		The type of the created event.
	@param		date		The date of the created event.
	@return		A rect in the day planner view's coordinate system.
 */
- (CGRect)rectForNewEventOfType:(MGCEventType)type atDate:(NSDate*)date;


/*!
	@group Managing the selection
 */

/*!
	@abstract	Determines whether users can select events in the day planner view.
	@discussion The default value is YES.
				For more control over the selection of items, you can provide a delegate object and implement the
				dayPlannerView:shouldSelectEventOfType:atIndex:date: methods of the MGCDayPlannerViewDelegate protocol.
 */
@property (nonatomic) BOOL allowsSelection;

/*!
	@abstract	Returns the event view for the current selection, or nil if no event is selected.
 */
@property (nonatomic, readonly) MGCEventView *selectedEventView;

/*!
	@abstract	Selects the visible event view having specified type, index and date.
	@param		type		The type of the event.
	@param		index		The index of the event.
	@param		date		The date of the event.
	@discussion If the allowsSelection property is NO, calling this method has no effect. 
				If there is an existing selection with a different type, index or date, calling this method replaces the previous selection.
	@discussion	This method does not cause any selection-related delegate methods to be called.
 */
-(void)selectEventOfType:(MGCEventType)type atIndex:(NSUInteger)index date:(NSDate*)date;

/*!
	@abstract	Cancels current selection.
	@discussion If the allowsSelection property is NO, calling this method has no effect.
	@discussion	This method does not cause any selection-related delegate methods to be called.
 */
- (void)deselectEvent;


/*!
	@group Reloading events
 */

/*!
	@abstract	Reloads all events in the day planner view.
	@discussion The view discards any currently displayed visible event views and redisplays them.
 */
- (void)reloadAllEvents;

/*!
	@abstract	Reloads all events for given date.
	@param		date		The date .
	@discussion The view discards any currently displayed visible event views at date and redisplays them.
 */
- (void)reloadEventsAtDate:(NSDate*)date;

// TODO: this has to be tested
- (void)insertEventOfType:(MGCEventType)type withDateRange:(MGCDateRange*)range;

/*!
	@abstract	Shows or hide the activity indicator in the column header at given date.
 */
- (BOOL)setActivityIndicatorVisible:(BOOL)visible forDate:(NSDate*)date;

/*!
	@abstract	Call this method to hide the interactive cell, after an existing event or a new one has been dragged around.
 */
- (void)endInteraction;

@end


/*!
 * An object that adopts the MGCDayPlannerViewDataSource protocol is responsible for providing the data and views
 * required by a day planner view. 
 */
@protocol MGCDayPlannerViewDataSource<NSObject>

@required

/*!
	@abstract	Asks the data source for the number of events of given type at specified date. (required)
	@param		view		The day planner view object making the request.
	@param		type		The type of the event.
	@param		date		The starting day of the event (time portion should be ignored).
	@return		The number of events.
 */
- (NSInteger)dayPlannerView:(MGCDayPlannerView*)view numberOfEventsOfType:(MGCEventType)type atDate:(NSDate*)date;

/*!
	@abstract	Asks the data source for the view that corresponds to the specified event in the collection view. (required)
 */
- (MGCEventView*)dayPlannerView:(MGCDayPlannerView*)view viewForEventOfType:(MGCEventType)type atIndex:(NSUInteger)index date:(NSDate*)date;

/*!
	@abstract	Asks the data source for the date range of the specified event in the day planner view. (required)
 */
- (MGCDateRange*)dayPlannerView:(MGCDayPlannerView*)view dateRangeForEventOfType:(MGCEventType)type atIndex:(NSUInteger)index date:(NSDate*)date;

@optional

/*!
	@abstract	Asks the data source if the specified event can be moved around. If the method returns YES, the 
				event view can be dragged and dropped to a different date / time.
	@discussion	This method is not called if day planner view's canMoveEvents property is set to NO.

 */
- (BOOL)dayPlannerView:(MGCDayPlannerView*)view shouldStartMovingEventOfType:(MGCEventType)type atIndex:(NSUInteger)index date:(NSDate*)date;

/*!
	@abstract	Asks the data source if the specified event can be moved to given date, or change its type. 
				If the method returns NO, a forbidden sign is shown to indicate that the view cannot be moved 
				to that date and, if dropped, the delegate method dayPlannerView:moveEventOfType:atIndex:date:toType:date:
				won't be called.
  */
- (BOOL)dayPlannerView:(MGCDayPlannerView*)view canMoveEventOfType:(MGCEventType)type atIndex:(NSUInteger)index date:(NSDate*)date toType:(MGCEventType)targetType date:(NSDate*)targetDate;

/*!
	@abstract	Informs the data source that an event was dragged and dropped to a different date / time.
				Data source should update the event accordingly, and ask the day planner view to reload events.
 */
- (void)dayPlannerView:(MGCDayPlannerView*)view moveEventOfType:(MGCEventType)type atIndex:(NSUInteger)index date:(NSDate*)date toType:(MGCEventType)targetType date:(NSDate*)targetDate;


/*!
	@abstract	Asks the data source for the view to be displayed when a new event is about to be created.
	@discussion	If this method is not implemented by the data source, a standard event view will be used.
 */
- (MGCEventView*)dayPlannerView:(MGCDayPlannerView*)view viewForNewEventOfType:(MGCEventType)type atDate:(NSDate*)date;

/*!
	@abstract	Asks the data source if an event can be created with given type and date. 
	@discussion	This method is not called if day planner view's canCreateEvents property is set to NO.
 */
- (BOOL)dayPlannerView:(MGCDayPlannerView*)view canCreateNewEventOfType:(MGCEventType)type atDate:(NSDate*)date;

/*!
	@abstract	Informs the data source that a new event was dragged and dropped at given date.
				Data source should update the event accordingly, and ask the day planner view to reload events.
 */
- (void)dayPlannerView:(MGCDayPlannerView*)view createNewEventOfType:(MGCEventType)type atDate:(NSDate*)date;

@end


/*!
 * The MGCDayPlannerViewDelegate protocol defines methods that allow you to manage the selection of events in
 * a day planner view and respond to operations like scrolling and changes in the display.
 * The methods of this protocol are all optional.
 */
@protocol MGCDayPlannerViewDelegate<NSObject>

@optional

/*!
	@group Configuring appearance
 */

/*!
	@abstract   Asks the delegate for the attributed string of time marks appearing on the left of the day planner view.
	@param		view		The day planner view requesting the information.
	@param		mark        The mark type being drawn.
    @param		ti          The time for the mark.
    @return     The attributed string to draw for the mark.
	@discussion If nil is returned, the default mark style is used.
 */
- (NSAttributedString*)dayPlannerView:(MGCDayPlannerView*)view attributedStringForTimeMark:(MGCDayPlannerTimeMark)mark time:(NSTimeInterval)ti;

/*!
	@abstract   Asks the delegate for the attributed string of the day header for given date.
    @param		view		The day planner view requesting the information.
	@param		date		The date for the header.
	@return     The attributed string to draw.
    @discussion If nil is returned or the method is not implemented, a default string is drawn using dateFormat property.
 */
- (NSAttributedString*)dayPlannerView:(MGCDayPlannerView*)view attributedStringForDayHeaderAtDate:(NSDate*)date;

/*!
	@group Responding to scrolling
 */

/*!
	@abstract	Tells the delegate that the day planner view was scrolled.
	@param		view		The day planner view object in which the scrolling occured.
	@param		scrollType	Indicates what was scrolled through (days, time or both).
	@discussion The method is only called when the view is scrolled horizontally.
				It is called when the user drags or swipes the view and when the view is scrolled programmatically.
	@see		visibleDays
	@see		firstVisibleTime
 */
- (void)dayPlannerView:(MGCDayPlannerView*)view didScroll:(MGCDayPlannerScrollType)scrollType;

/*!
	@abstract	Tells the delegate when a scrolling operation on the day planner view concludes.
	@param		view		The day planner view object in which the scrolling occured.
	@param		scrollType	Indicates what was scrolled through (days, time or both).
	@discussion The method is only called when the view is scrolled horizontally.
				It is called after user interaction and when the view is scrolled programmatically.
 */
- (void)dayPlannerView:(MGCDayPlannerView*)view didEndScrolling:(MGCDayPlannerScrollType)scrollType;

/*!
	@abstract	Tells the delegate that the specified day is about to be displayed in the day planner view.
	@param		view		The day planner view object notifying about the display change.
	@param		date		The day about to be displayed.
 */
- (void)dayPlannerView:(MGCDayPlannerView*)view willDisplayDate:(NSDate*)date;

/*!
	@abstract	Tells the delegate that the specified day is not displayed anymore in the day planner view.
	@param		view		The day planner view object notifying about the display change.
	@param		date		The day about to be displayed.
 */
- (void)dayPlannerView:(MGCDayPlannerView*)view didEndDisplayingDate:(NSDate*)date;

/*!
	@abstract	Tells the delegate that the day planner view was zoomed in or out, increasing or decreasing the hour slot height.
	@param		view		The day planner view object notifying about the display change.
 */
- (void)dayPlannerViewDidZoom:(MGCDayPlannerView*)view;

/*!
	@group Managing the selection of events
 */

/*!
	@abstract	Asks the delegate if the specified event should be selected.
	@param		view		The day planner view object making the request.
	@param		type		The type of the event.
	@param		index		The index of the event.
	@param		date		The starting day of the event.
	@return		YES if the event should be selected or NO if it should not.
	@discussion	The day planner view calls this method when the user tries to select an event. It does not call this method when 
				you programmatically set the selection.
	@discussion	If you do not implement this method, the default return value is YES.
 */
- (BOOL)dayPlannerView:(MGCDayPlannerView*)view shouldSelectEventOfType:(MGCEventType)type atIndex:(NSUInteger)index date:(NSDate*)date;

/*!
	@abstract	Tells the delegate that the specified event was selected.
	@param		view		The day planner view object notifying about the selection change.
	@param		type		The type of the event.
	@param		index		The index of the event.
	@param		date		The starting day of the event.
	@return		YES if the event should be selected or NO if it should not.
	@discussion	The day planner view calls this method when the user successfully selects an event. It does not call this method when
				you programmatically set the selection.
 */
- (void)dayPlannerView:(MGCDayPlannerView*)view didSelectEventOfType:(MGCEventType)type atIndex:(NSUInteger)index date:(NSDate*)date;

/*!
	@abstract	Tells the delegate that the specified event was deselected.
	@param		view		The day planner view object notifying about the selection change.
	@param		type		The type of the event.
	@param		index		The index of the event.
	@param		date		The starting day of the event.
	@return		YES if the event should be selected or NO if it should not.
	@discussion	The day planner view calls this method when the user successfully deselects an event. It does not call this method when
				you programmatically deselect the event.
 */
- (void)dayPlannerView:(MGCDayPlannerView*)view didDeselectEventOfType:(MGCEventType)type atIndex:(NSUInteger)index date:(NSDate*)date;

@end
