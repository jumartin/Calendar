//
//  MGCMonthPlannerView.m
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

#import "MGCMonthPlannerView.h"
#import "NSCalendar+MGCAdditions.h"
#import "OrderedDictionary.h"
#import "MGCReusableObjectQueue.h"
#import "MGCMonthPlannerViewLayout.h"
#import "MGCMonthPlannerViewDayCell.h"
#import "MGCMonthPlannerBackgroundView.h"
#import "MGCMonthPlannerWeekView.h"
#import "MGCEventsRowView.h"


// reuse identifiers for collection view cells and supplementary views
static NSString* const DayCellIdentifier = @"DayCellIdentifier";
static NSString* const MonthRowViewIdentifier = @"MonthRowViewIdentifier";
static NSString* const MonthBackgroundViewIdentifier = @"MonthBackgroundViewIdentifier";
static NSString* const EventsRowViewIdentifier = @"EventsRowViewIdentifier";

// we only load in the collection view (2 * kMonthsLoadingStep + 1) months each at a time.
// this value can be tweaked for performance or smoother scrolling (between 2 and 4 seems reasonable)
static const NSUInteger kMonthsLoadingStep = 2;

static const NSUInteger kRowCacheSize = 40;			// number of rows to cache (cells / layout)
static const CGFloat kDragScrollOffset = 20.;
static const CGFloat kDragScrollZoneSize = 20.;


#pragma mark -

typedef enum
{
	CalendarViewScrollingUp = 1 << 0,
	CalendarViewScrollingDown = 1 << 1
} CalendarViewScrollingDirection;


@interface MGCMonthPlannerView () <UICollectionViewDataSource, MGCMonthPlannerViewLayoutDelegate, MGCEventsRowViewDelegate>

@property (nonatomic, readonly) UICollectionView *eventsView;		// main view
@property (nonatomic) CALayer *headerBorderLayer;					// header bottom border
@property (nonatomic, readonly) MGCMonthPlannerViewLayout *layout;	// collection view layout
@property (nonatomic, copy) NSDate *startDate;						// always the first day of a month
@property (nonatomic, readonly) NSDate *maxStartDate;				// maximum date for the start of a loaded page of the collection view - set with dateRange, nil for infinite scrolling
@property (nonatomic, readonly) NSUInteger numberOfLoadedMonths;	// number of months loaded at once in the collection views
@property (nonatomic, readonly) MGCDateRange* loadedDateRange;		// date range of all months currently loaded in the collection views
@property (nonatomic) NSDateFormatter *dateFormatter;				// date formatter for day cells
@property (nonatomic, readonly) NSArray *dayLabels;					// week day labels (UILabel) for header view
@property (nonatomic) MGCReusableObjectQueue *reuseQueue;			// reuse queue for MGCEventsRowView and MGCEventView objects
@property (nonatomic) MutableOrderedDictionary *eventRows;			// cache of MRU MGCEventsRowView objects indexed by start date
@property (nonatomic) NSMutableDictionary *visibleRows;				// visible rows  { startingDay : rowView }
@property (nonatomic) MGCEventView *interactiveCell;				// cell moved around during drag and drop
@property (nonatomic) BOOL isInteractiveCellForNewEvent;			// YES if the interactive cell is for a new event
@property (nonatomic) CGPoint interactiveCelltouchPoint;			// touch point in cell coordinates
@property (nonatomic) NSInteger dragEventIndex;						// event index for the cell being dragged
@property (nonatomic) NSDate *dragEventDate;						// starting date for the cell being dragged
@property (nonatomic) MGCDateRange *dragEventDateRange;				// date range (day+time) of the event being moved
@property (nonatomic) NSUInteger dragEventTouchDayOffset;			// touch offset from start of event
@property (nonatomic, weak) NSTimer *dragTimer;

@end


@implementation MGCMonthPlannerView

// readonly properties whose getter's defined are not auto-synthesized
@synthesize eventsView = _eventsView;
@synthesize dayLabels = _dayLabels;
@synthesize startDate = _startDate;


#pragma mark - Initialization

- (void)setup
{
	_calendar = [NSCalendar currentCalendar];
	_dateFormatter = [NSDateFormatter new];
	_dateFormatter.calendar = _calendar;
	_dateFormatter.timeStyle = NSDateFormatterNoStyle;
	_dateFormatter.dateStyle = NSDateFormatterMediumStyle;
	_rowHeight = 140.;
	_headerHeight = 35;
	_itemHeight = 16;
	_reuseQueue = [MGCReusableObjectQueue new];
	_eventRows = [MutableOrderedDictionary dictionaryWithCapacity:kRowCacheSize];
	_visibleRows = [NSMutableDictionary dictionaryWithCapacity:20];
	_dragEventIndex = -1;
	
	self.backgroundColor = [UIColor clearColor];
	
	[self.reuseQueue registerClass:MGCEventsRowView.class forObjectWithReuseIdentifier:EventsRowViewIdentifier];
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationDidReceiveMemoryWarning:) name:UIApplicationDidReceiveMemoryWarningNotification object:nil];
}

- (id)initWithCoder:(NSCoder*)coder
{
	if (self = [super initWithCoder:coder]) {
		[self setup];
	}
	return self;
}

- (id)initWithFrame:(CGRect)frame
{
	if (self = [super initWithFrame:frame]) {
		[self setup];
	}
	return self;
}

- (void)dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];  // for UIApplicationDidReceiveMemoryWarningNotification
}

- (void)applicationDidReceiveMemoryWarning:(NSNotification*)notification
{
	// remove all cached events rows not currently displayed
	NSMutableArray *delete = [NSMutableArray array];
	
	for (NSDate *date in self.eventRows.allKeys) {
		if (![self.visibleDays containsDate:date]) {
			[delete addObject:date];
		}
	}
	[self.eventRows removeObjectsForKeys:delete];
}

#pragma mark - Layout

- (MGCMonthPlannerViewLayout*)layout
{
	return (MGCMonthPlannerViewLayout*)self.eventsView.collectionViewLayout;
}

// public
- (void)setDateRange:(MGCDateRange*)dateRange
{
	// nil dateRange means 'inifinite' scrolling
	if (dateRange != _dateRange && ![dateRange isEqual:_dateRange]) {
		NSDate *firstDate = self.visibleDays.start;
		
		_dateRange = nil;
		
		if (dateRange) {
			
			// adjust start and end date of new range on month boundaries
			NSDate *start = [self.calendar mgc_startOfMonthForDate:dateRange.start];
			NSDate *end = [self.calendar mgc_startOfMonthForDate:dateRange.end];
			_dateRange = [MGCDateRange dateRangeWithStart:start end:end];
			
			// adjust startDate so that it falls inside new range
			if (![_dateRange includesDateRange:self.loadedDateRange]) {
				self.startDate = _dateRange.start;
			}
			
			if (![_dateRange containsDate:firstDate]) {
				firstDate = [NSDate date];
				if (![_dateRange containsDate:firstDate]) {
					firstDate = _dateRange.start;
				}
			}
		}
		
		[self.eventsView reloadData];
		
		[self scrollToDate:firstDate animated:NO];
	}
}

// public
- (MGCDateRange*)visibleDays
{
	MGCDateRange *range = nil;
	
	NSArray *visible = [[self.eventsView indexPathsForVisibleItems]sortedArrayUsingSelector:@selector(compare:)];
	if (visible.count) {
		NSDate *first = [self dateForDayAtIndexPath:[visible firstObject]];
		NSDate *last = [self dateForDayAtIndexPath:[visible lastObject]];
		
		// end date of the range is excluded, so set it to next day
		NSDateComponents *comps = [NSDateComponents new];
		comps.day = 1;
		last = [self.calendar dateByAddingComponents:comps toDate:last options:0];
		
		range = [MGCDateRange dateRangeWithStart:first end:last];
	}
	return range;
}

#pragma mark - Private properties

- (NSDate*)startDate
{
	if (_startDate == nil) {
		_startDate = [self.calendar mgc_startOfMonthForDate:[NSDate date]];
		
		if (self.dateRange && ![self.dateRange containsDate:_startDate]) {
			_startDate = self.dateRange.start;
		}
	}
	return _startDate;
}

- (void)setStartDate:(NSDate*)startDate
{
	startDate = [self.calendar mgc_startOfMonthForDate:startDate];
	
	NSAssert([startDate compare:self.dateRange.start] !=  NSOrderedAscending, @"start date not in the scrollable date range");
	NSAssert([startDate compare:self.maxStartDate] != NSOrderedDescending, @"start date not in the scrollable date range");
	
	_startDate = startDate;
	
	//NSLog(@"Loaded days range: %@", self.loadedDateRange);
}

- (NSDate*)maxStartDate
{
	NSDate *date = nil;
	
	if (self.dateRange) {
		NSDateComponents *comps = [NSDateComponents new];
		comps.month = -(2 * kMonthsLoadingStep + 1);
		date = [self.calendar dateByAddingComponents:comps toDate:self.dateRange.end options:0];
		
		if ([date compare:self.dateRange.start] == NSOrderedAscending) {
			date = self.dateRange.start;
		}
	}
	return date;
}

- (NSUInteger)numberOfLoadedMonths
{
	NSUInteger numMonths = (2 * kMonthsLoadingStep + 1);
	if (self.dateRange) {
		NSInteger diff = [self.dateRange components:NSMonthCalendarUnit forCalendar:self.calendar].month;
		numMonths = MIN(numMonths, diff);  // cannot load more than the total number of scrollable months
	}
	return numMonths;
}

// range of loaded months
- (MGCDateRange*)loadedDateRange
{
	NSDateComponents *comps = [NSDateComponents new];
	comps.month = self.numberOfLoadedMonths;
	NSDate *endDate = [self.calendar dateByAddingComponents:comps toDate:self.startDate options:0];
	return [MGCDateRange dateRangeWithStart:self.startDate end:endDate];
}


#pragma mark - Utilities

// indexPath is in the form (day, month)
- (NSDate*)dateForDayAtIndexPath:(NSIndexPath*)indexPath
{
	NSDateComponents *comp = [NSDateComponents new];
	comp.month = indexPath.section;
	comp.day = indexPath.item;
	return [self.calendar dateByAddingComponents:comp toDate:self.startDate options:0];
}

// index path for given date - can be nil if date is not in the loaded range
- (NSIndexPath*)indexPathForDate:(NSDate*)date
{
	NSIndexPath *indexPath = nil;
	if ([[self loadedDateRange] containsDate:date]) {
		NSDateComponents *comps = [self.calendar components:NSCalendarUnitMonth|NSCalendarUnitDay fromDate:self.startDate toDate:date options:0];
		indexPath = [NSIndexPath indexPathForItem:comps.day inSection:comps.month];
	}
	return indexPath;
}

// array of all index paths for days in given range.
// range start should be on day boundary.
// can return empty array if range does not intersect loaded month range
- (NSArray*)indexPathsForDaysInRange:(MGCDateRange*)range
{
	NSMutableArray *paths = [NSMutableArray array];
	
	NSDateComponents *comps = [NSDateComponents new];
	comps.day = 0;

	NSDate *date = [self.calendar mgc_startOfDayForDate:range.start];
	while ([range containsDate:date]) {
		NSIndexPath *path = [self indexPathForDate:date];
		if (path) {
			[paths addObject:path];
		}
		
		comps.day++;
		date = [self.calendar dateByAddingComponents:comps toDate:range.start options:0];
	}

	return paths;
}

// first day of month at index
- (NSDate*)dateStartingMonthAtIndex:(NSUInteger)month
{
	return [self dateForDayAtIndexPath:[NSIndexPath indexPathForItem:0 inSection:month]];
}

- (NSUInteger)numberOfDaysForMonthAtIndex:(NSUInteger)month
{
	NSDate *date = [self dateStartingMonthAtIndex:month];
	NSRange range = [self.calendar rangeOfUnit:NSDayCalendarUnit inUnit:NSMonthCalendarUnit forDate:date];
	return range.length;
}

- (NSUInteger)columnForDayAtIndexPath:(NSIndexPath*)indexPath
{
	NSDate *date = [self dateForDayAtIndexPath:indexPath];
	
	NSUInteger weekday = [self.calendar components:NSWeekdayCalendarUnit fromDate:date].weekday;
	// zero-based, 0 is the first day of week of current calendar
	weekday = (weekday + 7 - self.calendar.firstWeekday) % 7;
	return weekday;
}

- (CGRect)rectForMonthAtIndex:(NSUInteger)month
{
	NSIndexPath *first = [NSIndexPath indexPathForItem:0 inSection:month];
	
	CGFloat top = [self.eventsView layoutAttributesForItemAtIndexPath:first].frame.origin.y;
	top -= self.layout.monthInsets.top;
	
	NSUInteger numDays = [self numberOfDaysForMonthAtIndex:month];
	NSIndexPath *last = [NSIndexPath indexPathForItem:numDays - 1 inSection:month];
	CGFloat bottom = CGRectGetMaxY([self.eventsView layoutAttributesForItemAtIndexPath:last].frame);
	bottom += self.layout.monthInsets.bottom;
	
	return CGRectMake(0, top, self.bounds.size.width, bottom - top);
}

- (void)reload
{
	[self.visibleRows removeAllObjects];
	[self clearRowsCacheInDateRange:nil];
	[self.eventsView reloadData];
}

#pragma mark - Public

- (void)registerClass:(Class)objectClass forEventCellReuseIdentifier:(NSString*)reuseIdentifier
{
	[self.reuseQueue registerClass:objectClass forObjectWithReuseIdentifier:reuseIdentifier];
}

- (MGCEventView*)dequeueReusableCellWithIdentifier:(NSString *)reuseIdentifier forEventAtIndex:(NSUInteger)index date:(NSDate*)date
{
	MGCEventView* cell = (MGCEventView*)[self.reuseQueue dequeueReusableObjectWithReuseIdentifier:reuseIdentifier];
	return cell;
}

- (void)reloadEvents
{
	[self clearRowsCacheInDateRange:nil];
			
	for (NSDate *date in self.visibleRows) {
		[self reloadRowStartingAtDate:date];
	}
}

- (void)reloadEventsInRange:(MGCDateRange*)range
{
	MGCDateRange *visibleDateRange = [self visibleDays];
	
	for (NSDate *date in [self.eventRows.allKeys copy]) {
		if ([range containsDate:date]) {
			[self removeRowAtDate:date];
			
			if ([visibleDateRange containsDate:date]) {
				[self reloadRowStartingAtDate:date];
			}
		}
	}
}

- (NSArray*)visibleEventCells
{
	NSMutableArray *cells = [NSMutableArray new];
	
	for (MGCEventsRowView *rowView in [self visibleEventRows]) {
		CGRect rect = [rowView convertRect:self.bounds fromView:self];
		[cells addObjectsFromArray:[rowView cellsInRect:rect]];
	}
	
	return cells;
}

- (MGCEventView*)cellForEventAtIndex:(NSUInteger)index date:(NSDate*)date
{
	for (MGCEventsRowView *rowView in [self visibleEventRows])
	{
		NSUInteger day = [self.calendar components:NSDayCalendarUnit fromDate:rowView.referenceDate toDate:date options:0].day;
		if (NSLocationInRange(day, rowView.daysRange))
		{
			return [rowView cellAtIndexPath:[NSIndexPath indexPathForItem:index inSection:day]];
		}
		
	}
	return nil;
}

- (MGCEventView*)eventCellAtPoint:(CGPoint)pt date:(NSDate**)date index:(NSUInteger*)index
{
	for (MGCEventsRowView *rowView in [self visibleEventRows])
	{
		CGPoint ptInRow = [rowView convertPoint:pt fromView:self];
		NSIndexPath *path = [rowView indexPathForCellAtPoint:ptInRow];
		if (path)
		{
			NSDateComponents *comps = [NSDateComponents new];
			comps.day = path.section;
			*date = [self.calendar dateByAddingComponents:comps toDate:rowView.referenceDate options:0];
			*index = path.item;
			return [rowView cellAtIndexPath:path];
		}
	}
	
	return nil;
}

- (NSDate*)dayAtPoint:(CGPoint)pt
{
	pt = [self.eventsView convertPoint:pt fromView:self];
	NSIndexPath *path = [self.eventsView indexPathForItemAtPoint:pt];
	if (path) {
		return [self dateForDayAtIndexPath:path];
	}
	return nil;
}

- (void)endInteraction
{
	if (self.interactiveCell) {
		self.interactiveCell.hidden = YES;
		[self.interactiveCell removeFromSuperview];
		self.interactiveCell = nil;
	}
	self.interactiveCelltouchPoint = CGPointZero;
	
	self.dragEventDateRange = nil;
	self.dragEventDate = nil;
	self.dragEventIndex = -1;
	self.dragEventTouchDayOffset = 0;

	[self highlightDaysInRange:nil];
}

- (void)selectEventCellAtIndex:(NSUInteger)index date:(NSDate*)date
{
	MGCEventView *cell = [self cellForEventAtIndex:index date:date];
	cell.selected = YES;
}

- (void)deselectEventCellAtIndex:(NSUInteger)index date:(NSDate*)date
{
	MGCEventView *cell = [self cellForEventAtIndex:index date:date];
	cell.selected = NO;
}

#pragma mark - Scrolling

-(void)scrollToDate:(NSDate*)date animated:(BOOL)animated
{
	NSAssert(date, @"scrollToDate:date: was passed nil date");
	
	// check if date in range
	if (self.dateRange && ![self.dateRange containsDate:date])
		[NSException raise:@"Invalid parameter" format:@"date %@ is not in range %@ for this month planner view", date, self.dateRange];
	
	NSDate *firstInMonth = [self.calendar mgc_startOfMonthForDate:date];
	
	// calc new startDate
	NSInteger diff = [self adjustStartDate:firstInMonth byNumberOfMonths:-kMonthsLoadingStep];
	
	[self reload];
	
	NSIndexPath *top = [NSIndexPath indexPathForItem:0 inSection:diff];
	[self.eventsView scrollToItemAtIndexPath:top atScrollPosition:UICollectionViewScrollPositionTop animated:animated];
	
	// this is needed, or subsequent call to visibleDateRange may fail
	[self.eventsView layoutIfNeeded];
	
	if ([self.delegate respondsToSelector:@selector(monthPlannerViewDidScroll:)]) {
		[self.delegate monthPlannerViewDidScroll:self];
	}
}

// adjusts startDate by offsetting date by given months within calendar date range.
// returns the distance in months between date and new start.
- (NSUInteger)adjustStartDate:(NSDate*)date byNumberOfMonths:(NSInteger)months
{
	NSDateComponents *comps = [NSDateComponents new];
	comps.month = months;
	NSDate *start = [self.calendar dateByAddingComponents:comps toDate:date options:0];
	
	if ([start compare:self.dateRange.start] == NSOrderedAscending) {
		start = self.dateRange.start;
	}
	else if ([start compare:self.maxStartDate] == NSOrderedDescending) {
		start = self.maxStartDate;
	}
	
	NSUInteger diff = abs((int)[self.calendar components:NSMonthCalendarUnit fromDate:start toDate:date options:0].month);
	
	self.startDate = start;
	return diff;
}

// returns new corresponding offset
- (CGFloat)reloadForTargetContentOffset:(CGFloat)yOffset
{
	CGFloat newYOffset = yOffset;
	
	NSUInteger diff;
	if (yOffset <= 0)
	{
		if ((diff = [self adjustStartDate:self.startDate byNumberOfMonths:-kMonthsLoadingStep]) != 0) {
			[self.eventsView reloadData];
			// NOTE: we only use rect origin !!
			newYOffset = [self rectForMonthAtIndex:diff].origin.y + yOffset;
		}
	}
	else if (CGRectGetMaxY(self.eventsView.bounds) >= self.eventsView.contentSize.height)
	{
		if ((diff = [self adjustStartDate:self.startDate byNumberOfMonths:kMonthsLoadingStep]) != 0) {
			newYOffset = yOffset - [self rectForMonthAtIndex:diff].origin.y;
			[self.eventsView reloadData];
		}
	}
	return newYOffset;
}

// returns YES if collection views were reloaded
- (BOOL)recenterIfNeeded
{
	CGPoint contentOffset = self.eventsView.contentOffset;
	
	if (contentOffset.y <= 0.0f || CGRectGetMaxY(self.eventsView.bounds) >= self.eventsView.contentSize.height)
	{
		CGPoint offset = self.eventsView.contentOffset;
		offset.y = [self reloadForTargetContentOffset:offset.y];
		[self.eventsView setContentOffset:offset];
		return YES;
	}
	return NO;
}


#pragma mark - Subviews

- (UICollectionView*)eventsView
{
	if (!_eventsView) {
		MGCMonthPlannerViewLayout *layout = [MGCMonthPlannerViewLayout new];
		layout.rowHeight = self.rowHeight;
		layout.delegate = self;
		
		_eventsView = [[UICollectionView alloc]initWithFrame:CGRectZero collectionViewLayout:layout];
		_eventsView.backgroundColor = [UIColor whiteColor];
		_eventsView.dataSource = self;
		_eventsView.delegate = self;
		_eventsView.showsVerticalScrollIndicator = NO;
		_eventsView.scrollsToTop = NO;
		
		[_eventsView registerClass:MGCMonthPlannerViewDayCell.class forCellWithReuseIdentifier:DayCellIdentifier];
		[_eventsView registerClass:MGCMonthPlannerBackgroundView.class forSupplementaryViewOfKind:MonthBackgroundViewKind withReuseIdentifier:MonthBackgroundViewIdentifier];
		[_eventsView registerClass:MGCMonthPlannerWeekView.class forSupplementaryViewOfKind:MonthRowViewKind withReuseIdentifier:MonthRowViewIdentifier];
		
		UILongPressGestureRecognizer *longPressGesture = [[UILongPressGestureRecognizer alloc]initWithTarget:self action:@selector(handleLongPress:)];
		[_eventsView addGestureRecognizer:longPressGesture];
	}
	return _eventsView;
}

- (CALayer*)headerBorderLayer
{
	if (!_headerBorderLayer) {
		_headerBorderLayer = [CALayer layer];
		_headerBorderLayer.backgroundColor = [UIColor lightGrayColor].CGColor;
		[self.layer addSublayer:_headerBorderLayer];
	}
	return _headerBorderLayer;
}

- (NSArray*)dayLabels
{
	if (_dayLabels == nil) {
		NSDateFormatter *formatter = [NSDateFormatter new];
		formatter.calendar = self.calendar;
		NSArray *days = formatter.shortStandaloneWeekdaySymbols;
		
		NSMutableArray *labels = [NSMutableArray array];
		for (int i = 0; i < 7; i++) {
			UILabel *label = [[UILabel alloc]initWithFrame:CGRectZero];
			label.textAlignment = NSTextAlignmentCenter;
			
			// days array is zero-based, sunday first :
			// translate to get firstWeekday at position 0
			int weekday = (i + self.calendar.firstWeekday - 1 + days.count) % (int)days.count;
			label.text = [days objectAtIndex:weekday];
			
			[labels addObject:label];
		}
		_dayLabels = labels;
	}
	return _dayLabels;
}

- (void)invalidateLayout
{
	//NSLog(@"invalidateLayout");
	
	if (self.bounds.size.width != 0) {
		self.layout.rowHeight = self.rowHeight;
		[self.layout invalidateLayout];
		//[self.layout prepareLayout];
		
		[self reload]; // TODO: we shouldn't have to reload everything...
	}
}

#pragma mark - UIView

- (void)setFrame:(CGRect)frame
{
	[super setFrame:frame];
	[self invalidateLayout];
}

- (void)setNeedsLayout
{
	[super setNeedsLayout];
	[self invalidateLayout];
}

- (void)layoutSubviews
{
	//NSLog(@"layout subviews");
	
	[super layoutSubviews];
	
	self.eventsView.frame = CGRectMake(0, self.headerHeight, self.bounds.size.width, self.bounds.size.height - self.headerHeight);
	if (!self.eventsView.superview) {
		[self addSubview:self.eventsView];
	}
	
	self.headerBorderLayer.frame = CGRectMake(0, self.headerHeight, self.bounds.size.width, 1);
	
	CGFloat xPos = self.layout.monthInsets.left;
	for (int i = 0; i < 7; i++) {
		UILabel *label = [self.dayLabels objectAtIndex:i];
		
		CGFloat width = [self.layout columnWidth:i];
		label.frame = CGRectMake(xPos, 0, width, self.headerHeight);
		if (!label.superview) {
			[self addSubview:label];
		}
		
		xPos += width;
	}
}

#pragma mark - Rows handling

- (NSArray*)visibleEventRows
{
	NSMutableArray *rows = [NSMutableArray new];
	
	MGCDateRange *visibleRange = [self visibleDays];
	if (visibleRange) {
		
		for (NSDate *date in self.eventRows) {
			if ([visibleRange containsDate:date]) {
				[rows addObject:[self.eventRows objectForKey:date]];
			}
		}
	}
	return rows;
}

// if range is nil, remove all entries
- (void)clearRowsCacheInDateRange:(MGCDateRange*)range
{
	for (NSDate *date in [[self.eventRows allKeys]copy])
	{
		if ([range containsDate:date] || range == nil) {
			[self removeRowAtDate:date];
		}
	}
}

- (void)removeRowAtDate:(NSDate*)date
{
	MGCEventsRowView *remove = [self.eventRows objectForKey:date];
	if (remove) {
		[self.reuseQueue enqueueReusableObject:remove];
		[self.eventRows removeObjectForKey:date];
	}
}

- (void)reloadRowStartingAtDate:(NSDate*)rowStart
{
	//NSLog(@"setup row at %@", rowStart);
	
	MGCEventsRowView *eventsView = [self.eventRows objectForKey:rowStart];

	if (!eventsView)
	{
		eventsView = (MGCEventsRowView*)[self.reuseQueue dequeueReusableObjectWithReuseIdentifier:EventsRowViewIdentifier];
		
		NSDate *referenceDate = [self.calendar mgc_startOfMonthForDate:rowStart];
		NSUInteger first = [self.calendar components:NSDayCalendarUnit fromDate:referenceDate toDate:rowStart options:0].day;
		NSUInteger numDays = [self.calendar rangeOfUnit:NSDayCalendarUnit inUnit:NSWeekOfMonthCalendarUnit forDate:rowStart].length;
		
		eventsView.referenceDate = referenceDate;
		eventsView.scrollEnabled = NO;
		eventsView.itemHeight = self.itemHeight;
		eventsView.delegate = self;
		eventsView.daysRange =  NSMakeRange(first, numDays);
		
		[eventsView reload];
	}

	[self cacheRow:eventsView forDate:rowStart];
	
	MGCMonthPlannerWeekView *rowView = [self.visibleRows objectForKey:rowStart];
	rowView.eventsView = eventsView;
}


- (void)cacheRow:(MGCEventsRowView*)eventsView forDate:(NSDate*)date
{
	MGCEventsRowView *rowView = [self.eventRows objectForKey:date];
	if (rowView)
	{
		// if already in the cache, we remove it first
		// because we want to keep the list in strict MRU order
		[self.eventRows removeObjectForKey:date];
	}
	
	[self.eventRows setObject:eventsView forKey:date];
	
	if (self.eventRows.count >= kRowCacheSize)
	{
		[self removeRowAtDate:[self.eventRows keyAtIndex:0]];
	}
}

-(MGCMonthPlannerWeekView*)monthRowViewAtIndexPath:(NSIndexPath*)indexPath
{
	NSDate *rowStart = [self dateForDayAtIndexPath:indexPath];
	MGCMonthPlannerWeekView *rowView = [self.eventsView dequeueReusableSupplementaryViewOfKind:MonthRowViewKind withReuseIdentifier:MonthRowViewIdentifier forIndexPath:indexPath];
	[self.visibleRows setObject:rowView forKey:rowStart];
	
	[self reloadRowStartingAtDate:rowStart];

	return rowView;
}

#pragma mark - Drag and drop

// For non modifiable events like holy days, birthdays... for which delegate method
// shouldStartMovingEventOfType returns NO, we bounce animate the cell when user tries to move it
- (void)bounceAnimateCell:(MGCEventView*)cell
{
	CGRect frame = cell.frame;
	
	[UIView animateWithDuration:0.2 animations:^{
		[UIView setAnimationRepeatCount:2];
		cell.frame = CGRectInset(cell.frame, -4, -2);
	} completion:^(BOOL finished){
		cell.frame = frame;
	}];
}

- (MGCDateRange*)daysRangeFromDateRange:(MGCDateRange*)dateRange
{
	NSDate *start = [self.calendar mgc_startOfDayForDate:dateRange.start];
	NSDate *end = [self.calendar mgc_startOfDayForDate:dateRange.end];
	
	if ([end compare:dateRange.end] != NSOrderedSame)
	{
		NSDateComponents *comps = [NSDateComponents new];
		comps.day = 1;
		end = [self.calendar dateByAddingComponents:comps toDate:end options:0];
	}
	return [MGCDateRange dateRangeWithStart:start end:end];
}

- (void)highlightDaysInRange:(MGCDateRange*)range
{
	if (range)
	{
		NSArray *paths = [self indexPathsForDaysInRange:[self daysRangeFromDateRange:range]];
		for (NSIndexPath *path in paths)
		{
			MGCMonthPlannerViewDayCell *dayCell = (MGCMonthPlannerViewDayCell*)[self.eventsView cellForItemAtIndexPath:path];
			dayCell.highlighted = YES;
		}
	}
	else
	{
		NSArray *visible = [self.eventsView visibleCells];
		for (MGCMonthPlannerViewDayCell *cell in visible)
		{
			cell.highlighted = NO;
		}
	}
}

// returns NO if gesture has to be canceled
// pt is in self coordinates
- (BOOL)didStartLongPressAtPoint:(CGPoint)pt
{
	// just in case previous operation did not end properly...
	[self endInteraction];
	
	NSDate *date = nil;
	NSUInteger index;
	MGCEventView *eventCell = [self eventCellAtPoint:pt date:&date index:&index];
	
	if (eventCell)  // a cell was touched
	{
		// can we move it ?
		if ([self.dataSource respondsToSelector:@selector(monthPlannerView:canMoveCellForEventAtIndex:date:)])
		{
			if (![self.dataSource monthPlannerView:self canMoveCellForEventAtIndex:index date:date]) {
				[self bounceAnimateCell:eventCell];
				return NO;  // cancel gesture
			}
		}
		
		if ([self.delegate respondsToSelector:@selector(monthPlannerView:willStartMovingEventAtIndex:date:)])
		{
			[self.delegate monthPlannerView:self willStartMovingEventAtIndex:index date:date];
		}
		
		self.dragEventDate = date;
		self.dragEventIndex = index;
		self.dragEventDateRange = [self.dataSource monthPlannerView:self dateRangeForEventAtIndex:index date:date];
	
		NSDate *touchDate = [self dayAtPoint:pt];
		NSDate *eventDayStart = [self.calendar mgc_startOfDayForDate:self.dragEventDateRange.start];
		self.dragEventTouchDayOffset = [self.calendar components:NSDayCalendarUnit fromDate:touchDate toDate:eventDayStart options:0].day;
		
		[self highlightDaysInRange:self.dragEventDateRange];

		self.isInteractiveCellForNewEvent = NO;
		self.interactiveCelltouchPoint = [self convertPoint:pt toView:eventCell];
		
		self.interactiveCell = [self.dataSource monthPlannerView:self cellForEventAtIndex:index date:date];

		// adjust the frame
		CGRect frame = [self.eventsView convertRect:eventCell.bounds fromView:eventCell];
		self.interactiveCell.frame = frame;
	}
	else	// an empty space was touched
	{
		self.isInteractiveCellForNewEvent = YES;
		// create a new cell
		if ([self.dataSource respondsToSelector:@selector(monthPlannerView:cellForNewEventAtDate:)])
		{
			self.interactiveCell = [self.dataSource monthPlannerView:self cellForNewEventAtDate:date];
			self.interactiveCell.frame = CGRectMake(0, 0, [self.layout columnWidth:0], self.itemHeight);
			self.interactiveCelltouchPoint = CGPointMake([self.layout columnWidth:0]/2., self.itemHeight/2.);
			self.interactiveCell.center = [self convertPoint:pt toView:self.eventsView];
		}
	}
	
	// show the interactive cell
	self.interactiveCell.selected = YES;
	[self.eventsView addSubview:self.interactiveCell];
	self.interactiveCell.hidden = NO;
	return YES;
}


// point in self coordinates
- (void)moveInteractiveCellAtPoint:(CGPoint)point
{
	[self highlightDaysInRange:nil];
	
	NSDate *hoveredDate = [self dayAtPoint:point];
	if (hoveredDate)
	{
		NSDate *highlightStart = hoveredDate;
		if (self.dragEventDate)
		{
			NSDateComponents *comps = [NSDateComponents new];
			comps.day = self.dragEventTouchDayOffset;
			highlightStart = [self.calendar dateByAddingComponents:comps toDate:hoveredDate options:0];
		}
		
		NSDateComponents *comps = [NSDateComponents new];
		if (self.isInteractiveCellForNewEvent)
		{
			comps.day = 1;
		}
		else
		{
			comps.day = [[self daysRangeFromDateRange:self.dragEventDateRange]components:NSDayCalendarUnit forCalendar:self.calendar].day;
		}
		NSDate *highlightEnd = [self.calendar dateByAddingComponents:comps toDate:highlightStart options:0];
		MGCDateRange *highlight = [MGCDateRange dateRangeWithStart:highlightStart end:highlightEnd];
		
		[self highlightDaysInRange:highlight];
	}
	else
	{
		[self highlightDaysInRange:self.dragEventDateRange];
	}
	
	if (point.y > CGRectGetMaxY(self.eventsView.frame) - kDragScrollZoneSize)
	{
		[self.dragTimer invalidate];
		self.dragTimer = [NSTimer scheduledTimerWithTimeInterval:0.05 target:self selector:@selector(dragTimer:) userInfo:@{@"direction": @(CalendarViewScrollingDown)} repeats:YES];
	}
	else if (point.y < self.headerHeight + kDragScrollZoneSize)
	{
		[self.dragTimer invalidate];
		self.dragTimer = [NSTimer scheduledTimerWithTimeInterval:0.05 target:self selector:@selector(dragTimer:) userInfo:@{@"direction": @(CalendarViewScrollingUp)} repeats:YES];
	}
	else if (self.dragTimer)
	{
		[self.dragTimer invalidate];
		self.dragTimer = nil;
	}
	
	CGRect frame = self.interactiveCell.frame;
	frame.origin = [self convertPoint:point toView:self.eventsView];
	frame = CGRectOffset(frame, -self.interactiveCelltouchPoint.x, -self.interactiveCelltouchPoint.y);
	self.interactiveCell.frame = frame;
}

- (void)didEndLongPressAtPoint:(CGPoint)pt
{
	[self.dragTimer invalidate];
	self.dragTimer = nil;
	
	NSDate *day = [self dayAtPoint:pt];
	if (day)
	{
		if (!self.isInteractiveCellForNewEvent) // existing event
		{
									
			NSDateComponents *comps = [self.calendar components:NSCalendarUnitHour|NSCalendarUnitMinute fromDate:self.dragEventDateRange.start];
			comps.day  = self.dragEventTouchDayOffset;
			NSDate *startDate = [self.calendar dateByAddingComponents:comps toDate:day options:0];

			// move only if new start is different from old start
			if ([startDate compare:self.dragEventDateRange.start] != NSOrderedSame &&
				[self.delegate respondsToSelector:@selector(monthPlannerView:didMoveEventAtIndex:date:toDate:)])
			{
				[self.delegate monthPlannerView:self didMoveEventAtIndex:self.dragEventIndex date:self.dragEventDate toDate:startDate];
				return;
			}
		}
		else	// new event
		{
			if ([self.delegate respondsToSelector:@selector(monthPlannerView:didShowCell:forNewEventAtDate:)])
			{
				[self.delegate monthPlannerView:self didShowCell:self.interactiveCell forNewEventAtDate:day];
				return;
			}
		}
	}
	
	[self endInteraction];
	
	//[self setUserInteractionEnabled:YES];
}

- (void)handleLongPress:(UILongPressGestureRecognizer*)gesture
{
	CGPoint pt = [gesture locationInView:self];
	
	// long press on a cell or an empty space
	if (gesture.state == UIGestureRecognizerStateBegan)
	{
		[self setUserInteractionEnabled:NO];

		if (![self didStartLongPressAtPoint:pt]) {
			// cancel gesture
			gesture.enabled = NO;
			gesture.enabled = YES;
		}
	}
	// interactive cell was moved
	else if (gesture.state == UIGestureRecognizerStateChanged)
	{
		[self moveInteractiveCellAtPoint:pt];
	}
	// finger was lifted
	else if (gesture.state == UIGestureRecognizerStateEnded)
	{
		[self didEndLongPressAtPoint:pt];
		[self setUserInteractionEnabled:YES];
	}
	// gesture was canceled
	else
	{
		[self endInteraction];
		[self setUserInteractionEnabled:YES];
	}
}

- (void)dragTimer:(NSTimer*)timer
{
	NSInteger scrollDirection = [[timer.userInfo objectForKey:@"direction"]integerValue];
		
	CGPoint newOffset = self.eventsView.contentOffset;
	CGRect frame = self.interactiveCell.frame;
	
	if (scrollDirection == CalendarViewScrollingDown)
	{
		newOffset.y = fminf(newOffset.y + kDragScrollOffset, self.eventsView.contentSize.height - self.eventsView.bounds.size.height);
		frame.origin.y += kDragScrollOffset;
	}
	else if (scrollDirection == CalendarViewScrollingUp)
	{
		newOffset.y = fmaxf(newOffset.y - kDragScrollOffset, 0);
		frame.origin.y -= kDragScrollOffset;
	}
	
	self.interactiveCell.frame = frame;
	[self.eventsView setContentOffset:newOffset animated:NO];
}

#pragma mark - UICollectionViewDataSource

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView*)collectionView
{
	return self.numberOfLoadedMonths;
}

- (NSInteger)collectionView:(UICollectionView*)collectionView numberOfItemsInSection:(NSInteger)section
{
	return [self numberOfDaysForMonthAtIndex:section];
}

- (UICollectionViewCell*)collectionView:(UICollectionView*)collectionView cellForItemAtIndexPath:(NSIndexPath*)indexPath
{
	MGCMonthPlannerViewDayCell* cell = [self.eventsView dequeueReusableCellWithReuseIdentifier:DayCellIdentifier forIndexPath:indexPath];
	NSDate *date = [self dateForDayAtIndexPath:indexPath];
	
	if ([self.calendar mgc_isDate:date sameDayAsDate:[NSDate date]])
		cell.marked = YES;
	
	// isDateInWeekend is only in iOS 8 and later
	if ([self.calendar respondsToSelector:@selector(isDateInWeekend:)] && [self.calendar isDateInWeekend:date]) {
		cell.backgroundColor = [UIColor colorWithWhite:.97 alpha:.8];
	}
	else {
		cell.backgroundColor = [UIColor whiteColor/*clearColor*/];
	}
	
	cell.dayLabel.text = [self.dateFormatter stringFromDate:date];
	return cell;
}

- (UICollectionReusableView*)collectionView:(UICollectionView*)collectionView viewForSupplementaryElementOfKind:(NSString*)kind atIndexPath:(NSIndexPath*)indexPath
{
	if ([kind isEqualToString:MonthBackgroundViewKind])
	{
		NSDate *date = [self dateStartingMonthAtIndex:indexPath.section];
		NSUInteger firstColumn = [self columnForDayAtIndexPath:[NSIndexPath indexPathForItem:0 inSection:indexPath.section]];
		NSUInteger lastColumn = [self columnForDayAtIndexPath:[NSIndexPath indexPathForItem:0 inSection:indexPath.section + 1]];
		NSUInteger numRows = [self.calendar rangeOfUnit:NSWeekCalendarUnit inUnit:NSMonthCalendarUnit forDate:date].length;
		
		MGCMonthPlannerBackgroundView *view = [self.eventsView dequeueReusableSupplementaryViewOfKind:MonthBackgroundViewKind withReuseIdentifier:MonthBackgroundViewIdentifier forIndexPath:indexPath];
		view.numberOfColumns = 7;
		view.numberOfRows = numRows;
		view.firstColumn = firstColumn;
		view.lastColumn = lastColumn == 0 ? 7 : lastColumn;

		[view setNeedsDisplay];
		
		return view;
	}
	else if ([kind isEqualToString:MonthRowViewKind])
	{
		MGCMonthPlannerWeekView *view = [self monthRowViewAtIndexPath:indexPath];
		return view;
	}
	return nil;
}


#pragma mark - MGCEventsRowViewDelegate

- (NSUInteger)eventsRowView:(MGCEventsRowView*)view numberOfEventsForDayAtIndex:(NSUInteger)day
{
	NSDateComponents *comps = [NSDateComponents new];
	comps.day = day;
	NSDate *date = [self.calendar dateByAddingComponents:comps toDate:view.referenceDate options:0];
	
	NSUInteger count = [self.dataSource monthPlannerView:self numberOfEventsAtDate:date];
	return count;
}

- (NSRange)eventsRowView:(MGCEventsRowView*)view rangeForEventAtIndexPath:(NSIndexPath*)indexPath
{
	NSDateComponents *comps = [NSDateComponents new];
	comps.day = indexPath.section;
	NSDate *date = [self.calendar dateByAddingComponents:comps toDate:view.referenceDate options:0];
	
	MGCDateRange *dateRange = [self.dataSource monthPlannerView:self dateRangeForEventAtIndex:indexPath.item date:date];
		
	NSInteger start = MAX(0, [self.calendar components:NSCalendarUnitDay fromDate:view.referenceDate toDate:dateRange.start options:0].day);
	NSInteger end = [self.calendar components:NSCalendarUnitDay fromDate:view.referenceDate toDate:dateRange.end options:0].day;
	if ([dateRange.end timeIntervalSinceDate:[self.calendar mgc_startOfDayForDate:dateRange.end]] > 0) {
		end++;
	}
	end = MIN(end, NSMaxRange(view.daysRange));
	
	return NSMakeRange(start, end - start);
}

- (MGCEventView*)eventsRowView:(MGCEventsRowView*)view cellForEventAtIndexPath:(NSIndexPath*)path
{
	NSDateComponents *comps = [NSDateComponents new];
	comps.day = path.section;
	NSDate *date = [self.calendar dateByAddingComponents:comps toDate:view.referenceDate options:0];
	
	return [self.dataSource monthPlannerView:self cellForEventAtIndex:path.item date:date];
}

- (CGFloat)eventsRowView:(MGCEventsRowView*)view widthForDayRange:(NSRange)range
{
	return [self.layout widthForColumnRange:range];
}

- (BOOL)eventsRowView:(MGCEventsRowView*)view shouldSelectCellAtIndexPath:(NSIndexPath*)indexPath
{
	if ([self.delegate respondsToSelector:@selector(monthPlannerView:shouldSelectEventAtIndex:date:)]) {
		NSDateComponents *comps = [NSDateComponents new];
		comps.day = indexPath.section;
		NSDate *date = [self.calendar dateByAddingComponents:comps toDate:view.referenceDate options:0];
		
		return [self.delegate monthPlannerView:self shouldSelectEventAtIndex:indexPath.item date:date];
	}
	return YES;
}

- (void)eventsRowView:(MGCEventsRowView*)view didSelectCellAtIndexPath:(NSIndexPath*)indexPath
{
	if ([self.delegate respondsToSelector:@selector(monthPlannerView:didSelectEventAtIndex:date:)]) {
		NSDateComponents *comps = [NSDateComponents new];
		comps.day = indexPath.section;
		NSDate *date = [self.calendar dateByAddingComponents:comps toDate:view.referenceDate options:0];
		
		[self.delegate monthPlannerView:self didSelectEventAtIndex:indexPath.item date:date];
	}
}

- (BOOL)eventsRowView:(MGCEventsRowView *)view shouldDeselectCellAtIndexPath:(NSIndexPath *)indexPath
{
	if ([self.delegate respondsToSelector:@selector(monthPlannerView:shouldDeselectEventAtIndex:date:)])
	{
		NSDateComponents *comps = [NSDateComponents new];
		comps.day = indexPath.section;
		NSDate *date = [self.calendar dateByAddingComponents:comps toDate:view.referenceDate options:0];
		
		return [self.delegate monthPlannerView:self shouldDeselectEventAtIndex:indexPath.item date:date];
	}
	return YES;
}

- (void)eventsRowView:(MGCEventsRowView *)view didDeselectCellAtIndexPath:(NSIndexPath *)indexPath
{
	if ([self.delegate respondsToSelector:@selector(monthPlannerView:didDeselectEventAtIndex:date:)]) {
		NSDateComponents *comps = [NSDateComponents new];
		comps.day = indexPath.section;
		NSDate *date = [self.calendar dateByAddingComponents:comps toDate:view.referenceDate options:0];
		
		[self.delegate monthPlannerView:self didDeselectEventAtIndex:indexPath.item date:date];
	}
}

- (void)eventsRowView:(MGCEventsRowView*)view willDisplayCell:(MGCEventView*)cell forEventAtIndexPath:(NSIndexPath*)indexPath
{
}

- (void)eventsRowView:(MGCEventsRowView*)view didEndDisplayingCell:(MGCEventView*)cell forEventAtIndexPath:(NSIndexPath*)indexPath
{
	[self.reuseQueue enqueueReusableObject:cell];
}

#pragma mark - MGCMonthPlannerViewLayoutDelegate

- (NSUInteger)collectionView:(UICollectionView*)collectionView layout:(MGCMonthPlannerViewLayout*)layout columnForDayAtIndexPath:(NSIndexPath*)indexPath
{
	return [self columnForDayAtIndexPath:indexPath];
}

- (void)collectionView:(UICollectionView*)collectionView didSelectItemAtIndexPath:(NSIndexPath*)indexPath
{
	if ([self.delegate respondsToSelector:@selector(monthPlannerView:didSelectDayCellAtDate:)]) {
		NSDate *date = [self dateForDayAtIndexPath:indexPath];
		[self.delegate monthPlannerView:self didSelectDayCellAtDate:date];
	}
	
	[self.eventsView deselectItemAtIndexPath:self.eventsView.indexPathsForSelectedItems.firstObject animated:YES];
}

- (void)collectionView:(UICollectionView*)collectionView didEndDisplayingSupplementaryView:(UICollectionReusableView*)view forElementOfKind:(NSString*)elementKind atIndexPath:(NSIndexPath*)indexPath
{
	if ([elementKind isEqualToString:MonthRowViewKind]) {
		NSDate *date = [self dateForDayAtIndexPath:indexPath];
		[self.visibleRows removeObjectForKey:date];
	}
}

- (void)scrollViewDidScroll:(UIScrollView*)scrollview
{
	[self recenterIfNeeded];
	
	// this is needed, or subsequent call to visibleDateRange may fail (?)
	[self.eventsView layoutIfNeeded];
	
	
	if ([self.delegate respondsToSelector:@selector(monthPlannerViewDidScroll:)]) {
		[self.delegate monthPlannerViewDidScroll:self];
	}
}

@end
