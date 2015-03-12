//
//  MGCEventsRowView.h
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
#import "MGCEventView.h"
#import "MGCReusableObjectQueue.h"


@class MGCEventsRowView;

@protocol MGCEventsRowViewDelegate <UIScrollViewDelegate>

- (NSUInteger)eventsRowView:(MGCEventsRowView*)view numberOfEventsForDayAtIndex:(NSUInteger)day;
- (NSRange)eventsRowView:(MGCEventsRowView*)view rangeForEventAtIndexPath:(NSIndexPath*)indexPath;
- (MGCEventView*)eventsRowView:(MGCEventsRowView*)view cellForEventAtIndexPath:(NSIndexPath*)indexPath;

@optional

- (CGFloat)eventsRowView:(MGCEventsRowView*)view widthForDayRange:(NSRange)range;
- (BOOL)eventsRowView:(MGCEventsRowView*)view shouldSelectCellAtIndexPath:(NSIndexPath*)indexPath;
- (void)eventsRowView:(MGCEventsRowView*)view didSelectCellAtIndexPath:(NSIndexPath*)indexPath;
- (BOOL)eventsRowView:(MGCEventsRowView*)view shouldDeselectCellAtIndexPath:(NSIndexPath*)indexPath;
- (void)eventsRowView:(MGCEventsRowView*)view didDeselectCellAtIndexPath:(NSIndexPath*)indexPath;
- (void)eventsRowView:(MGCEventsRowView*)view willDisplayCell:(MGCEventView*)cell forEventAtIndexPath:(NSIndexPath*)indexPath;
- (void)eventsRowView:(MGCEventsRowView*)view didEndDisplayingCell:(MGCEventView*)cell forEventAtIndexPath:(NSIndexPath*)indexPath;

@end


@interface MGCEventsRowView : UIScrollView<MGCReusableObject>

@property (nonatomic, copy) NSString *reuseIdentifier;
@property (nonatomic, copy) NSDate *referenceDate;
@property (nonatomic) NSRange daysRange;
@property (nonatomic) CGFloat dayWidth;
@property (nonatomic) CGFloat itemHeight;
@property (nonatomic, weak) id<MGCEventsRowViewDelegate> delegate;
@property (nonatomic, readonly) NSUInteger maxVisibleLines;
//@property (nonatomic) BOOL limitsToVisibleHeight;

- (void)reload;
- (NSArray*)cellsInRect:(CGRect)rect;
- (NSIndexPath*)indexPathForCellAtPoint:(CGPoint)pt;
- (MGCEventView*)cellAtIndexPath:(NSIndexPath*)indexPath;

@end

