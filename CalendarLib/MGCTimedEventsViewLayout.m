//
//  MGCTimedEventsViewLayout.m
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

#import "MGCTimedEventsViewLayout.h"
#import "MGCEventCellLayoutAttributes.h"
#import "MGCAlignedGeometry.h"


// In iOS 8.1.2 and older, there is a bug with UICollectionView that will make
// cells disappear when their frame overlap vertically the visible rect (i.e the one passed in
// layoutAttributesForElementsInRect:)
// To avoid this, we constraint the height of the cells frame so that they entirely fit in the rect.
// Then we have to remember to invalidate the whole layout whenever this visible rect changes

// see http://stackoverflow.com/questions/13770484/large-uicollectionviewcells-disappearing-with-custom-layout
// or https://github.com/mattjgalloway/CocoaBugs/blob/master/UICollectionView-MissingCells/README.md

#define BUG_FIX


@interface MGCTimedEventsViewLayout()

@property (nonatomic) NSMutableDictionary *layoutInfo;

#ifdef BUG_FIX
@property (nonatomic) CGRect visibleBounds;
@property (nonatomic) BOOL shouldInvalidate;
#endif

@end


@implementation MGCTimedEventsViewLayout

- (instancetype)init {
	if (self = [super init]) {
		_minimumVisibleHeight = 15.;
	}
	return self;
}

- (NSMutableDictionary*)layoutInfo
{
	if (!_layoutInfo) {
		NSInteger numSections = self.collectionView.numberOfSections;
		_layoutInfo = [NSMutableDictionary dictionaryWithCapacity:numSections];
	}
	return _layoutInfo;
}

- (NSArray*)layoutAttributesForSection:(NSUInteger)section
{
	NSArray *sectionAttribs = [self.layoutInfo objectForKey:@(section)];
	if (!sectionAttribs) {
		
		NSInteger numItems = [self.collectionView numberOfItemsInSection:section];
		NSMutableArray *attribs = [NSMutableArray arrayWithCapacity:numItems];
		
		for (NSInteger item = 0; item < numItems; item++) {
			NSIndexPath *indexPath = [NSIndexPath indexPathForItem:item inSection:section];
			
            CGRect rect = [self.delegate collectionView:self.collectionView layout:self rectForEventAtIndexPath:indexPath];
            if (!CGRectIsNull(rect)) {
                MGCEventCellLayoutAttributes *cellAttribs = [MGCEventCellLayoutAttributes layoutAttributesForCellWithIndexPath:indexPath];
                
                rect.origin.x = self.dayColumnSize.width * indexPath.section;
                rect.size.width = self.dayColumnSize.width;
                rect.size.height = fmax(self.minimumVisibleHeight, rect.size.height);
                
                cellAttribs.frame = MGCAlignedRect(CGRectInset(rect , 0, 1));
                cellAttribs.visibleHeight = cellAttribs.frame.size.height;
                
                [attribs addObject:cellAttribs];
            }
        }
		
		sectionAttribs = [self adjustLayoutForOverlappingCells:attribs inSection:section];
		
		[self.layoutInfo setObject:sectionAttribs forKey:@(section)];
	}
	
	return sectionAttribs;
}

- (NSArray*)adjustLayoutForOverlappingCells:(NSArray*)attributes inSection:(NSUInteger)section
{
	const CGFloat kOverlapOffset = 4.;
	
	// sort layout attributes by frame y-position
	NSArray *adjustedAttributes = [attributes sortedArrayUsingComparator:^NSComparisonResult(MGCEventCellLayoutAttributes *att1, MGCEventCellLayoutAttributes *att2) {
		if (att1.frame.origin.y > att2.frame.origin.y) {
			 return NSOrderedDescending;
		}
		else if (att1.frame.origin.y < att2.frame.origin.y) {
			 return NSOrderedAscending;
		}
		return NSOrderedSame;
	}];
	
	
	for (NSUInteger i = 0; i < adjustedAttributes.count; i++) {
		MGCEventCellLayoutAttributes *attribs1 = [adjustedAttributes objectAtIndex:i];
		
		NSMutableArray *layoutGroup = [NSMutableArray array];
		MGCEventCellLayoutAttributes *covered = nil;
		[layoutGroup addObject:attribs1];
		
		// iterate previous frames (i.e with highest or equal y-pos)
		for (NSInteger j = i - 1; j >= 0; j--) {
			
			MGCEventCellLayoutAttributes *attribs2 = [adjustedAttributes objectAtIndex:j];
			if (CGRectIntersectsRect(attribs1.frame, attribs2.frame)) {
				CGFloat visibleHeight = fabs(attribs1.frame.origin.y - attribs2.frame.origin.y);
				
				if (visibleHeight > self.minimumVisibleHeight) {
					covered = attribs2;
					covered.visibleHeight = visibleHeight;
                    attribs1.zIndex = attribs2.zIndex + 1;
					break;
				}
				else {
					[layoutGroup addObject:attribs2];
				}
			}
		}
		
		// now, distribute elements in layout group
		CGFloat groupOffset = 0;
		if (covered) {
			CGFloat sectionXPos = section * self.dayColumnSize.width;
			groupOffset += covered.frame.origin.x - sectionXPos + kOverlapOffset;
		}
		
		CGFloat totalWidth = (self.dayColumnSize.width - 1.) - groupOffset;
		CGFloat colWidth = totalWidth / layoutGroup.count;
		
		CGFloat x = section * self.dayColumnSize.width + groupOffset;
		
		for (MGCEventCellLayoutAttributes* attribs in [layoutGroup reverseObjectEnumerator]) {
			attribs.frame = MGCAlignedRectMake(x, attribs.frame.origin.y, colWidth, attribs.frame.size.height);
			x += colWidth;
		}
	}
	
	return adjustedAttributes;
}

#pragma mark - UICollectionViewLayout

+ (Class)layoutAttributesClass
{
	return [MGCEventCellLayoutAttributes class];
}

- (MGCEventCellLayoutAttributes*)layoutAttributesForItemAtIndexPath:(NSIndexPath*)indexPath
{
	//NSLog(@"layoutAttributesForItemAtIndexPath %@", indexPath);
	
	NSArray *attribs = [self layoutAttributesForSection:indexPath.section];
	return [attribs objectAtIndex:indexPath.item];
}

- (MGCEventCellLayoutAttributes*)initialLayoutAttributesForAppearingItemAtIndexPath:(NSIndexPath*)indexPath
{
	return (MGCEventCellLayoutAttributes*)[self layoutAttributesForItemAtIndexPath:indexPath];
}

- (MGCEventCellLayoutAttributes*)finalLayoutAttributesForDisappearingItemAtIndexPath:(NSIndexPath*)indexPath
{
	return (MGCEventCellLayoutAttributes*)[self layoutAttributesForItemAtIndexPath:indexPath];
}

- (void)prepareForCollectionViewUpdates:(NSArray*)updateItems
{
	//NSLog(@"prepare Collection updates");
	
	[super prepareForCollectionViewUpdates:updateItems];
}

- (void)invalidateLayout
{
	//NSLog(@"invalidateLayout");
	
	[super invalidateLayout];
	self.layoutInfo = nil;
}

- (CGSize)collectionViewContentSize
{
	return CGSizeMake(self.dayColumnSize.width * self.collectionView.numberOfSections, self.dayColumnSize.height);
}

- (NSArray*)layoutAttributesForElementsInRect:(CGRect)rect
{
	//NSLog(@"layoutAttributesForElementsInRect %@", NSStringFromCGRect(rect));
	
#ifdef BUG_FIX
	self.shouldInvalidate = self.visibleBounds.origin.y != rect.origin.y || self.visibleBounds.size.height != rect.size.height;
	//self.shouldInvalidate = !CGRectEqualToRect(self.visibleBounds, rect);
	self.visibleBounds = rect;
#endif
	
	NSMutableArray *allAttribs = [NSMutableArray array];
	
	// determine first and last day intersecting rect
	NSUInteger maxSection = self.collectionView.numberOfSections;
	NSUInteger first = MAX(0, floorf(rect.origin.x  / self.dayColumnSize.width));
    NSUInteger last =  MIN(MAX(first, ceilf(CGRectGetMaxX(rect) / self.dayColumnSize.width)), maxSection);
    
	for (NSInteger day = first; day < last; day++) {
		NSArray *attribs = [self layoutAttributesForSection:day];
		
		for (MGCEventCellLayoutAttributes *a in attribs) {
			if (CGRectIntersectsRect(rect, a.frame)) {
#ifdef BUG_FIX
				CGRect frame = a.frame;
				frame.size.height = fminf(frame.size.height, CGRectGetMaxY(rect) - frame.origin.y);
				a.frame = frame;
#endif
				[allAttribs addObject:a];
			}
		}
	}

	return allAttribs;
}

- (CGPoint)targetContentOffsetForProposedContentOffset:(CGPoint)proposedContentOffset
{
    CGFloat x = roundf(proposedContentOffset.x / self.dayColumnSize.width) * self.dayColumnSize.width;
    return CGPointMake(x, proposedContentOffset.y);
}

- (BOOL)shouldInvalidateLayoutForBoundsChange:(CGRect)newBounds
{
    //NSLog(@"shouldInvalidateLayoutForBoundsChange %@", NSStringFromCGRect(newBounds));
    
    CGRect oldBounds = self.collectionView.bounds;
    
    return
#ifdef BUG_FIX
        self.shouldInvalidate ||
#endif
        oldBounds.size.width != newBounds.size.width;
}

@end
