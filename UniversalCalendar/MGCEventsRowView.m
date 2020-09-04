//
//  MGCEventsRowView.m
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
#import "MGCEventsRowView.h"

static const CGFloat kCellSpacing = 2.;		// space around cells


@interface MGCEventsRowView ()

@property (nonatomic) NSMutableDictionary *cells;		// dictionary of event cells [ { indexPath (day, item) : cell }, ... ]
@property (nonatomic) NSMutableArray *labels;			// array of "more events" UILabels
@property (nonatomic) NSMutableDictionary *eventsCount;	// cache of events count per day [ { day : count }, ... ]

@end


@implementation MGCEventsRowView

@dynamic delegate;

- (id)initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame])
	{
        _cells = [[NSMutableDictionary alloc]initWithCapacity:25];
		_itemHeight = 18;
		_labels = [NSMutableArray array];
		_dayWidth = 100;

		self.contentSize = CGSizeMake(frame.size.width, 400);
		
		self.backgroundColor = [UIColor clearColor];
		
		self.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
		self.clipsToBounds = YES;
		
		UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(handleTap:)];
		[self addGestureRecognizer:tapGesture];
    }
    return self;
}

- (void)layoutSubviews
{
	[super layoutSubviews];
    [self reload];
    // possible optimization: we shouldn't have to reload everything but only to recompute the frames of the cells
    
}

- (NSUInteger)maxVisibleLinesForDaysInRange:(NSRange)range
{
	NSUInteger count = 0;
	for (NSUInteger day = range.location; day < NSMaxRange(range); day++)
	{
		count = MAX(count, [self numberOfEventsForDayAtIndex:day]);
	}
	// if count > max, we have to keep one row to show "x more events"
	return count > self.maxVisibleLines ? self.maxVisibleLines - 1 : count;
}

- (NSUInteger)maxVisibleLines
{
	return (self.bounds.size.height + kCellSpacing  +1) / (self.itemHeight + kCellSpacing);
}

// { (day, item): range, ... }
- (NSDictionary*)eventRanges
{
	NSMutableDictionary *eventRanges = [NSMutableDictionary new];
	
	for (NSUInteger day = self.daysRange.location; day < NSMaxRange(self.daysRange); day++)
	{
		NSUInteger eventsCount = [self numberOfEventsForDayAtIndex:day];
		
		for (int item = 0; item < eventsCount; item++)
		{
			NSIndexPath *path = [NSIndexPath indexPathForItem:item inSection:day];
			NSRange eventRange = [self.delegate eventsRowView:self rangeForEventAtIndexPath:path];
			
			// keep only those events starting at current column,
			// or those started earlier if this is the first day of the row range
			if (eventRange.location == day || day == self.daysRange.location)
			{
				NSRange rangeEventInRow = NSIntersectionRange(eventRange, self.daysRange);
				[eventRanges setObject:[NSValue valueWithRange:rangeEventInRow] forKey:path];
			}
		}
	}
	
	return eventRanges;
}

- (NSUInteger)numberOfEventsForDayAtIndex:(NSUInteger)day
{
	NSNumber *count = [self.eventsCount objectForKey:[NSNumber numberWithUnsignedInteger:day]];
	if (!count)
	{
		NSUInteger numEvents = [self.delegate eventsRowView:self numberOfEventsForDayAtIndex:day];
		count = [NSNumber numberWithUnsignedInteger:numEvents];
		
		if (!self.eventsCount)
		{
			self.eventsCount = [NSMutableDictionary dictionaryWithCapacity:self.daysRange.length];
		}

		[self.eventsCount setObject:count forKey:[NSNumber numberWithUnsignedInteger:day]];
	}
	
	return [count unsignedIntegerValue];
}

- (void)reload
{
	//NSLog(@"reload date: %@, range: %@", self.referenceDate, NSStringFromRange(self.daysRange));
	//NSLog(@"total created: %d, unused: %d", [[EventsRowView cellsReuseQueue]totalCreated], [[EventsRowView cellsReuseQueue]count]);
	
	[self recycleEventsCells];
	self.eventsCount = nil;
	
	NSDictionary *eventRanges = [self eventRanges];
	// dictionary of "more events" labels [ { day : count of hidden events }, ... ]
	NSMutableDictionary *daysWithMoreEvents = [NSMutableDictionary dictionaryWithCapacity:self.daysRange.length];
	
	// arrange events on lines
	NSMutableArray *lines = [NSMutableArray new];
		
	for (NSIndexPath *indexPath in [[eventRanges allKeys]sortedArrayUsingSelector:@selector(compare:)])
	{
		NSRange eventRange = [[eventRanges objectForKey:indexPath]rangeValue];
		
		NSInteger numLine = -1; // index of the line where to insert the event (i.e the group of cells)
		
		for (NSUInteger i = 0; i < lines.count; i++)
		{
			NSMutableIndexSet *indexes = [lines objectAtIndex:i];
			if (![indexes intersectsIndexesInRange:eventRange])
			{
				numLine = i; // found the right line !
				break;
			}
		}
		if (numLine == -1) // meaning no line was yet created, or the group does not fit any
		{
			numLine = [lines count];
			[lines addObject:[NSMutableIndexSet indexSetWithIndexesInRange:eventRange]];
		}
		else
		{
			[[lines objectAtIndex:numLine] addIndexesInRange:eventRange];
		}
		
		NSUInteger maxVisibleEvents = [self maxVisibleLinesForDaysInRange:eventRange];
		if (numLine < maxVisibleEvents)
		{
			MGCEventView *cell = [self.delegate eventsRowView:self cellForEventAtIndexPath:indexPath];
			cell.frame = [self rectForCellWithRange:eventRange line:numLine];

			if ([self.delegate respondsToSelector:@selector(eventsRowView:willDisplayCell:forEventAtIndexPath:)]) {
				[self.delegate eventsRowView:self willDisplayCell:cell forEventAtIndexPath:indexPath];
			}
			
			[self addSubview:cell];
			[cell setNeedsDisplay];
			
			[self.cells setObject:cell forKey:indexPath];
		}
		else
		{
			for (NSUInteger day = eventRange.location; day < NSMaxRange(eventRange); day++)
			{
				NSUInteger count = [[daysWithMoreEvents objectForKey:@(day)]unsignedIntegerValue];
				count++;
				[daysWithMoreEvents setObject:@(count) forKey:@(day)];
			}
		}
	}
	
	for (NSUInteger day = self.daysRange.location; day < NSMaxRange(self.daysRange); day++)
	{
		NSUInteger hiddenCount = [[daysWithMoreEvents objectForKey:@(day)]unsignedIntegerValue];
		if (hiddenCount)
		{
			UILabel *label = [[UILabel alloc]initWithFrame:CGRectZero];
			label.text = [NSString stringWithFormat:NSLocalizedString(@"%lu more...", nil), (unsigned long)hiddenCount];
			label.textColor = [UIColor grayColor];
			label.textAlignment = NSTextAlignmentRight;
			label.font = [UIFont systemFontOfSize:11];
			label.frame = [self rectForCellWithRange:NSMakeRange(day, 1) line:self.maxVisibleLines - 1];
			
			[self addSubview:label];
			[self.labels addObject:label];
		}
	}
}

- (NSArray*)cellsInRect:(CGRect)rect
{
	NSMutableArray *cells = [NSMutableArray arrayWithCapacity:self.cells.count];
	for (NSIndexPath *path in self.cells)
	{
		MGCEventView *cell = [self.cells objectForKey:path];
		if (CGRectIntersectsRect(cell.frame, rect))
		{
			[cells addObject:cell];
		}
	}
	return cells;
}

- (NSIndexPath*)indexPathForCellAtPoint:(CGPoint)pt
{
	for (NSIndexPath *path in self.cells)
	{
		MGCEventView *cell = [self.cells objectForKey:path];
		if (CGRectContainsPoint(cell.frame, pt))
		{
			return path;
		}
	}
	return nil;
}

- (MGCEventView*)cellAtIndexPath:(NSIndexPath *)indexPath
{
	return [self.cells objectForKey:indexPath];
}

- (void)prepareForReuse
{
	[self recycleEventsCells];
}

- (void)recycleEventsCells
{
	for (NSIndexPath *path in self.cells) {
		MGCEventView *cell = [self.cells objectForKey:path];

		[cell removeFromSuperview];
		
		if ([self.delegate respondsToSelector:@selector(eventsRowView:didEndDisplayingCell:forEventAtIndexPath:)]) {
			[self.delegate eventsRowView:self didEndDisplayingCell:cell forEventAtIndexPath:path];
		}
	}
	[self.cells removeAllObjects];
	
	for (UILabel *label in self.labels) {
		[label removeFromSuperview];
	}
	[self.labels removeAllObjects];
	
	//NSLog(@"recycle %d cells", self.cells.count);
}

- (CGRect)rectForCellWithRange:(NSRange)range line:(NSUInteger)line
{
	NSUInteger colStart = range.location - self.daysRange.location;
	
	CGFloat x = self.dayWidth * colStart;
	if ([self.delegate respondsToSelector:@selector(eventsRowView:widthForDayRange:)])
		x = [self.delegate eventsRowView:self widthForDayRange:NSMakeRange(0, colStart)];
	
	CGFloat y = line * (self.itemHeight + kCellSpacing);

	CGFloat width = self.dayWidth * range.length;
	if ([self.delegate respondsToSelector:@selector(eventsRowView:widthForDayRange:)])
		width = [self.delegate eventsRowView:self widthForDayRange:NSMakeRange(colStart, range.length)];
	
	CGRect rect = CGRectMake(x, y, width, self.itemHeight);
	return CGRectInset(rect, kCellSpacing, 0);
}


#pragma mark - Gestures

- (void)didTapCell:(MGCEventView*)cell atIndexPath:(NSIndexPath*)path
{
	if (cell.selected)
	{
		BOOL shouldDeselect = YES;
		if ([self.delegate respondsToSelector:@selector(eventsRowView:shouldDeselectCellAtIndexPath:)])
			shouldDeselect = [self.delegate eventsRowView:self shouldDeselectCellAtIndexPath:path];
		
		if (shouldDeselect)
		{
			cell.selected = NO;
			if ([self.delegate respondsToSelector:@selector(eventsRowView:didDeselectCellAtIndexPath:)]) {
				[self.delegate eventsRowView:self didDeselectCellAtIndexPath:path];
			}
		}
	}
	else
	{
		BOOL shouldSelect = YES;
		if ([self.delegate respondsToSelector:@selector(eventsRowView:shouldSelectCellAtIndexPath:)])
			shouldSelect = [self.delegate eventsRowView:self shouldSelectCellAtIndexPath:path];
		
		if (shouldSelect)
		{
			cell.selected = YES;
			if ([self.delegate respondsToSelector:@selector(eventsRowView:didSelectCellAtIndexPath:)]) {
				[self.delegate eventsRowView:self didSelectCellAtIndexPath:path];
			}
		}
	}
}

- (void)handleTap:(UITapGestureRecognizer*)recognizer
{
	CGPoint pt = [recognizer locationInView:self];
	
	for (NSIndexPath *path in self.cells)
	{
		MGCEventView *cell = [self.cells objectForKey:path];
		
		if (CGRectContainsPoint(cell.frame, pt))
		{
			[self didTapCell:cell atIndexPath:path];
			break;
		}
	}
}

- (UIView*)hitTest:(CGPoint)point withEvent:(UIEvent *)event
{
	UIView *hitView = [super hitTest:point withEvent:event];
    return (hitView == self) ? nil : hitView;
}

@end
