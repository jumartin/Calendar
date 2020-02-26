//
//  MGCMonthMiniCalendarView.h
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


@protocol MGCMonthMiniCalendarViewDelegate;


@interface MGCMonthMiniCalendarView : UIView

@property (nonatomic, copy) NSCalendar *calendar;			// calendar used (one of Gregorian, Indian, Hebrew...)
@property (nonatomic) NSDate *date;							// date for which we want to display the month (not necessarly the first day). Default is today
@property (nonatomic) BOOL showsMonthHeader;				// set to NO to hide the month header. Default is YES
@property (nonatomic) BOOL showsDayHeader;					// set to NO to hide the week day header. Default is YES
@property (nonatomic, copy) NSAttributedString *headerText; // text for the month header. Default is month followed by year (ex: May 2014)
@property (nonatomic) UIFont *daysFont;						// font for week day symbols. Default is system font with size of 13.
@property (nonatomic) NSIndexSet *highlightedDays;			// highlighted days show a circle around the day label
@property (nonatomic) UIColor *highlightColor;				// color of the circle for highlighted days. Default is black.
@property (nonatomic, weak) id<MGCMonthMiniCalendarViewDelegate> delegate;


// returns the ideal size of the view.
// If yearWise is YES, it does not take date into account, but rather calculates the number of rows
// according to the maximum number of weeks per month in a year.
- (CGSize)preferredSizeYearWise:(BOOL)yearWise;

@end


@protocol MGCMonthMiniCalendarViewDelegate <NSObject>

@optional

- (UIColor*)monthMiniCalendarView:(MGCMonthMiniCalendarView*)view backgroundColorForDayAtIndex:(NSUInteger)index;

@end