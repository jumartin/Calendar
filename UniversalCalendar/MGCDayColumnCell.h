//
//  MGCDayColumnCell.h
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


typedef enum : NSUInteger
{
	MGCDayColumnCellAccessoryNone = 0,
	MGCDayColumnCellAccessoryDot = 1 << 0,		// draw a dot under the day label (e.g. to indicate events on that day)
	MGCDayColumnCellAccessoryMark = 1 << 1,		// draw a mark around the day figure (e.g. to indicate today)
	MGCDayColumnCellAccessoryBorder = 1 << 2,	// draw a border on the left side of the cell (day separator)
    MGCDayColumnCellAccessorySeparator = 1 << 3 // draw a thick border (week separator)
} MGCDayColumnCellAccessoryType;


// This collection view cell is used by the day planner view's subview dayColumnView.
// It is responsible for drawing the day header and vertical separator between columns.
// The day header displays the date, which can be marked, and eventually a dot below
// that can indicate the presence of events. It can also show an activity indicator which
// can be set visible while events are loading (see MGCDayPlannerView setActivityIndicatorVisible:forDate:)
@interface MGCDayColumnCell : UICollectionViewCell

@property (nonatomic, readonly) UILabel *dayLabel;						// label displaying dates
@property (nonatomic) MGCDayColumnCellAccessoryType accessoryTypes;		// presentation style of the view
@property (nonatomic) UIColor *markColor;								// color of the mark around the date (default is black)
@property (nonatomic) UIColor *dotColor;								// color of the dot (default is blue)
@property (nonatomic) UIColor *separatorColor;                          // color of the separator line (default is light gray)
@property (nonatomic) CGFloat headerHeight;								// height of the header

- (void)setActivityIndicatorVisible:(BOOL)visible;

@end
