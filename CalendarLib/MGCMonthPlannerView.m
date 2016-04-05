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
#import "MGCMonthPlannerHeaderView.h"
#import "MGCStandardEventView.h"
#import "Constant.h"


// reuse identifiers for collection view cells and supplementary views
static NSString* const DayCellIdentifier = @"DayCellIdentifier";
static NSString* const MonthRowViewIdentifier = @"MonthRowViewIdentifier";
static NSString* const MonthHeaderViewIdentifier = @"MonthHeaderViewIdentifier";
static NSString* const MonthBackgroundViewIdentifier = @"MonthBackgroundViewIdentifier";
static NSString* const EventsRowViewIdentifier = @"EventsRowViewIdentifier";

static const NSUInteger kRowCacheSize = 40;			// number of rows to cache (cells / layout)
static const CGFloat kDragScrollOffset = 20.;
static const CGFloat kDragScrollZoneSize = 20.;
static NSString* const kDefaultDateFormat = @"dMMYY";


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
@property (nonatomic) NSMutableArray *dayLabels;                    // week day labels (UILabel) for header view
@property (nonatomic) MGCReusableObjectQueue *reuseQueue;			// reuse queue for MGCEventsRowView and MGCEventView objects
@property (nonatomic) MutableOrderedDictionary *eventRows;			// cache of MRU MGCEventsRowView objects indexed by start date
@property (nonatomic, readwrite) NSDate *selectedEventDate;         // date of the selected event, or nil if no event is selected
@property (nonatomic, readwrite) NSUInteger selectedEventIndex;     // index of the selected event at the date returned by selectedEventDate
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
    _dateFormatter.dateFormat = [NSDateFormatter dateFormatFromTemplate:kDefaultDateFormat options:0 locale:[NSLocale currentLocale]]; //kDefaultDateFormat;
    _rowHeight = isiPad ? 140. : 60.;
    _dayCellHeaderHeight = 30;
    _headerHeight =  35;
    _itemHeight = 16;
    _reuseQueue = [MGCReusableObjectQueue new];
    _eventRows = [MutableOrderedDictionary dictionaryWithCapacity:kRowCacheSize];
    _dragEventIndex = -1;
    _monthHeaderStyle = MGCMonthHeaderStyleDefault;
    _monthInsets = UIEdgeInsetsMake(20, 0, 20, 0);
    _gridStyle = MGCMonthPlannerGridStyleDefault;
    _style = MGCMonthPlannerStyleEvents;
    _eventsDotColor = [UIColor lightGrayColor];
    _allowsSelection = YES;
    _selectedEventDate = nil;
    _canCreateEvents = YES;
    _canMoveEvents = YES;
    _calendarBackgroundColor   = [UIColor whiteColor];
    _weekDayBackgroundColor    = [UIColor whiteColor];
    _weekendDayBackgroundColor = [UIColor colorWithWhite:.97 alpha:.8];
    _weekdaysLabelTextColor    = [UIColor blackColor];
    _monthLabelTextColor       = [UIColor blackColor];
    _monthLabelFont            = [UIFont preferredFontForTextStyle:UIFontTextStyleHeadline];
    
    _dayLabels = [NSMutableArray array];
    for (int i = 0; i < 7; i++) {
        [_dayLabels addObject:[[UILabel alloc]initWithFrame:CGRectZero]];
    }
    
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

    MGCDateRange *visibleDays = self.visibleDays;
    
    for (NSDate *date in self.eventRows.allKeys) {
        if (![visibleDays containsDate:date]) {
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
- (void)setDateFormat:(NSString*)dateFormat
{
    self.dateFormatter.dateFormat = dateFormat ?: kDefaultDateFormat;
    [self.eventsView reloadData];
}

- (NSString*)dateFormat
{
    return self.dateFormatter.dateFormat;
}

// public
- (void)setDayCellHeaderHeight:(CGFloat)dayCellHeaderHeight
{
    _dayCellHeaderHeight = dayCellHeaderHeight;
    self.layout.dayHeaderHeight = dayCellHeaderHeight;
    [self.eventsView reloadData];
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
    [self.eventsView layoutIfNeeded];
    
    MGCDateRange *range = nil;
    
    NSArray *visible = [[self.eventsView indexPathsForVisibleItems]sortedArrayUsingSelector:@selector(compare:)];
    if (visible.count) {
        NSDate *first = [self dateForDayAtIndexPath:[visible firstObject]];
        NSDate *last = [self dateForDayAtIndexPath:[visible lastObject]];
        
        // end date of the range is excluded, so set it to next day
        last = [self.calendar dateByAddingUnit:NSCalendarUnitDay value:1 toDate:last options:0];
        
        range = [MGCDateRange dateRangeWithStart:first end:last];
    }
    return range;
}

- (void)setRowHeight:(CGFloat)rowHeight
{
    if (rowHeight != _rowHeight) {
        _rowHeight = rowHeight;
        self.layout.rowHeight = rowHeight;
        [self.eventsView reloadData];
    }
}

- (void)setMonthInsets:(UIEdgeInsets)monthInsets
{
    if (!UIEdgeInsetsEqualToEdgeInsets(monthInsets, _monthInsets)) {
        _monthInsets = monthInsets;
        self.layout.monthInsets = monthInsets;
        [self setNeedsLayout];
    }
}

- (void)setMonthHeaderStyle:(MGCMonthHeaderStyle)monthHeaderStyle
{
    if (monthHeaderStyle != _monthHeaderStyle) {
        _monthHeaderStyle = monthHeaderStyle;
        [self.eventsView reloadData];
    }
}

- (void)setGridStyle:(MGCMonthPlannerGridStyle)gridStyle
{
    if (gridStyle != _gridStyle) {
        _gridStyle = gridStyle;
        self.layout.alignMonthHeaders = !(gridStyle & MGCMonthPlannerGridStyleFill);
        [self.eventsView reloadData];
    }
}

- (void)setStyle:(MGCMonthPlannerStyle)style
{
    if (style != _style) {
        _style = style;
        self.layout.showEvents = (style == MGCMonthPlannerStyleEvents);
        [self reload];
    }
}

- (void)setEventsDotColor:(UIColor *)eventsDotColor
{
    _eventsDotColor = eventsDotColor;
    [self.eventsView reloadData];
}

- (void)setPagingMode:(MGCMonthPlannerPagingMode)pagingMode
{
    _pagingMode = pagingMode;
    self.eventsView.decelerationRate = pagingMode == MGCMonthPlannerPagingModeNone ? UIScrollViewDecelerationRateNormal : UIScrollViewDecelerationRateFast;
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
        comps.month = -self.numberOfLoadedMonths;
        date = [self.calendar dateByAddingComponents:comps toDate:self.dateRange.end options:0];
        
        if ([date compare:self.dateRange.start] == NSOrderedAscending) {
            date = self.dateRange.start;
        }
    }
    return date;
}

// minimum height of a month
- (CGFloat)monthMinimumHeight
{
    NSUInteger numWeeks = [self.calendar minimumRangeOfUnit:NSCalendarUnitWeekOfMonth].length;
    return numWeeks * self.rowHeight + self.monthInsets.top + self.monthInsets.bottom;
}

// maximum height of a month
- (CGFloat)monthMaximumHeight
{
    NSUInteger numWeeks = [self.calendar maximumRangeOfUnit:NSCalendarUnitWeekOfMonth].length;
    return numWeeks * self.rowHeight + self.monthInsets.top + self.monthInsets.bottom;
}

// height for month containing date
- (CGFloat)heightForMonthAtDate:(NSDate*)date
{
    NSDate *monthStart = [self.calendar mgc_startOfMonthForDate:date];
    NSUInteger numWeeks = [self.calendar rangeOfUnit:NSCalendarUnitWeekOfMonth inUnit:NSCalendarUnitMonth forDate:monthStart].length;
    return numWeeks * self.rowHeight + self.monthInsets.top + self.monthInsets.bottom;
}

// number of months loaded at once in the collection view
- (NSUInteger)numberOfLoadedMonths
{
    // default number of loaded month
    // this can eventually be tweaked for performance or smoother scrolling
    NSUInteger numMonths = 9;
    
    // it cannot be less than the number of months displayable on one screen plus one on each size to accomodate paging
    CGFloat minContentHeight = CGRectGetHeight(self.eventsView.bounds) + 2 * self.monthMaximumHeight;
    NSUInteger minLoadedMonths = ceilf(minContentHeight / self.monthMinimumHeight);
    
    numMonths = MAX(numMonths, minLoadedMonths);
    
    if (self.dateRange) {
		NSInteger diff = [self.dateRange components:NSCalendarUnitMonth forCalendar:self.calendar].month;
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
	NSRange range = [self.calendar rangeOfUnit:NSCalendarUnitDay inUnit:NSCalendarUnitMonth forDate:date];
	return range.length;
}

- (NSUInteger)columnForDayAtIndexPath:(NSIndexPath*)indexPath
{
	NSDate *date = [self dateForDayAtIndexPath:indexPath];
	
	NSUInteger weekday = [self.calendar components:NSCalendarUnitWeekday fromDate:date].weekday;
	// zero-based, 0 is the first day of week of current calendar
	weekday = (weekday + 7 - self.calendar.firstWeekday) % 7;
	return weekday;
}

- (MGCDateRange*)dateRangeForEventsRowView:(MGCEventsRowView*)rowView
{
    NSDate *start = [self.calendar dateByAddingUnit:NSCalendarUnitDay value:rowView.daysRange.location toDate:rowView.referenceDate options:0];
    NSDate *end =  [self.calendar dateByAddingUnit:NSCalendarUnitDay value:NSMaxRange(rowView.daysRange) toDate:rowView.referenceDate options:0];
    return [MGCDateRange dateRangeWithStart:start end:end];
}

// returns the offset from startDate to given month
- (CGFloat)yOffsetForMonth:(NSDate*)date
{
    NSDate *startOfMonth = [self.calendar mgc_startOfMonthForDate:date];
    
    NSDateComponents *comps = [self.calendar components:NSCalendarUnitMonth fromDate:self.startDate toDate:startOfMonth options:0];
    NSUInteger monthsDiff = labs(comps.month);
    
    CGFloat offset = 0;
    
    NSDate *month = [startOfMonth earlierDate:self.startDate];
    for (int i = 0; i < monthsDiff; i++) {
        offset += [self heightForMonthAtDate:month];
        month = [self.calendar dateByAddingUnit:NSCalendarUnitMonth value:1 toDate:month options:0];
    }
    
    if ([startOfMonth compare:self.startDate] == NSOrderedAscending) {
        offset = -offset;
    }
    return offset;
}

// returns start date for the month at given offset
- (NSDate*)monthFromOffset:(CGFloat)yOffset
{
    NSDate *month = self.startDate;
    CGFloat y = yOffset > 0 ? [self heightForMonthAtDate:month] : 0;
    
    while (y < fabs(yOffset)) {
        month = [self.calendar dateByAddingUnit:NSCalendarUnitMonth value:(yOffset > 0 ? 1 : -1) toDate:month options:0];
        y += [self heightForMonthAtDate:month];
    };
    
    return month;
}

- (void)reload
{
    [self deselectEventWithDelegate:YES];
    
    [self clearRowsCacheInDateRange:nil];
    [self.eventsView reloadData];
}

- (CGFloat)maxSizeForFont:(UIFont*)font toFitStrings:(NSArray<NSString*>*)strings inSize:(CGSize)size
{
    NSStringDrawingContext *context = [NSStringDrawingContext new];
    context.minimumScaleFactor = .1;
    
    CGFloat fontSize = font.pointSize;
    
    for (NSString *str in strings) {
        NSAttributedString *attrStr = [[NSAttributedString alloc]initWithString:str attributes:@{ NSFontAttributeName: font }];
        [attrStr boundingRectWithSize:size options:NSStringDrawingUsesLineFragmentOrigin context:context];
        fontSize = fminf(fontSize, font.pointSize * context.actualScaleFactor);
    }
    
    return floorf(fontSize);
}

#pragma mark - Public

- (void)registerClass:(Class)objectClass forEventCellReuseIdentifier:(NSString*)reuseIdentifier
{
    [self.reuseQueue registerClass:objectClass forObjectWithReuseIdentifier:reuseIdentifier];
}

- (MGCEventView*)dequeueReusableCellWithIdentifier:(NSString *)reuseIdentifier forEventAtIndex:(NSUInteger)index date:(NSDate*)date
{
    MGCEventView* cell = (MGCEventView*)[self.reuseQueue dequeueReusableObjectWithReuseIdentifier:reuseIdentifier];
    
    if ([self.selectedEventDate isEqualToDate:date] && index == self.selectedEventIndex)
        cell.selected = YES;
    
    return cell;
}

- (void)reloadEvents
{
    if (self.style == MGCMonthPlannerStyleDots) {
        [self.eventsView reloadData];
    }
    else if (self.style == MGCMonthPlannerStyleEvents) {
        [self deselectEventWithDelegate:YES];
        
        MGCDateRange *visibleDateRange = [self visibleDays];
        
        [[self.eventRows copy] enumerateKeysAndObjectsUsingBlock:^(NSDate *date, MGCEventsRowView *rowView, BOOL* stop) {
            MGCDateRange *rowRange = [self dateRangeForEventsRowView:rowView];
            
            if ([rowRange intersectsDateRange:visibleDateRange]) {
                [rowView reload];
            }
            else {
                [self removeRowAtDate:date];
            }
        }];
    }
}

- (void)reloadEventsAtDate:(NSDate*)date
{
    if (self.style == MGCMonthPlannerStyleDots) {
        NSIndexPath *path = [self indexPathForDate:date];
        if (path) {
            MGCMonthPlannerViewDayCell *cell = (MGCMonthPlannerViewDayCell*)[self.eventsView cellForItemAtIndexPath:path];
            if (cell) {
                NSUInteger eventsCounts = [self.dataSource monthPlannerView:self numberOfEventsAtDate:date];
                cell.showsDot = eventsCounts > 0;
            }
        }
    }
    else if (self.style == MGCMonthPlannerStyleEvents) {
        if ([self.selectedEventDate isEqualToDate:date]) {
            [self deselectEventWithDelegate:YES];
        }
        
        MGCDateRange *visibleDateRange = [self visibleDays];
        
        [[self.eventRows copy] enumerateKeysAndObjectsUsingBlock:^(NSDate *date, MGCEventsRowView *rowView, BOOL* stop) {
            MGCDateRange *rowRange = [self dateRangeForEventsRowView:rowView];
            
            if ([rowRange containsDate:date]) {
                if ([visibleDateRange containsDate:date]) {
                    [rowView reload];
                }
                else {
                    [self removeRowAtDate:date];
                }
            }
        }];
    }
}

- (void)reloadEventsInRange:(MGCDateRange*)range
{
   if (self.style == MGCMonthPlannerStyleDots) {
       
       [range enumerateDaysWithCalendar:self.calendar usingBlock:^(NSDate *day, BOOL *stop) {
           [self reloadEventsAtDate:day];
       }];
    }
    else if (self.style == MGCMonthPlannerStyleEvents) {
        
        if (self.selectedEventDate && [range containsDate:self.selectedEventDate]) {
            [self deselectEventWithDelegate:YES];
        }
        
        MGCDateRange *visibleDateRange = [self visibleDays];
        
        [[self.eventRows copy] enumerateKeysAndObjectsUsingBlock:^(NSDate *date, MGCEventsRowView *rowView, BOOL* stop) {
            MGCDateRange *rowRange = [self dateRangeForEventsRowView:rowView];
            
            if ([rowRange intersectsDateRange:range]) {
                if ([rowRange intersectsDateRange:visibleDateRange]) {
                    [rowView reload];
                }
                else {
                    [self removeRowAtDate:date];
                }
            }
        }];
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
		NSUInteger day = [self.calendar components:NSCalendarUnitDay fromDate:rowView.referenceDate toDate:date options:0].day;
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

#pragma mark - Selection

// public
- (MGCEventView*)selectedEventView
{
    if (self.selectedEventDate) {
        return [self cellForEventAtIndex:self.selectedEventIndex date:self.selectedEventDate];
    }
    return nil;
}

// tellDelegate is used to distinguish between user deselection (touch) where delegate is informed,
// and programmatically deselected events where delegate is not informed
- (void)deselectEventWithDelegate:(BOOL)tellDelegate
{
    if (self.selectedEventDate)
    {
        MGCEventView *cell = [self cellForEventAtIndex:self.selectedEventIndex date:self.selectedEventDate];
        cell.selected = NO;
        
        if (tellDelegate && [self.delegate respondsToSelector:@selector(monthPlannerView:didDeselectEventAtIndex:date:)]) {
            [self.delegate monthPlannerView:self didDeselectEventAtIndex:self.selectedEventIndex date:self.selectedEventDate];
        }
        
        self.selectedEventDate = nil;
    }
}

// public
- (void)deselectEvent
{
    if (self.allowsSelection) {
        [self deselectEventWithDelegate:NO];
    }
}

// public
- (void)selectEventCellAtIndex:(NSUInteger)index date:(NSDate*)date
{
    [self deselectEventWithDelegate:NO];
    
    if (self.allowsSelection) {
        MGCEventView *cell = [self cellForEventAtIndex:index date:date];
        cell.selected = YES;
        
        self.selectedEventDate = date;
        self.selectedEventIndex = index;
    }
}

#pragma mark - Scrolling

// public - deprecated
-(void)scrollToDate:(NSDate*)date animated:(BOOL)animated
{
    [self scrollToDate:date alignment:MGCMonthPlannerScrollAlignmentHeaderTop animated:animated];
}

// public
- (void)scrollToDate:(NSDate*)date alignment:(MGCMonthPlannerScrollAlignment)position animated:(BOOL)animated {
    NSAssert(date, @"scrollToDate:date: was passed nil date");
    
    // check if date in range
    if (self.dateRange && ![self.dateRange containsDate:date])
        [NSException raise:@"Invalid parameter" format:@"date %@ is not in range %@ for this month planner view", date, self.dateRange];

    CGFloat yOffset = [self yOffsetForMonth:date];
    
    if (position == MGCMonthPlannerScrollAlignmentHeaderBottom) {
        yOffset += self.monthInsets.top;
    }
    else if (position == MGCMonthPlannerScrollAlignmentWeekRow) {
        NSUInteger weekNum = [self.calendar mgc_indexOfWeekInMonthForDate:date];
        yOffset += self.monthInsets.top + (weekNum - 1) * self.rowHeight;
    }
    
    [self.eventsView setContentOffset:CGPointMake(0, yOffset) animated:animated];

    if ([self.delegate respondsToSelector:@selector(monthPlannerViewDidScroll:)]) {
        [self.delegate monthPlannerViewDidScroll:self];
    }
}

// adjusts startDate so that month at given date is centered.
// returns the distance in months between old and new start date
- (NSInteger)adjustStartDateForCenteredMonth:(NSDate*)date
{
    CGFloat contentHeight = self.eventsView.contentSize.height;
    CGFloat boundsHeight = CGRectGetHeight(self.eventsView.bounds);
    
    NSUInteger offset = floorf((contentHeight - boundsHeight) / self.monthMaximumHeight) / 2;
    
    NSDate *start = [self.calendar dateByAddingUnit:NSCalendarUnitMonth value:-offset toDate:date options:0];
    if ([start compare:self.dateRange.start] == NSOrderedAscending) {
        start = self.dateRange.start;
    }
    else if ([start compare:self.maxStartDate] == NSOrderedDescending) {
        start = self.maxStartDate;
    }
    
    NSInteger diff = [self.calendar components:NSCalendarUnitMonth fromDate:self.startDate toDate:start options:0].month;
    
    self.startDate = start;
    return diff;
}

// returns YES if the collection view was reloaded
- (BOOL)recenterIfNeeded
{
    CGFloat yOffset = self.eventsView.contentOffset.y;
    CGFloat contentHeight = self.eventsView.contentSize.height;

    if (yOffset < self.monthMaximumHeight || CGRectGetMaxY(self.eventsView.bounds) + self.monthMaximumHeight > contentHeight) {
        
        NSDate *oldStart = [self.startDate copy];
        
        NSDate *centerMonth = [self monthFromOffset:yOffset];
        NSInteger monthOffset = [self adjustStartDateForCenteredMonth:centerMonth];
    
        if (monthOffset != 0) {
            CGFloat y = [self yOffsetForMonth:oldStart];
            [self.eventsView reloadData];
        
            CGPoint offset = self.eventsView.contentOffset;
            offset.y = y + yOffset;
            self.eventsView.contentOffset = offset;
            
            //NSLog(@"recentered - startdate offset by %d months", monthOffset);
            return YES;
        }
    }
    return NO;
}

#pragma mark - Subviews

- (UICollectionView*)eventsView
{
    if (!_eventsView) {
        MGCMonthPlannerViewLayout *layout = [MGCMonthPlannerViewLayout new];
        layout.rowHeight = self.rowHeight;
        layout.dayHeaderHeight = self.dayCellHeaderHeight;
        layout.monthInsets = self.monthInsets;
        layout.alignMonthHeaders = !(self.gridStyle & MGCMonthPlannerGridStyleFill);
        layout.showEvents = (self.style == MGCMonthPlannerStyleEvents);
        layout.delegate = self;
        
        _eventsView = [[UICollectionView alloc]initWithFrame:CGRectZero collectionViewLayout:layout];
        _eventsView.backgroundColor = self.calendarBackgroundColor;
        _eventsView.dataSource = self;
        _eventsView.delegate = self;
        _eventsView.showsVerticalScrollIndicator = NO;
        _eventsView.scrollsToTop = NO;
        
        [_eventsView registerClass:MGCMonthPlannerViewDayCell.class forCellWithReuseIdentifier:DayCellIdentifier];
        [_eventsView registerClass:MGCMonthPlannerBackgroundView.class forSupplementaryViewOfKind:MonthBackgroundViewKind withReuseIdentifier:MonthBackgroundViewIdentifier];
        [_eventsView registerClass:MGCMonthPlannerWeekView.class forSupplementaryViewOfKind:MonthRowViewKind withReuseIdentifier:MonthRowViewIdentifier];
        [_eventsView registerClass:MGCMonthPlannerHeaderView.class forSupplementaryViewOfKind:MonthHeaderViewKind withReuseIdentifier:MonthHeaderViewIdentifier];
        
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
    }
    return _headerBorderLayer;
}

- (void)setupDayLabels
{
    const CGFloat kHeaderHMargin = 6, kHeaderVMargin = 1;
    
    CGFloat width = fmaxf([self.layout columnWidth:0] - 2*kHeaderHMargin, 0);
    CGFloat height = fmaxf(self.headerHeight - 2*kHeaderVMargin, 0);
    CGSize labelSize = CGSizeMake(width, height);
        
    NSDateFormatter *formatter = [NSDateFormatter new];
    formatter.calendar = self.calendar;
    
    NSArray *days = self.weekDaysStringArray;
    if (!days) {
        days = formatter.shortStandaloneWeekdaySymbols;
    }
    
    UIFont *font = [UIFont systemFontOfSize:[UIFont labelFontSize]];
    CGFloat maxFontSize = [self maxSizeForFont:font toFitStrings:days inSize:labelSize];
        
    if (maxFontSize / font.pointSize < .8) {
        days = formatter.veryShortStandaloneWeekdaySymbols;
        maxFontSize = [self maxSizeForFont:font toFitStrings:days inSize:labelSize];
    }
    
    font = [font fontWithSize:maxFontSize];
    
    for (int i = 0; i < 7; i++) {
        // days array is zero-based, sunday first :
        // translate to get firstWeekday at position 0
        int weekday = (i + self.calendar.firstWeekday - 1 + days.count) % (int)days.count;
        
        UILabel *label = self.dayLabels[i];
        label.textAlignment = NSTextAlignmentCenter;
        label.text = [days objectAtIndex:weekday];
        if (self.weekdaysLabelFont) {
            label.font = self.weekdaysLabelFont;
            label.adjustsFontSizeToFitWidth = YES;
        } else {
            label.font = font;
        }
        label.textColor = self.weekdaysLabelTextColor;
        label.hidden = (self.headerHeight == 0);
    }
}

#pragma mark - UIView

- (void)layoutSubviews
{
    //NSLog(@"layout subviews");
    
    [super layoutSubviews];
    
    [self setupDayLabels];
    
    // the order in which subviews are added is important here -
    // see UIViewController automaticallyAdjustsScrollViewInsets property:
    // if the first subview of the controller's view is a scrollview,
    // its insets may be adjusted to account for screen areas consumed by navigation bar...
    
    CGFloat xPos = self.layout.monthInsets.left;
    CGFloat colWidth = (self.bounds.size.width - (self.monthInsets.left + self.monthInsets.right)) / 7.;
    
    for (int i = 0; i < 7; i++) {
        UILabel *label = [self.dayLabels objectAtIndex:i];
        
        label.frame = CGRectMake(xPos, 0, colWidth, self.headerHeight);
        if (!label.superview) {
            [self addSubview:label];
        }
        
        xPos += colWidth;
    }
 
    self.eventsView.frame = CGRectMake(0, self.headerHeight, self.bounds.size.width, self.bounds.size.height - self.headerHeight);
    if (!self.eventsView.superview) {
        [self addSubview:self.eventsView];
    }
    
    self.headerBorderLayer.frame = CGRectMake(0, self.headerHeight, self.bounds.size.width, 1);
    if (!self.headerBorderLayer.superlayer) {
        [self.layer addSublayer:_headerBorderLayer];
    }

    // we have to reload everything at this point - layout invalidation is not enough -
    // because date formats for headers might change depending on available size
    [self.eventsView reloadData];
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


- (MGCEventsRowView*)eventsRowViewAtDate:(NSDate*)rowStart
{
    MGCEventsRowView *eventsView = [self.eventRows objectForKey:rowStart];
    
    if (!eventsView) {
        eventsView = (MGCEventsRowView*)[self.reuseQueue dequeueReusableObjectWithReuseIdentifier:EventsRowViewIdentifier];
        
        NSDate *referenceDate = [self.calendar mgc_startOfMonthForDate:rowStart];
        NSUInteger first = [self.calendar components:NSCalendarUnitDay fromDate:referenceDate toDate:rowStart options:0].day;
        NSUInteger numDays = [self.calendar rangeOfUnit:NSCalendarUnitDay inUnit:NSCalendarUnitWeekOfMonth forDate:rowStart].length;
        
        eventsView.referenceDate = referenceDate;
        eventsView.scrollEnabled = NO;
        eventsView.itemHeight = self.itemHeight;
        eventsView.delegate = self;
        eventsView.daysRange =  NSMakeRange(first, numDays);
        
        [eventsView reload];
    }
    
    [self cacheRow:eventsView forDate:rowStart];
    
    return eventsView;
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
   
    MGCEventsRowView *eventsView = [self eventsRowViewAtDate:rowStart];
    rowView.eventsView = eventsView;
    
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
        if (!self.canMoveEvents) return NO;
        
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
		self.dragEventTouchDayOffset = [self.calendar components:NSCalendarUnitDay fromDate:touchDate toDate:eventDayStart options:0].day;
		
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
        if (!self.canCreateEvents) return NO;
        
        self.isInteractiveCellForNewEvent = YES;
		// create a new cell
		if ([self.dataSource respondsToSelector:@selector(monthPlannerView:cellForNewEventAtDate:)])
		{
			self.interactiveCell = [self.dataSource monthPlannerView:self cellForNewEventAtDate:date];
            NSAssert(self.interactiveCell, @"monthPlannerView:cellForNewEventAtDate: can't return nil");
		}
        else {
            MGCStandardEventView *cell= [[MGCStandardEventView alloc]initWithFrame:CGRectZero];
            cell.title = NSLocalizedString(@"New Event", nil);
            self.interactiveCell = cell;
        }
        self.interactiveCell.frame = CGRectMake(0, 0, [self.layout columnWidth:0], self.itemHeight);
        self.interactiveCelltouchPoint = CGPointMake([self.layout columnWidth:0]/2., self.itemHeight/2.);
        self.interactiveCell.center = [self convertPoint:pt toView:self.eventsView];
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
			comps.day = [[self daysRangeFromDateRange:self.dragEventDateRange]components:NSCalendarUnitDay forCalendar:self.calendar].day;
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
    if (self.style != MGCMonthPlannerStyleEvents)
        return;
    
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
    cell.headerHeight = self.dayCellHeaderHeight;
    
    NSDate *date = [self dateForDayAtIndexPath:indexPath];
    
    NSAttributedString *attrStr = nil;
    if ([self.delegate respondsToSelector:@selector(monthPlannerView:attributedStringForDayHeaderAtDate:)]) {
        attrStr = [self.delegate monthPlannerView:self attributedStringForDayHeaderAtDate:date];
    }
    
    if (!attrStr) {
        NSString *str = [self.dateFormatter stringFromDate:date];
        
        NSMutableParagraphStyle *para = [NSMutableParagraphStyle new];
        para.alignment = NSTextAlignmentCenter;
        
        UIColor *textColor = [self.calendar mgc_isDate:date sameDayAsDate:[NSDate date]] ? [UIColor redColor] : [UIColor blackColor];
        
        attrStr = [[NSAttributedString alloc]initWithString:str attributes:@{ NSParagraphStyleAttributeName: para, NSForegroundColorAttributeName: textColor }];
    }
    
    cell.dayLabel.attributedText = attrStr;
    cell.backgroundColor = [self.calendar isDateInWeekend:date] ? self.weekendDayBackgroundColor : self.weekDayBackgroundColor;
    
    if (self.style & MGCMonthPlannerStyleDots) {
        NSUInteger eventsCounts = [self.dataSource monthPlannerView:self numberOfEventsAtDate:date];
        cell.showsDot = eventsCounts > 0;
        cell.dotColor = self.eventsDotColor;
    }
    return cell;
}


- (MGCMonthPlannerHeaderView*)headerViewForMonthAtIndexPath:(NSIndexPath*)indexPath
{
    MGCMonthPlannerHeaderView *view = [self.eventsView dequeueReusableSupplementaryViewOfKind:MonthHeaderViewKind withReuseIdentifier:MonthHeaderViewIdentifier forIndexPath:indexPath];
    view.label.hidden = self.monthHeaderStyle & MGCMonthHeaderStyleHidden;
    
    if (self.monthHeaderStyle & MGCMonthHeaderStyleHidden) return view;
 
    NSLocale *locale = [NSLocale currentLocale];
    
    static NSDateFormatter *dateFormatter = nil;
    if (dateFormatter == nil) {
        dateFormatter = [NSDateFormatter new];
    }
    dateFormatter.calendar = self.calendar;

    NSString *fmtTemplate = self.monthHeaderStyle & MGCMonthHeaderStyleShort ? @"MMMM" : @"MMMMYYYY";
    dateFormatter.dateFormat = [NSDateFormatter dateFormatFromTemplate:fmtTemplate options:0 locale:locale];

    NSDate *date = [self dateStartingMonthAtIndex:indexPath.section];
    NSString *str = [[dateFormatter stringFromDate:date]uppercaseStringWithLocale:locale];
    
    UIFont *font = self.monthLabelFont;
    NSMutableAttributedString *attrStr = [[NSMutableAttributedString alloc]initWithString:str attributes:@{ NSFontAttributeName: font, NSForegroundColorAttributeName: self.monthLabelTextColor }];
    
    CGRect strRect = [attrStr boundingRectWithSize:CGSizeMake(CGFLOAT_MAX, CGFLOAT_MAX) options:0 context:NULL];
    
    UICollectionViewLayoutAttributes *attribs = [self.layout layoutAttributesForSupplementaryViewOfKind:MonthHeaderViewKind atIndexPath:indexPath];
    
    if (strRect.size.width > attribs.frame.size.width) {
        fmtTemplate = self.monthHeaderStyle & MGCMonthHeaderStyleShort ? @"MMM" : @"MMMYY";
        dateFormatter.dateFormat = [NSDateFormatter dateFormatFromTemplate:fmtTemplate options:0 locale:locale];
        
        str = [[dateFormatter stringFromDate:date]uppercaseStringWithLocale:locale];
        attrStr = [[NSMutableAttributedString alloc]initWithString:str attributes:@{ NSFontAttributeName: font, NSForegroundColorAttributeName: self.monthLabelTextColor }];
    }
    
    if (self.gridStyle & MGCMonthPlannerGridStyleFill) {
        NSMutableParagraphStyle *para = [NSMutableParagraphStyle new];
        para.alignment = NSTextAlignmentCenter;
        
        [attrStr addAttribute:NSParagraphStyleAttributeName value:para range:NSMakeRange(0, str.length)];
    }
    
    view.label.attributedText = attrStr;
    return view;
}

- (MGCMonthPlannerBackgroundView*)backgroundViewForMonthAtIndexPath:(NSIndexPath*)indexPath
{
    NSDate *date = [self dateStartingMonthAtIndex:indexPath.section];
    
    NSUInteger firstColumn = [self columnForDayAtIndexPath:[NSIndexPath indexPathForItem:0 inSection:indexPath.section]];
    NSUInteger lastColumn = [self columnForDayAtIndexPath:[NSIndexPath indexPathForItem:0 inSection:indexPath.section + 1]] ?: 7;
    NSUInteger numRows = [self.calendar rangeOfUnit:NSCalendarUnitWeekOfMonth inUnit:NSCalendarUnitMonth forDate:date].length;
    
    MGCMonthPlannerBackgroundView *view = [self.eventsView dequeueReusableSupplementaryViewOfKind:MonthBackgroundViewKind withReuseIdentifier:MonthBackgroundViewIdentifier forIndexPath:indexPath];
    view.numberOfColumns = 7;
    view.numberOfRows = numRows;
    view.firstColumn = self.gridStyle & MGCMonthPlannerGridStyleFill ? 0 : firstColumn;
    view.lastColumn =  self.gridStyle & MGCMonthPlannerGridStyleFill ? 7 : lastColumn;
    view.drawVerticalLines = self.gridStyle & MGCMonthPlannerGridStyleVerticalLines;
    view.drawHorizontalLines = self.gridStyle & MGCMonthPlannerGridStyleHorizontalLines;
    view.drawBottomDayLabelLines = self.gridStyle & MGCMonthPlannerGridStyleBottomDayLabel;
    view.dayCellHeaderHeight = self.dayCellHeaderHeight;

    [view setNeedsDisplay];
    
    return view;
}

- (UICollectionReusableView*)collectionView:(UICollectionView*)collectionView viewForSupplementaryElementOfKind:(NSString*)kind atIndexPath:(NSIndexPath*)indexPath
{
	if ([kind isEqualToString:MonthBackgroundViewKind])
	{
        return [self backgroundViewForMonthAtIndexPath:indexPath];
	}
    else if ([kind isEqualToString:MonthHeaderViewKind]) {
        return [self headerViewForMonthAtIndexPath:indexPath];
    }
	else if ([kind isEqualToString:MonthRowViewKind]) {
		return [self monthRowViewAtIndexPath:indexPath];
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
	if ([dateRange.end timeIntervalSinceDate:[self.calendar mgc_startOfDayForDate:dateRange.end]] >= 0) {
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
    if (!self.allowsSelection) return NO;
    
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
    [self deselectEventWithDelegate:YES];
    
    NSDateComponents *comps = [NSDateComponents new];
    comps.day = indexPath.section;
    NSDate *date = [self.calendar dateByAddingComponents:comps toDate:view.referenceDate options:0];
    
    self.selectedEventDate = date;
    self.selectedEventIndex = indexPath.item;
    
    if ([self.delegate respondsToSelector:@selector(monthPlannerView:didSelectEventAtIndex:date:)]) {
        [self.delegate monthPlannerView:self didSelectEventAtIndex:indexPath.item date:date];
    }
}

- (BOOL)eventsRowView:(MGCEventsRowView *)view shouldDeselectCellAtIndexPath:(NSIndexPath *)indexPath
{
    if (!self.allowsSelection) return NO;
    
    if ([self.delegate respondsToSelector:@selector(monthPlannerView:shouldDeselectEventAtIndex:date:)]) {
        NSDateComponents *comps = [NSDateComponents new];
        comps.day = indexPath.section;
        NSDate *date = [self.calendar dateByAddingComponents:comps toDate:view.referenceDate options:0];
        
        return [self.delegate monthPlannerView:self shouldDeselectEventAtIndex:indexPath.item date:date];
    }
    return YES;
}

- (void)eventsRowView:(MGCEventsRowView *)view didDeselectCellAtIndexPath:(NSIndexPath *)indexPath
{
    NSDateComponents *comps = [NSDateComponents new];
    comps.day = indexPath.section;
    NSDate *date = [self.calendar dateByAddingComponents:comps toDate:view.referenceDate options:0];

    if ([self.selectedEventDate isEqualToDate:date] && indexPath.item == self.selectedEventIndex) {
        self.selectedEventDate = nil;
        self.selectedEventIndex = 0;
    }
    
    if ([self.delegate respondsToSelector:@selector(monthPlannerView:didDeselectEventAtIndex:date:)]) {
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

- (void)scrollViewDidScroll:(UIScrollView*)scrollview
{
    [self recenterIfNeeded];
    
    if ([self.delegate respondsToSelector:@selector(monthPlannerViewDidScroll:)]) {
        [self.delegate monthPlannerViewDidScroll:self];
    }
}

- (void)scrollViewWillEndDragging:(UIScrollView*)scrollView withVelocity:(CGPoint)velocity targetContentOffset:(inout CGPoint*)targetContentOffset
{
    if (self.pagingMode == MGCMonthPlannerPagingModeNone) return;
    
    const CGFloat kFlickVelocity = .5;
    
    CGFloat yOffsetMin = self.pagingMode == MGCMonthPlannerPagingModeHeaderTop ? 0 : self.monthInsets.top;
    CGFloat yOffsetMax = 0;
    
    NSDate *monthStart = [self.startDate copy];
    for (int i = 0; i < self.numberOfLoadedMonths; i++) {
        CGFloat offset = yOffsetMin + [self heightForMonthAtDate:monthStart];
        if (offset > scrollView.contentOffset.y) {
            yOffsetMax = offset;
            break;
        }
        yOffsetMin = offset;
        
        monthStart = [self.calendar dateByAddingUnit:NSCalendarUnitMonth value:1 toDate:monthStart options:0];
    }
    
    // we need to had a few checks to avoid flickering when swiping fast on a small distance
    // see http://stackoverflow.com/a/14291208/740949
    CGFloat deltaY = targetContentOffset->y - scrollView.contentOffset.y;
    BOOL mightFlicker = (velocity.y > 0.0 && deltaY > 0.0) || (velocity.y < 0.0 && deltaY < 0.0);
    
    if (fabs(velocity.y) < kFlickVelocity && !mightFlicker) {
        // stick to nearest section
        if (scrollView.contentOffset.y - yOffsetMin < yOffsetMax - scrollView.contentOffset.y) {
            targetContentOffset->y = yOffsetMin;
        } else {
            targetContentOffset->y = yOffsetMax;
        }
    }
    else {
        // scroll to next page
        if (velocity.y > 0) {
            targetContentOffset->y = yOffsetMax;
        } else {
            targetContentOffset->y = yOffsetMin;
        }
    }
}

#pragma mark - Customization

- (void)setCalendarBackgroundColor:(UIColor *)calendarBackgroundColor {
    _calendarBackgroundColor = calendarBackgroundColor;
    self.eventsView.backgroundColor = calendarBackgroundColor;
}

@end
