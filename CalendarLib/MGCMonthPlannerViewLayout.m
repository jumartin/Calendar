//
//  MGCMonthPlannerViewLayout.m
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

#import "MGCMonthPlannerViewLayout.h"
#import "MGCMonthPlannerView.h"


const CGFloat kMonthHeaderMargin = 3.;


@interface MGCMonthPlannerViewLayout()

@property (nonatomic) NSDictionary *layoutInfo;
@property (nonatomic) CGFloat contentHeight;

@end


@implementation MGCMonthPlannerViewLayout

- (CGFloat)widthForColumnRange:(NSRange)range
{
	CGFloat availableWidth = self.collectionView.bounds.size.width - (self.monthInsets.left + self.monthInsets.right);
	CGFloat columnWidth = availableWidth / 7;
	
	if (NSMaxRange(range) == 7) {
		return availableWidth - columnWidth * (7 - range.length);
	}
    return columnWidth * range.length;
}

- (CGFloat)columnWidth:(NSUInteger)colIndex
{
	return [self widthForColumnRange:NSMakeRange(colIndex, 1)];
}


#pragma mark - NSObject

- (id)init
{
	if (self = [super init]) {
		_monthInsets = UIEdgeInsetsMake(20, 0, 20, 0);
		_rowHeight = 140;
		_dayHeaderHeight = 28;
        _showEvents = YES;
	}
	return self;
}

#pragma mark - UICollectionViewLayout

- (void)prepareLayout
{
	NSUInteger numberOfMonths = [self.collectionView numberOfSections];

	NSMutableDictionary *layoutInfo = [NSMutableDictionary dictionary];
	NSMutableDictionary *dayCellsInfo = [NSMutableDictionary dictionary];
	NSMutableDictionary *monthsInfo = [NSMutableDictionary dictionary];
	NSMutableDictionary *rowsInfo = [NSMutableDictionary dictionary];
	
	CGFloat y = 0;
    CGFloat totalWidth = self.collectionView.bounds.size.width - (self.monthInsets.left + self.monthInsets.right);
    
	for (NSUInteger month = 0; month < numberOfMonths; month++)
	{
		NSUInteger col = [self.delegate collectionView:self.collectionView layout:self columnForDayAtIndexPath:[NSIndexPath indexPathForItem:0 inSection:month]];
		NSUInteger daysInMonth = [self.collectionView numberOfItemsInSection:month];
		NSUInteger numRows = ceil((col + daysInMonth) / 7.);
		NSUInteger day = 0;
		
		CGRect monthRect = { .origin = CGPointMake(0, y) };
        
        NSIndexPath *path = [NSIndexPath indexPathForItem:1 inSection:month];;
        CGRect headerFrame = CGRectMake(self.monthInsets.left, y, totalWidth, self.monthInsets.top);
        if (self.alignMonthHeaders) {
            CGFloat xOffset = [self widthForColumnRange:NSMakeRange(0, col)];
            headerFrame.origin.x += (xOffset + kMonthHeaderMargin);
            headerFrame.size.width -= (xOffset + 2*kMonthHeaderMargin);
        }
        UICollectionViewLayoutAttributes *attribs = [UICollectionViewLayoutAttributes layoutAttributesForSupplementaryViewOfKind:MonthHeaderViewKind withIndexPath:path];
        attribs.frame = headerFrame;
        [monthsInfo setObject:attribs forKey:path];
        
		y += self.monthInsets.top;
		
		for (NSUInteger row = 0; row < numRows; row++)
		{
			NSRange colRange = NSMakeRange(col, MIN(7 - col, daysInMonth - day));
			
            if (self.showEvents) {
                NSIndexPath *path = [NSIndexPath indexPathForItem:day inSection:month];
                UICollectionViewLayoutAttributes *attribs = [UICollectionViewLayoutAttributes layoutAttributesForSupplementaryViewOfKind:MonthRowViewKind withIndexPath:path];
                CGFloat x = [self widthForColumnRange:NSMakeRange(0, col)] + self.monthInsets.left;
                CGFloat width = [self widthForColumnRange:NSMakeRange(col, colRange.length)];
                attribs.frame = CGRectMake(x, y + self.dayHeaderHeight, width, self.rowHeight - self.dayHeaderHeight);
                attribs.zIndex = 1;
                [rowsInfo setObject:attribs forKey:path];
            }

			for (; col < NSMaxRange(colRange); col++, day++)
			{
				NSIndexPath *path = [NSIndexPath indexPathForItem:day inSection:month];
				UICollectionViewLayoutAttributes *attribs = [UICollectionViewLayoutAttributes layoutAttributesForCellWithIndexPath:path];
				CGFloat x = [self widthForColumnRange:NSMakeRange(0, col)] + self.monthInsets.left;
				CGFloat width = [self widthForColumnRange:NSMakeRange(col, 1)];
				attribs.frame = CGRectMake(x, y, width, self.rowHeight);
				[dayCellsInfo setObject:attribs forKey:path];
			}
			
			y += self.rowHeight;
			col = 0;
		}
			
		y += self.monthInsets.bottom;
		monthRect.size = CGSizeMake(self.collectionView.bounds.size.width, y - monthRect.origin.y);
			
        path = [NSIndexPath indexPathForItem:0 inSection:month];
		attribs = [UICollectionViewLayoutAttributes layoutAttributesForSupplementaryViewOfKind:MonthBackgroundViewKind withIndexPath:path];
		attribs.frame = UIEdgeInsetsInsetRect(monthRect, self.monthInsets);
		attribs.zIndex = 2;
		[monthsInfo setObject:attribs forKey:path];
	}
	
	self.contentHeight = y;
	
	[layoutInfo setObject:dayCellsInfo forKey:@"DayCellInfo"];
	[layoutInfo setObject:monthsInfo forKey:@"MonthInfo"];
	[layoutInfo setObject:rowsInfo forKey:@"RowsInfo"];
	
	self.layoutInfo = layoutInfo;
}

- (CGSize)collectionViewContentSize
{
	return CGSizeMake(self.collectionView.bounds.size.width, self.contentHeight);
}

- (NSArray*)layoutAttributesForElementsInRect:(CGRect)rect
{
	NSMutableArray *allAttribs = [NSMutableArray arrayWithCapacity:self.layoutInfo.count];
	
    for (NSString *kind in self.layoutInfo)
	{
        NSDictionary *attributesDict = [self.layoutInfo objectForKey:kind];
        for (NSIndexPath *key in attributesDict)
		{
            UICollectionViewLayoutAttributes *attributes = [attributesDict objectForKey:key];
            if (CGRectIntersectsRect(rect, attributes.frame))
			{
				[allAttribs addObject:attributes];
            }
        }
    }
    return allAttribs;
}

- (UICollectionViewLayoutAttributes*)layoutAttributesForItemAtIndexPath:(NSIndexPath*)indexPath
{
	NSDictionary *layout = [self.layoutInfo objectForKey:@"DayCellInfo"];
	return [layout objectForKey:indexPath];
}

- (UICollectionViewLayoutAttributes*)layoutAttributesForSupplementaryViewOfKind:(NSString*)kind atIndexPath:(NSIndexPath*)indexPath
{
	UICollectionViewLayoutAttributes *attribs = nil;
	if ([kind isEqualToString:MonthBackgroundViewKind] || [kind isEqualToString:MonthHeaderViewKind]) {
		NSDictionary *layout = [self.layoutInfo objectForKey:@"MonthInfo"];
		attribs = [layout objectForKey:indexPath];
	}
	else if ([kind isEqualToString:MonthRowViewKind]) {
		NSDictionary *layout = [self.layoutInfo objectForKey:@"RowsInfo"];
		attribs = [layout objectForKey:indexPath];
	}
	return attribs;
}

@end
