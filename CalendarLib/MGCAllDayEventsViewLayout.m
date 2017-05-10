//
//  MGCAllDayEventsViewLayout.m
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

#import "MGCAllDayEventsViewLayout.h"
#import "MGCAlignedGeometry.h"


static const CGFloat kCellSpacing = 2.;		// space around cells
static const CGFloat kCellInset = 4.;


@interface MGCAllDayEventsViewLayout ()

@property (nonatomic) NSUInteger maxEventsInSections;
@property (nonatomic) NSMutableDictionary *eventsCount;	// cache of events count per day [ { day : count }, ... ]
@property (nonatomic) NSMutableDictionary *hiddenCount; // cache of hidden events count per day
@property (nonatomic) NSMutableDictionary *layoutInfos;

@property (nonatomic) NSRange visibleSections;

@end


@implementation MGCAllDayEventsViewLayout


- (instancetype)init
{
	if (self = [super init]) {
		_dayColumnWidth = 60.;
		_eventCellHeight = 20.;
		_maxContentHeight = CGFLOAT_MAX;
		_visibleSections = NSMakeRange(0, 0);
	}
	return self;
}

// maximum number of event lines that can be displayed
- (NSUInteger)maxVisibleLines
{
	return (self.maxContentHeight + kCellSpacing + 1) / (self.eventCellHeight + kCellSpacing);
}

// returns the number of event lines displayed for this day range
- (NSUInteger)maxVisibleLinesForDaysInRange:(NSRange)range
{
	NSUInteger count = 0;
	for (NSUInteger day = range.location; day < NSMaxRange(range); day++) {
		count = MAX(count, [self numberOfEventsForDayAtIndex:day]);
	}
	// if count > max, we have to keep one row to show "x more events"
	return count > self.maxVisibleLines ? self.maxVisibleLines - 1 : count;
}

- (NSInteger)numberOfEventsForDayAtIndex:(NSInteger)day
{
    NSNumber *count = [self.eventsCount objectForKey:@(day)];
	
	if (!count) {
		count = @([self.collectionView numberOfItemsInSection:day]);
		if (!self.eventsCount) {
			self.eventsCount = [NSMutableDictionary dictionaryWithCapacity:self.collectionView.numberOfSections];
		}
		
		[self.eventsCount setObject:count forKey:@(day)];
	}
	return [count integerValue];
}

- (void)addHiddenEventForDayAtIndex:(NSInteger)day
{
	if (!self.hiddenCount) {
		self.hiddenCount = [NSMutableDictionary dictionaryWithCapacity:self.collectionView.numberOfSections];
	}
	
	NSInteger count = [[self.hiddenCount objectForKey:@(day)]integerValue];
	[self.hiddenCount setObject:@(++count) forKey:@(day)];
}

- (NSUInteger)numberOfHiddenEventsInSection:(NSInteger)section
{
	return [[self.hiddenCount objectForKey:@(section)]unsignedIntegerValue];
}

// returns a dictionary of (indexpath : range) for all visible events
- (NSDictionary*)eventRanges
{
    NSMutableDictionary *eventRanges = [NSMutableDictionary new];
	
	NSRange visibleSections = [self visibleDayRangeForBounds:self.collectionView.bounds];
	
    BOOL previousDaysWithEvents = NO;
    for (NSInteger day = visibleSections.location; day < NSMaxRange(visibleSections); day++)
    {
        NSInteger eventsCount = [self numberOfEventsForDayAtIndex:day];
        for (NSInteger item = 0; item < eventsCount; item++)
        {
            NSIndexPath *path = [NSIndexPath indexPathForItem:item inSection:day];
            NSRange eventRange = [self.delegate collectionView:self.collectionView layout:self dayRangeForEventAtIndexPath:path];
            
            // keep only those events starting at current column,
            // or those started earlier if this is the first day of the row range
            if (eventRange.location == day || day == visibleSections.location ||
                // this last case means than the event started earlier but previous days may not have loaded yet, thus returning 0 event.
                // we keep it to avoid nasty flickering when scrolling backwards
                !previousDaysWithEvents)
            {
                eventRange = NSIntersectionRange(eventRange, visibleSections);
                [eventRanges setObject:[NSValue valueWithRange:eventRange] forKey:path];
            }
        }
        if (eventsCount > 0) previousDaysWithEvents = YES;
    }
        
	return eventRanges;
}

- (CGRect)rectForCellWithRange:(NSRange)range line:(NSUInteger)line insets:(AllDayEventInset)insets
{
	CGFloat x = self.dayColumnWidth * range.location;
	CGFloat y = line * (self.eventCellHeight + kCellSpacing);
	
	if (insets & AllDayEventInsetLeft) {
		x += kCellInset;
	}
	
	CGFloat width = self.dayColumnWidth * range.length;
	if (insets & AllDayEventInsetRight) {
		width -= kCellInset;
	}
	
	CGRect rect = MGCAlignedRectMake(x, y, width, self.eventCellHeight);
	return CGRectInset(rect, kCellSpacing, 0);
}

#pragma mark - UICollectionViewLayout

- (void)prepareLayout
{
	//NSLog(@"AllDayEvents prepareLayout");
    
	self.maxEventsInSections = 0;
	self.eventsCount = nil;
	self.hiddenCount = nil;
	self.layoutInfos = [NSMutableDictionary dictionary];
    
	NSMutableDictionary *cellInfos = [NSMutableDictionary dictionary];
	NSMutableDictionary *moreInfos = [NSMutableDictionary dictionary];

	NSDictionary *eventRanges = [self eventRanges];
	NSMutableArray *lines = [NSMutableArray new];
	
	for (NSIndexPath *indexPath in [[eventRanges allKeys]sortedArrayUsingSelector:@selector(compare:)])
	{
		NSRange eventRange = [[eventRanges objectForKey:indexPath]rangeValue];
		
		NSUInteger numLine = 0;	// index of the line where to insert the event
		
		for (NSMutableIndexSet *indexes in lines) {
			if (![indexes intersectsIndexesInRange:eventRange]) {
				// we found the right line
				[indexes addIndexesInRange:eventRange];
				break;
			}
			numLine++;
		}

		if (numLine == lines.count)  {
			// this means no line was yet created, or the event does not fit any
			[lines addObject:[NSMutableIndexSet indexSetWithIndexesInRange:eventRange]];
		}
		
		NSUInteger maxVisibleEvents = [self maxVisibleLinesForDaysInRange:eventRange];
		if (numLine < maxVisibleEvents) {
			
			UICollectionViewLayoutAttributes *attribs = [UICollectionViewLayoutAttributes layoutAttributesForCellWithIndexPath:indexPath];
			
			AllDayEventInset insets = AllDayEventInsetNone;
			if ([self.delegate respondsToSelector:@selector(collectionView:layout:insetsForEventAtIndexPath:)]) {
				insets = [self.delegate collectionView:self.collectionView layout:self insetsForEventAtIndexPath:indexPath];
			}
			
			CGRect frame = [self rectForCellWithRange:eventRange line:numLine insets:insets];
			attribs.frame = frame;
			
			[cellInfos setObject:attribs forKey:indexPath];
			
			self.maxEventsInSections = MAX(self.maxEventsInSections, numLine+1);
		}
		else {
			for (NSUInteger day = eventRange.location; day < NSMaxRange(eventRange); day++) {
				[self addHiddenEventForDayAtIndex:day];
				self.maxEventsInSections = maxVisibleEvents + 1;
			}
		}
	}
	
	NSInteger numSections = self.collectionView.numberOfSections;
	for (int day = 0; day < numSections; day++)
	{
		NSUInteger hiddenCount = [self numberOfHiddenEventsInSection:day];
		if (hiddenCount) {
			NSIndexPath *path = [NSIndexPath indexPathForItem:0 inSection:day];
			UICollectionViewLayoutAttributes *attribs = [UICollectionViewLayoutAttributes layoutAttributesForSupplementaryViewOfKind:MoreEventsViewKind withIndexPath:path];
			CGRect frame = [self rectForCellWithRange:NSMakeRange(day, 1) line:self.maxVisibleLines - 1 insets:AllDayEventInsetNone];
			attribs.frame = frame;

			[moreInfos setObject:attribs forKey:path];
		}
	}
	
	[self.layoutInfos setObject:cellInfos forKey:@"cellInfos"];
	[self.layoutInfos setObject:moreInfos forKey:@"moreInfos"];
}

- (CGSize)collectionViewContentSize
{
	CGFloat width = self.collectionView.numberOfSections * self.dayColumnWidth;
	CGFloat height = self.maxEventsInSections * (self.eventCellHeight + kCellSpacing);
	return CGSizeMake(width, height);
}

- (NSArray*)layoutAttributesForElementsInRect:(CGRect)rect
{
	NSMutableArray *allAttribs = [NSMutableArray array];
	
	for (NSString *key in self.layoutInfos)
	{
		NSDictionary *attributesDict = [self.layoutInfos objectForKey:key];
		for (NSIndexPath *indexPath in attributesDict)
		{
			UICollectionViewLayoutAttributes *attributes = [attributesDict objectForKey:indexPath];
			if (CGRectIntersectsRect(rect, attributes.frame) && !attributes.hidden) {
				[allAttribs addObject:attributes];
			}
		}
	}
	return allAttribs;
}

- (UICollectionViewLayoutAttributes*)layoutAttributesForItemAtIndexPath:(NSIndexPath*)indexPath
{
	//NSLog(@"AllDayEvents layoutAttributesForItemAtIndexPath: %d-%d\n", indexPath.section, indexPath.item);

	NSDictionary *cellsInfos = [self.layoutInfos objectForKey:@"cellInfos"];
	UICollectionViewLayoutAttributes *attribs = [cellsInfos objectForKey:indexPath];
	
	if (!attribs) {
		attribs = [UICollectionViewLayoutAttributes layoutAttributesForCellWithIndexPath:indexPath];
		attribs.hidden = YES;
		attribs.frame = CGRectZero;
	}

	return attribs;
}

- (UICollectionViewLayoutAttributes*)initialLayoutAttributesForAppearingItemAtIndexPath:(NSIndexPath*)indexPath
{
	return [self layoutAttributesForItemAtIndexPath:indexPath];
}

- (UICollectionViewLayoutAttributes*)finalLayoutAttributesForDisappearingItemAtIndexPath:(NSIndexPath*)indexPath
{
	return [self layoutAttributesForItemAtIndexPath:indexPath];
}

- (UICollectionViewLayoutAttributes*)layoutAttributesForSupplementaryViewOfKind:(NSString*)elementKind atIndexPath:(NSIndexPath*)indexPath
{
	NSDictionary *cellsInfos = [self.layoutInfos objectForKey:@"moreInfos"];
	UICollectionViewLayoutAttributes *attribs = [cellsInfos objectForKey:indexPath];
	
	if (!attribs) {
		attribs = [UICollectionViewLayoutAttributes layoutAttributesForCellWithIndexPath:indexPath];
		attribs.hidden = YES;
		attribs.frame = CGRectZero;
	}
	
	return attribs;
}

- (NSRange)visibleDayRangeForBounds:(CGRect)bounds
{
    NSUInteger maxSection = self.collectionView.numberOfSections;
    NSUInteger first = MAX(0, floorf(bounds.origin.x  / self.dayColumnWidth));
    NSUInteger last =  MIN(MAX(first, ceilf(CGRectGetMaxX(bounds) / self.dayColumnWidth)), maxSection);
    return NSMakeRange(first, last - first);
}

- (BOOL)shouldInvalidateLayoutForBoundsChange:(CGRect)newBounds
{
    BOOL shouldInvalidate = NO;
	
	CGRect oldBounds = self.collectionView.bounds;
    shouldInvalidate = (oldBounds.size.width != newBounds.size.width);

    NSRange visibleDays = [self visibleDayRangeForBounds:newBounds];
	BOOL offContent = newBounds.origin.x < 0 || CGRectGetMaxX(newBounds) > self.collectionViewContentSize.width;
	if (!NSEqualRanges(visibleDays, self.visibleSections) && !offContent) {
		self.visibleSections = visibleDays;
		shouldInvalidate = YES;
	}
    
	return shouldInvalidate;
}

- (CGPoint)targetContentOffsetForProposedContentOffset:(CGPoint)proposedContentOffset
{
    CGFloat xOffset = roundf(proposedContentOffset.x / self.dayColumnWidth) * self.dayColumnWidth ;
    return CGPointMake(xOffset, proposedContentOffset.y);
}

@end
