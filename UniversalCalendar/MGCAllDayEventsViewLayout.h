//
//  MGCAllDayEventsViewLayout.h
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


static NSString* const MoreEventsViewKind = @"MoreEventsViewKind";

typedef enum : NSUInteger
{
	AllDayEventInsetNone = 0,
	AllDayEventInsetLeft  = 1 << 0,
	AllDayEventInsetRight = 1 << 1,
} AllDayEventInset;


@protocol MGCAllDayEventsViewLayoutDelegate;


// This collection view layout is responsible for the layout of event views in the all-day events part
// of the day planner view.
@interface MGCAllDayEventsViewLayout : UICollectionViewLayout

@property (nonatomic, weak) id<MGCAllDayEventsViewLayoutDelegate> delegate;
@property (nonatomic) CGFloat dayColumnWidth;		// width of columns
@property (nonatomic) CGFloat eventCellHeight;		// height of an event cell
@property (nonatomic) CGFloat maxContentHeight;		// if the total content height, defined by the sum of the height of all stacked cells, is more than this value, then some cells will be hidden and a view at the bottom will indicate the number of hidden events

- (NSUInteger)numberOfHiddenEventsInSection:(NSInteger)section;

@end


@protocol MGCAllDayEventsViewLayoutDelegate<UICollectionViewDelegate>

- (NSRange)collectionView:(UICollectionView*)view layout:(MGCAllDayEventsViewLayout*)layout dayRangeForEventAtIndexPath:(NSIndexPath*)indexPath;

@optional

- (AllDayEventInset)collectionView:(UICollectionView*)view layout:(MGCAllDayEventsViewLayout*)layout insetsForEventAtIndexPath:(NSIndexPath*)indexPath;

@end
