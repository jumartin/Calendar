//
//  MGCYearCalendarView.h
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


@protocol MGCYearCalendarViewDelegate;

/**
 * You can use `CalendarYearView` to display a scrollable 12-months calendar. 
 **/
@interface MGCYearCalendarView : UIView

/*!
	@name Configuring a calendar year view
	-----------------------------------------------------------------------------------------------------------------------
 */

/*!
	@property	calendar
	@abstract	The calendar used for formatting the months and dates.
	@discussion The default value is the logical calendar for the current user (as returned by `[NSCalendar currentCalendar]`)
 */
@property (nonatomic) NSCalendar *calendar;

/*!
	@property	delegate
	@abstract	The object acting as the delegate of the Calendar Year View.
	@discussion The delegate must adopt the `CalendarYearViewDelegate` protocol. The Calendar View maintains a weak reference to the delegate object.
	@discussion The delegate object is responsible for managing presentation of dates headers and interaction with months cells.
 */
@property (nonatomic, weak) id<MGCYearCalendarViewDelegate> delegate;

/*!
	@property	daysFont
	@abstract	The font used to display the days ordinals.
	@discussion The default value is the system font with a size of 13.
 */
@property (nonatomic) UIFont *daysFont;

/*!
	@property	headerFont
	@abstract	The font used to display the month header.
	@discussion The default value is the system font with a size of 25.
	@see		[CalendarYearViewDelegate calendarYearView:headerTextForMonthAtDate:]
 */
@property (nonatomic) UIFont *headerFont;

/*!
	@property	visibleMonthsRange
	@abstract	Returns the date range of all visible months.
	@discussion Returns nil if no months are shown.
 */
@property (nonatomic, readonly) MGCDateRange *visibleMonthsRange;

/*!
	@property	dateRange
	@abstract	Scrollable range of years. Default is nil, for 'infinite' scrolling.
	@discussion The range start date is set to the first day of the year, range end to the first day of the year followind end.
	@discussion If the currently visible year is outside the new range, the calendar view scrolls to the range starting date.
 */
@property (nonatomic, copy) MGCDateRange *dateRange;


- (NSDate*)dateForMonthAtPoint:(CGPoint)pt;

/*!
	@name Scrolling a calendar year view
 -----------------------------------------------------------------------------------------------------------------------
 */

/*!
	@abstract	Scrolls the calendar until a certain date is visible.
	@param		date		The date to scroll into view.
	@param		animated	Specify YES to animate the scrolling behavior or NO to adjust the visible content immediately.
	@warning	If `date` param is not in the scrollable range of dates, an exception is thrown.
 */
- (void)scrollToDate:(NSDate*)date animated:(BOOL)animated;

@end

//////////////////////////////////////////////////////////////////////////////////////////////
// CalendarYearViewDelegate
@protocol MGCYearCalendarViewDelegate<NSObject>

@optional

- (CGFloat)heightForYearHeaderInCalendarYearView:(MGCYearCalendarView*)view; // set to 0 to hide year header
- (NSAttributedString*)calendarYearView:(MGCYearCalendarView*)view headerTextForYearAtDate:(NSDate*)date;
- (NSAttributedString*)calendarYearView:(MGCYearCalendarView*)view headerTextForMonthAtDate:(NSDate*)date;
- (void)calendarYearViewDidScroll:(MGCYearCalendarView*)view;
- (void)calendarYearView:(MGCYearCalendarView*)view didSelectMonthAtDate:(NSDate*)date;

@end