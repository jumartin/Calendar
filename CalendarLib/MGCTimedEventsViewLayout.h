//
//  MGCTimedEventsViewLayout.h
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

static NSString* const DimmingViewKind = @"DimmingViewKind";

typedef enum : NSUInteger
{
    TimedEventCoveringTypeClassic = 0,
    TimedEventCoveringTypeComplex  = 1 << 0,
} TimedEventCoveringType;


@protocol MGCTimedEventsViewLayoutDelegate;
@class MGCEventCellLayoutAttributes;


// Custom invalidation context for MGCTimedEventsViewLayout
@interface MGCTimedEventsViewLayoutInvalidationContext: UICollectionViewLayoutInvalidationContext

@property (nonatomic) BOOL invalidateDimmingViews;  // set to true if layout attributes of dimming views must be recomputed
@property (nonatomic) BOOL invalidateEventCells;  // set to true if layout attributes of event cells must be recomputed
@property (nonatomic) NSMutableIndexSet *invalidatedSections;   // sections whose layout attributes (dimming views or event cells) must be recomputed - if nil, recompute everything

@end


// This collection view layout is responsible for the layout of event views in the timed-events part
// of the day planner view.
@interface MGCTimedEventsViewLayout : UICollectionViewLayout

@property (nonatomic, weak) id<MGCTimedEventsViewLayoutDelegate> delegate;
@property (nonatomic) CGSize dayColumnSize;
@property (nonatomic) CGFloat minimumVisibleHeight;  // if 2 cells overlap, and the height of the uncovered part of the upper cell is less than this value, the column is split
@property (nonatomic) BOOL ignoreNextInvalidation;  // for some reason, UICollectionView reloadSections: messes up with scrolling and animations so we have to stick with using reloadData even when only individual sections need to be invalidated. As a workaroud, we explicitly invalidate them with custom context, and set this flag to YES before calling reloadData
@property (nonatomic) TimedEventCoveringType coveringType;  // how to handle event covering

@end


@protocol MGCTimedEventsViewLayoutDelegate <UICollectionViewDelegate>

// x and width of returned rect are ignored
- (CGRect)collectionView:(UICollectionView*)collectionView layout:(MGCTimedEventsViewLayout*)layout rectForEventAtIndexPath:(NSIndexPath*)indexPath;
- (NSArray*)collectionView:(UICollectionView*)collectionView layout:(MGCTimedEventsViewLayout*)layout dimmingRectsForSection:(NSUInteger)section;

@end
