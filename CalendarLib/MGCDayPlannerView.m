//
//  MGCDayPlannerView.m
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

#import "MGCDayPlannerView.h"
#import "NSCalendar+MGCAdditions.h"
#import "MGCDateRange.h"
#import "MGCReusableObjectQueue.h"
#import "MGCTimedEventsViewLayout.h"
#import "MGCAllDayEventsViewLayout.h"
#import "MGCDayColumnCell.h"
#import "MGCEventCell.h"
#import "MGCEventView.h"
#import "MGCStandardEventView.h"
#import "MGCInteractiveEventView.h"
#import "MGCTimeRowsView.h"
#import "MGCAlignedGeometry.h"
#import "OSCache.h"


// used to restrict scrolling to one direction / axis
typedef enum: NSUInteger
{
	ScrollDirectionUnknown = 0,
	ScrollDirectionLeft = 1 << 0,
	ScrollDirectionUp = 1 << 1,
	ScrollDirectionRight = 1 << 2,
	ScrollDirectionDown = 1 << 3,
	ScrollDirectionHorizontal = (ScrollDirectionLeft | ScrollDirectionRight),
	ScrollDirectionVertical = (ScrollDirectionUp | ScrollDirectionDown)
} ScrollDirection;


// collection views cell identifiers
static NSString* const EventCellReuseIdentifier = @"EventCellReuseIdentifier";
static NSString* const DimmingViewReuseIdentifier = @"DimmingViewReuseIdentifier";
static NSString* const DayColumnCellReuseIdentifier = @"DayColumnCellReuseIdentifier";
static NSString* const TimeRowCellReuseIdentifier = @"TimeRowCellReuseIdentifier";
static NSString* const MoreEventsViewReuseIdentifier = @"MoreEventsViewReuseIdentifier";   // test


// we only load in the collection views (2 * kDaysLoadingStep + 1) pages of (numberOfVisibleDays) days each at a time.
// this value can be tweaked for performance or smoother scrolling (between 2 and 4 seems reasonable)
static const NSUInteger kDaysLoadingStep = 2;

// minimum and maximum height of a one-hour time slot
static const CGFloat kMinHourSlotHeight = 20.;
static const CGFloat kMaxHourSlotHeight = 150.;


@interface MGCDayColumnViewFlowLayout : UICollectionViewFlowLayout
@end

@implementation MGCDayColumnViewFlowLayout

- (UICollectionViewLayoutInvalidationContext *)invalidationContextForBoundsChange:(CGRect)newBounds {
    
    UICollectionViewFlowLayoutInvalidationContext *context = (UICollectionViewFlowLayoutInvalidationContext *)[super invalidationContextForBoundsChange:newBounds];
    CGRect oldBounds = self.collectionView.bounds;
    context.invalidateFlowLayoutDelegateMetrics = !CGSizeEqualToSize(newBounds.size, oldBounds.size);
    return context;
}

// we keep this for iOS 8 compatibility. As of iOS 9, this is replaced by collectionView:targetContentOffsetForProposedContentOffset:
- (CGPoint)targetContentOffsetForProposedContentOffset:(CGPoint)proposedContentOffset
{
    id<UICollectionViewDelegate> delegate = (id<UICollectionViewDelegate>)self.collectionView.delegate;
    return [delegate collectionView:self.collectionView targetContentOffsetForProposedContentOffset:proposedContentOffset];
}


@end


@interface MGCDayPlannerView () <UICollectionViewDataSource, MGCTimedEventsViewLayoutDelegate, MGCAllDayEventsViewLayoutDelegate, UICollectionViewDelegateFlowLayout, MGCTimeRowsViewDelegate>

// subviews
@property (nonatomic, readonly) UICollectionView *timedEventsView;
@property (nonatomic, readonly) UICollectionView *allDayEventsView;
@property (nonatomic, readonly) UIView *allDayEventsBackgroundView;
@property (nonatomic, readonly) UICollectionView *dayColumnsView;
@property (nonatomic, readonly) UIScrollView *timeScrollView;
@property (nonatomic, readonly) MGCTimeRowsView *timeRowsView;

// collection view layouts
@property (nonatomic, readonly) MGCTimedEventsViewLayout *timedEventsViewLayout;
@property (nonatomic, readonly) MGCAllDayEventsViewLayout *allDayEventsViewLayout;

@property (nonatomic) MGCReusableObjectQueue *reuseQueue;		// reuse queue for event views (MGCEventView)

@property (nonatomic, copy) NSDate *startDate;					// first currently loaded day in the collection views (might not be visible)
@property (nonatomic, readonly) NSDate *maxStartDate;			// maximum date for the start of a loaded page of the collection view - set with dateRange, nil for infinite scrolling
@property (nonatomic, readonly) NSUInteger numberOfLoadedDays;	// number of days loaded at once in the collection views
@property (nonatomic, readonly) MGCDateRange* loadedDaysRange;	// date range of all days currently loaded in the collection views
@property (nonatomic) MGCDateRange* previousVisibleDays;		// used by updateVisibleDaysRange to inform delegate about appearing / disappearing days

@property (nonatomic) NSMutableOrderedSet *loadingDays;			// set of dates with running activity indicator

@property (nonatomic, readonly) NSDate *firstVisibleDate;		// first fully visible day (!= visibleDays.start)

@property (nonatomic) CGFloat allDayEventCellHeight;			// height of an event cell in the all-day event view
@property (nonatomic) CGFloat eventsViewInnerMargin;			// distance between top and first time line and between last line and bottom

@property (nonatomic) UIScrollView *controllingScrollView;		// the collection view which initiated scrolling - used for proper synchronization between the different collection views
@property (nonatomic) CGPoint scrollStartOffset;				// content offset in the controllingScrollView where scrolling started - used to lock scrolling in one direction
@property (nonatomic) ScrollDirection scrollDirection;			// direction or axis of the scroll movement
@property (nonatomic) NSDate *scrollTargetDate;                 // target date after scrolling (initiated programmatically or following pan or swipe gesture)

@property (nonatomic) MGCInteractiveEventView *interactiveCell;	// view used when dragging event around
@property (nonatomic) CGPoint interactiveCellTouchPoint;		// point where touch occured in interactiveCell coordinates
@property (nonatomic) MGCEventType interactiveCellType;			// current type of interactive cell
@property (nonatomic, copy) NSDate *interactiveCellDate;		// current date of interactice cell
@property (nonatomic) CGFloat interactiveCellTimedEventHeight;	// height of the dragged event
@property (nonatomic) BOOL isInteractiveCellForNewEvent;		// is the interactive cell for new event or existing one

@property (nonatomic) MGCEventType movingEventType;				// origin type of the event being moved
@property (nonatomic) NSUInteger movingEventIndex;				// origin index of the event being moved
@property (nonatomic, copy) NSDate *movingEventDate;			// origin date of the event being moved
@property (nonatomic) BOOL acceptsTarget;						// are the current date and type accepted for new event or existing one

@property (nonatomic, assign) NSTimer *dragTimer;				// timer used when scrolling while dragging

@property (nonatomic, copy) NSIndexPath *selectedCellIndexPath; // index path of the currently selected event cell
@property (nonatomic) MGCEventType selectedCellType;			// type of the currently selected event

@property (nonatomic) CGFloat hourSlotHeightForGesture;
@property (copy, nonatomic) dispatch_block_t scrollViewAnimationCompletionBlock;

@property (nonatomic) OSCache *dimmedTimeRangesCache;          // cache for dimmed time ranges (indexed by date)

@end


@implementation MGCDayPlannerView

// readonly properties whose getter's defined are not auto-synthesized
@synthesize timedEventsView = _timedEventsView;
@synthesize allDayEventsView = _allDayEventsView;
@synthesize dayColumnsView = _dayColumnsView;
//@synthesize backgroundView = _backgroundView;
@synthesize timeScrollView = _timeScrollView;
@synthesize allDayEventsBackgroundView = _allDayEventsBackgroundView;
@synthesize timedEventsViewLayout = _timedEventsViewLayout;
@synthesize allDayEventsViewLayout = _allDayEventsViewLayout;
@synthesize startDate = _startDate;

#pragma mark - Initialization

- (void)setup
{
	_numberOfVisibleDays = 7;
	_hourSlotHeight = 65.;
	_hourRange = NSMakeRange(0, 24);
	_timeColumnWidth = 60.;
	_dayHeaderHeight = 40.;
    _daySeparatorsColor = [UIColor lightGrayColor];
    _timeSeparatorsColor = [UIColor lightGrayColor];
    _currentTimeColor = [UIColor redColor];
    _eventIndicatorDotColor = [UIColor blueColor];
	_showsAllDayEvents = YES;
    _eventsViewInnerMargin = 15.;
	_allDayEventCellHeight = 20;
    _dimmingColor = [UIColor colorWithWhite:.9 alpha:.5];
	_pagingEnabled = YES;
	_zoomingEnabled = YES;
	_canCreateEvents = YES;
	_canMoveEvents = YES;
	_allowsSelection = YES;
    _eventCoveringType = TimedEventCoveringTypeClassic;
	
	_reuseQueue = [[MGCReusableObjectQueue alloc] init];
	_loadingDays = [NSMutableOrderedSet orderedSetWithCapacity:14];
	
    _dimmedTimeRangesCache = [[OSCache alloc]init];
    _dimmedTimeRangesCache.countLimit = 200;
    
    _durationForNewTimedEvent = 60 * 60;
    
	self.backgroundColor = [UIColor whiteColor];
	self.autoresizesSubviews = NO;
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationDidReceiveMemoryWarning:) name:UIApplicationDidReceiveMemoryWarningNotification object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationWillChangeStatusBarOrientation:) name:UIApplicationWillChangeStatusBarOrientationNotification object:nil];
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
	[self reloadAllEvents];
}

- (void)applicationWillChangeStatusBarOrientation:(NSNotification*)notification
{
    [self endInteraction];
    
    // cancel eventual pan gestures
    self.timedEventsView.panGestureRecognizer.enabled = NO;
    self.timedEventsView.panGestureRecognizer.enabled = YES;
    
    self.allDayEventsView.panGestureRecognizer.enabled = NO;
    self.allDayEventsView.panGestureRecognizer.enabled = YES;
}

#pragma mark - Layout

// public
- (void)setNumberOfVisibleDays:(NSUInteger)numberOfVisibleDays
{
	NSAssert(numberOfVisibleDays > 0, @"numberOfVisibleDays in day planner view cannot be set to 0");
	
	if (_numberOfVisibleDays != numberOfVisibleDays) {
		NSDate* date = self.visibleDays.start;
        
        _numberOfVisibleDays = numberOfVisibleDays;
        
        if (self.dateRange && [self.dateRange components:NSCalendarUnitDay forCalendar:self.calendar].day < numberOfVisibleDays)
            return;
        
        [self reloadCollectionViews];
        [self scrollToDate:date options:MGCDayPlannerScrollDate animated:NO];
	}
}

// public
- (void)setHourSlotHeight:(CGFloat)hourSlotHeight
{
    CGFloat yCenterOffset = self.timeScrollView.contentOffset.y + self.timeScrollView.bounds.size.height / 2.;
    NSTimeInterval ti = [self timeFromOffset:yCenterOffset rounding:0];
   
    _hourSlotHeight = fminf(fmaxf(MGCAlignedFloat(hourSlotHeight), kMinHourSlotHeight), kMaxHourSlotHeight);
    
    [self.dayColumnsView.collectionViewLayout invalidateLayout];
    
    self.timedEventsViewLayout.dayColumnSize = self.dayColumnSize;
    [self.timedEventsViewLayout invalidateLayout];
    
    self.timeRowsView.hourSlotHeight = _hourSlotHeight;
    self.timeScrollView.contentSize = CGSizeMake(self.bounds.size.width, self.dayColumnSize.height);
    self.timeRowsView.frame = CGRectMake(0, 0, self.timeScrollView.contentSize.width, self.timeScrollView.contentSize.height);
    
    CGFloat yOffset = [self offsetFromTime:ti rounding:0] - self.timeScrollView.bounds.size.height / 2.;
    yOffset = fmaxf(0, fminf(yOffset, self.timeScrollView.contentSize.height - self.timeScrollView.bounds.size.height));

    self.timeScrollView.contentOffset = CGPointMake(0, yOffset);
    self.timedEventsView.contentOffset = CGPointMake(self.timedEventsView.contentOffset.x, yOffset);
}

// public
- (CGSize)dayColumnSize
{
 	CGFloat height = self.hourSlotHeight * self.hourRange.length + 2 * self.eventsViewInnerMargin;
	
	// if the number of days in dateRange is less than numberOfVisibleDays, spread the days over the view
	NSUInteger numberOfDays = MIN(self.numberOfVisibleDays, self.numberOfLoadedDays);
    CGFloat width = (self.bounds.size.width - self.timeColumnWidth) / numberOfDays;
	
	return MGCAlignedSizeMake(width, height);
}

// public
- (void)setShowsAllDayEvents:(BOOL)showsAllDayEvents
{
	if (_showsAllDayEvents != showsAllDayEvents) {
		_showsAllDayEvents = showsAllDayEvents;
	
        [self.allDayEventsView reloadData];
        [self.dayColumnsView reloadData];   // for dots indicating events
        
        [self.dayColumnsView performBatchUpdates:^{} completion:^(BOOL finished){
            [self setupSubviews];
        }];
	}
}

// public
- (NSCalendar*)calendar
{
	if (_calendar == nil) {
		_calendar = [NSCalendar currentCalendar];
	}
	return _calendar;
}

// public
- (void)setDateRange:(MGCDateRange*)dateRange
{
	if (dateRange != _dateRange && ![dateRange isEqual:_dateRange]) {
		NSDate *firstDate = self.visibleDays.start;
		
		_dateRange = nil;
	
		if (dateRange) {
			
			// adjust start and end date of new range on day boundaries
			NSDate *start = [self.calendar mgc_startOfDayForDate:dateRange.start];
			NSDate *end = [self.calendar mgc_startOfDayForDate:dateRange.end];
			_dateRange = [MGCDateRange dateRangeWithStart:start end:end];
			
			// adjust startDate so that it falls inside new range
			if (![_dateRange includesDateRange:self.loadedDaysRange]) {
				self.startDate = _dateRange.start;
			}
			
			if (![_dateRange containsDate:firstDate]) {
				firstDate = [NSDate date];
				if (![_dateRange containsDate:firstDate]) {
					firstDate = _dateRange.start;
				}
			}
		}
		
		[self reloadCollectionViews];
		[self scrollToDate:firstDate options:MGCDayPlannerScrollDate animated:NO];
	}
}

// public
- (MGCDateRange*)visibleDays
{
    CGFloat dayWidth = self.dayColumnSize.width;
	
	NSUInteger first = floorf(self.timedEventsView.contentOffset.x / dayWidth);
	NSDate *firstDay = [self dateFromDayOffset:first];
	if (self.dateRange && [firstDay compare:self.dateRange.start] == NSOrderedAscending)
		firstDay = self.dateRange.start;

	// since the day column width is rounded, there can be a difference of a few points between
	// the right side of the view bounds and the limit of the last column, causing last visible day
	// to be one more than expected. We have to take this in account
	CGFloat diff = self.timedEventsView.bounds.size.width - self.dayColumnSize.width * self.numberOfVisibleDays;

	NSUInteger last = ceilf((CGRectGetMaxX(self.timedEventsView.bounds) - diff) / dayWidth);
	NSDate *lastDay = [self dateFromDayOffset:last];
	if (self.dateRange && [lastDay compare:self.dateRange.end] != NSOrderedAscending)
		lastDay = self.dateRange.end;

	return [MGCDateRange dateRangeWithStart:firstDay end:lastDay];
}

// public
- (NSTimeInterval)firstVisibleTime
{
    NSTimeInterval ti = [self timeFromOffset:self.timedEventsView.contentOffset.y rounding:0];
    return fmax(self.hourRange.location * 3600., ti);
}

// public
- (NSTimeInterval)lastVisibleTime
{
    NSTimeInterval ti = [self timeFromOffset:CGRectGetMaxY(self.timedEventsView.bounds) rounding:0];
    return fmin(NSMaxRange(self.hourRange) * 3600., ti);
}

// public
- (void)setHourRange:(NSRange)hourRange
{
    NSAssert(hourRange.length >= 1 && NSMaxRange(hourRange) <= 24, @"Invalid hour range %@", NSStringFromRange(hourRange));
    
    CGFloat yCenterOffset = self.timeScrollView.contentOffset.y + self.timeScrollView.bounds.size.height / 2.;
    NSTimeInterval ti = [self timeFromOffset:yCenterOffset rounding:0];
    
    _hourRange = hourRange;
    
    [self.dimmedTimeRangesCache removeAllObjects];
    
    self.timedEventsViewLayout.dayColumnSize = self.dayColumnSize;
    [self.timedEventsViewLayout invalidateLayout];

    self.timeRowsView.hourRange = hourRange;
    self.timeScrollView.contentSize = CGSizeMake(self.bounds.size.width, self.dayColumnSize.height);
    self.timeRowsView.frame = CGRectMake(0, 0, self.timeScrollView.contentSize.width, self.timeScrollView.contentSize.height);
    
    CGFloat yOffset = [self offsetFromTime:ti rounding:0] - self.timeScrollView.bounds.size.height / 2.;
    yOffset = fmaxf(0, fminf(yOffset, self.timeScrollView.contentSize.height - self.timeScrollView.bounds.size.height));
    
    self.timeScrollView.contentOffset = CGPointMake(0, yOffset);
    self.timedEventsView.contentOffset = CGPointMake(self.timedEventsView.contentOffset.x, yOffset);
}

// public
- (void)setDateFormat:(NSString*)dateFormat
{
	if (dateFormat != _dateFormat || ![dateFormat isEqualToString:_dateFormat]) {
		_dateFormat = [dateFormat copy];
		[self.dayColumnsView reloadData];
	}
}

// public
- (void)setDaySeparatorsColor:(UIColor *)daySeparatorsColor
{
    _daySeparatorsColor = daySeparatorsColor;
    [self.dayColumnsView reloadData];
}

// public
- (void)setTimeSeparatorsColor:(UIColor *)timeSeparatorsColor
{
    _timeSeparatorsColor = timeSeparatorsColor;
    self.timeRowsView.timeColor = timeSeparatorsColor;
    [self.timeRowsView setNeedsDisplay];
}

// public
- (void)setCurrentTimeColor:(UIColor *)currentTimeColor
{
    _currentTimeColor = currentTimeColor;
    self.timeRowsView.currentTimeColor = currentTimeColor;
    [self.timeRowsView setNeedsDisplay];
}

// public
- (void)setEventIndicatorDotColor:(UIColor *)eventIndicatorDotColor
{
    _eventIndicatorDotColor = eventIndicatorDotColor;
    [self.dayColumnsView reloadData];
}

// public
- (void)setDimmingColor:(UIColor *)dimmingColor
{
    _dimmingColor = dimmingColor;
    for (UIView *v in [self.timedEventsView visibleSupplementaryViewsOfKind:DimmingViewKind]) {
        v.backgroundColor = dimmingColor;
    }
}

// public
- (void)setEventCoveringType:(MGCDayPlannerCoveringType)eventCoveringType {
    _eventCoveringType = eventCoveringType;
    self.timedEventsViewLayout.coveringType = eventCoveringType == MGCDayPlannerCoveringTypeComplex ? TimedEventCoveringTypeComplex : TimedEventCoveringTypeClassic;
    [self.dayColumnsView setNeedsDisplay];
}

#pragma mark - Private properties

// startDate is the first currently loaded day in the collection views - time is set to 00:00
- (NSDate*)startDate
{
	if (_startDate == nil) {
		_startDate = [self.calendar mgc_startOfDayForDate:[NSDate date]];
		
		if (self.dateRange && ![self.dateRange containsDate:_startDate]) {
			_startDate = self.dateRange.start;
		}
	}
	return _startDate;
}

- (void)setStartDate:(NSDate*)startDate
{
	startDate = [self.calendar mgc_startOfDayForDate:startDate];
	
	NSAssert([startDate compare:self.dateRange.start] !=  NSOrderedAscending, @"start date not in the scrollable date range");
	NSAssert([startDate compare:self.maxStartDate] != NSOrderedDescending, @"start date not in the scrollable date range");

	_startDate = startDate;
	
	//NSLog(@"Loaded days range: %@", self.loadedDaysRange);
}

- (NSDate*)maxStartDate
{
	NSDate *date = nil;
	
	if (self.dateRange) {
		NSDateComponents *comps = [NSDateComponents new];
		comps.day = -(2 * kDaysLoadingStep + 1) * self.numberOfVisibleDays;
		date = [self.calendar dateByAddingComponents:comps toDate:self.dateRange.end options:0];
		
		if ([date compare:self.dateRange.start] == NSOrderedAscending) {
			date = self.dateRange.start;
		}
	}
	return date;
}

- (NSUInteger)numberOfLoadedDays
{
	NSUInteger numDays = (2 * kDaysLoadingStep + 1) * self.numberOfVisibleDays;
	if (self.dateRange) {
		NSInteger diff = [self.dateRange components:NSCalendarUnitDay forCalendar:self.calendar].day;
		numDays = MIN(numDays, diff);  // cannot load more than the total number of scrollable days
	}
	return numDays;
}

- (MGCDateRange*)loadedDaysRange
{
	NSDateComponents *comps = [NSDateComponents new];
	comps.day = self.numberOfLoadedDays;
	NSDate *endDate = [self.calendar dateByAddingComponents:comps toDate:self.startDate options:0];
	return [MGCDateRange dateRangeWithStart:self.startDate end:endDate];
}

// first fully visible day (!= visibleDays.start)
- (NSDate*)firstVisibleDate
{
	CGFloat xOffset = self.timedEventsView.contentOffset.x;
	NSUInteger section = ceilf(xOffset / self.dayColumnSize.width);
	return [self dateFromDayOffset:section];
}

#pragma mark - Utilities

// dayOffset is the offset from the first loaded day in the view (ie startDate)
- (CGFloat)xOffsetFromDayOffset:(NSInteger)dayOffset
{
	return (dayOffset * self.dayColumnSize.width);
}

// dayOffset is the offset from the first loaded day in the view (ie startDate)
- (NSDate*)dateFromDayOffset:(NSInteger)dayOffset
{
	NSDateComponents *comp = [NSDateComponents new];
	comp.day = dayOffset;
	return [self.calendar dateByAddingComponents:comp toDate:self.startDate options:0];
}

// returns the day offset from the first loaded day in the view (ie startDate)
- (NSInteger)dayOffsetFromDate:(NSDate*)date
{
	NSAssert(date, @"dayOffsetFromDate: was passed nil date");
	
	NSDateComponents *comps = [self.calendar components:NSCalendarUnitDay fromDate:self.startDate toDate:date options:0];
	return comps.day;
}

// returns the time interval corresponding to a vertical offset in the timedEventsView coordinates,
// rounded according to given parameter (in minutes)
- (NSTimeInterval)timeFromOffset:(CGFloat)yOffset rounding:(NSUInteger)rounding
{
	rounding = MAX(rounding % 60, 1);
    
    CGFloat hour = fmax(0, (yOffset - self.eventsViewInnerMargin) / self.hourSlotHeight) + self.hourRange.location;
   	NSTimeInterval ti = roundf((hour * 3600) / (rounding * 60)) * (rounding * 60);
    
 	return ti;
}

// returns the vertical offset in the timedEventsView coordinates corresponding to given time interval
// previously rounded according to parameter (in minutes)
- (CGFloat)offsetFromTime:(NSTimeInterval)ti rounding:(NSUInteger)rounding
{
	rounding = MAX(rounding % 60, 1);
	ti = roundf(ti / (rounding * 60)) * (rounding * 60);
	CGFloat hour = ti / 3600. - self.hourRange.location;
	return MGCAlignedFloat(hour * self.hourSlotHeight + self.eventsViewInnerMargin);
}

- (CGFloat)offsetFromDate:(NSDate*)date
{
    NSDateComponents *comp = [self.calendar components:(NSCalendarUnitHour|NSCalendarUnitMinute) fromDate:date];
    CGFloat y = roundf((comp.hour + comp.minute / 60. - self.hourRange.location) * self.hourSlotHeight + self.eventsViewInnerMargin);
    // when the following line is commented, event cells and dimming views are not constrained to the visible hour range
    // (ie cells can show past the edge of content)
    //y = fmax(self.eventsViewInnerMargin, fmin(self.dayColumnSize.height - self.eventsViewInnerMargin, y));
    return MGCAlignedFloat(y);
}

// returns the offset for a given event date and type in self coordinates
- (CGPoint)offsetFromDate:(NSDate*)date eventType:(MGCEventType)type
{
    CGFloat x = [self xOffsetFromDayOffset:[self dayOffsetFromDate:date]];
    if(type == MGCAllDayEventType) {
        CGPoint pt = CGPointMake(x, 0);
        return [self convertPoint:pt fromView:self.allDayEventsView];
    }
    else {
        NSTimeInterval ti = [date timeIntervalSinceDate:[self.calendar mgc_startOfDayForDate:date]];
        CGFloat y = [self offsetFromTime:ti rounding:1];
        CGPoint pt = CGPointMake(x, y);
        return [self convertPoint:pt fromView:self.timedEventsView];
    }
}

// returns the scrollable time range for the day at date, depending on hourRange
- (MGCDateRange*)scrollableTimeRangeForDate:(NSDate*)date
{
    NSDate *dayRangeStart = [self.calendar dateBySettingHour:self.hourRange.location minute:0 second:0 ofDate:date options:0];
    NSDate *dayRangeEnd = [self.calendar dateBySettingHour:NSMaxRange(self.hourRange) - 1 minute:59 second:0 ofDate:date options:0];
    return [MGCDateRange dateRangeWithStart:dayRangeStart end:dayRangeEnd];
}

#pragma mark - Locating days and events

// public
- (NSDate*)dateAtPoint:(CGPoint)point rounded:(BOOL)rounded
{
	if (self.dayColumnsView.contentSize.width == 0) return nil;
	
	CGPoint ptDayColumnsView = [self convertPoint:point toView:self.dayColumnsView];
	NSIndexPath *dayPath = [self.dayColumnsView indexPathForItemAtPoint:ptDayColumnsView];
	
	if (dayPath) {
		// get the day/month/year portion of the date
		NSDate *date = [self dateFromDayOffset:dayPath.section];

		// get the time portion
		CGPoint ptTimedEventsView = [self convertPoint:point toView:self.timedEventsView];
		if ([self.timedEventsView pointInside:ptTimedEventsView withEvent:nil]) {
            // max time for is 23:59
			NSTimeInterval ti = fminf([self timeFromOffset:ptTimedEventsView.y rounding:15], 24 * 3600. - 60);
			date = [date dateByAddingTimeInterval:ti];
		}
		return date;
	}
	return nil;
}

// public
- (MGCEventView*)eventViewAtPoint:(CGPoint)point type:(MGCEventType*)type index:(NSUInteger*)index date:(NSDate**)date
{
	CGPoint ptTimedEventsView = [self convertPoint:point toView:self.timedEventsView];
	CGPoint ptAllDayEventsView = [self convertPoint:point toView:self.allDayEventsView];
	
	if ([self.timedEventsView pointInside:ptTimedEventsView withEvent:nil]) {
		NSIndexPath *path = [self.timedEventsView indexPathForItemAtPoint:ptTimedEventsView];
		if (path) {
			MGCEventCell *cell = (MGCEventCell*)[self.timedEventsView cellForItemAtIndexPath:path];
			if (type) *type = MGCTimedEventType;
			if (index) *index = path.item;
			if (date) *date = [self dateFromDayOffset:path.section];
			return cell.eventView;
		}
	}
	else if ([self.allDayEventsView pointInside:ptAllDayEventsView withEvent:nil]) {
		NSIndexPath *path = [self.allDayEventsView indexPathForItemAtPoint:ptAllDayEventsView];
		if (path) {
			MGCEventCell *cell = (MGCEventCell*)[self.allDayEventsView cellForItemAtIndexPath:path];
			if (type) *type = MGCAllDayEventType;
			if (index) *index = path.item;
			if (date) *date = [self dateFromDayOffset:path.section];
			return cell.eventView;
		}
	}
	
	return nil;
}

// public
- (MGCEventView*)eventViewOfType:(MGCEventType)type atIndex:(NSUInteger)index date:(NSDate*)date
{
	NSAssert(date, @"eventViewOfType:atIndex:date: was passed nil date");
	
	NSUInteger section = [self dayOffsetFromDate:date];
	NSIndexPath *indexPath = [NSIndexPath indexPathForItem:index inSection:section];
	
	return [[self collectionViewCellForEventOfType:type atIndexPath:indexPath] eventView];
}

#pragma mark - Navigation

// public
-(void)scrollToDate:(NSDate*)date options:(MGCDayPlannerScrollType)options animated:(BOOL)animated
{
	NSAssert(date, @"scrollToDate:date: was passed nil date");
	
	if (self.dateRange && ![self.dateRange containsDate:date]) {
		[NSException raise:@"Invalid parameter" format:@"date %@ is not in range %@ for this day planner view", date, self.dateRange];
	}
	
	// if scrolling is already happening, let it end properly
	if (self.controllingScrollView) return;
	
	NSDate *firstVisible = date;
	NSDate *maxScrollable = [self maxScrollableDate];
	if (maxScrollable != nil && [firstVisible compare:maxScrollable] == NSOrderedDescending) {
		firstVisible = maxScrollable;
	}
	
	NSDate *dayStart = [self.calendar mgc_startOfDayForDate:firstVisible];
    self.scrollTargetDate = dayStart;
    
	NSTimeInterval ti = [date timeIntervalSinceDate:dayStart];
	
    CGFloat y = [self offsetFromTime:ti rounding:0];
	y = fmaxf(fminf(y, MGCAlignedFloat(self.timedEventsView.contentSize.height - self.timedEventsView.bounds.size.height)), 0);
	CGFloat x = [self xOffsetFromDayOffset:[self dayOffsetFromDate:dayStart]];

	CGPoint offset = self.timedEventsView.contentOffset;

	MGCDayPlannerView * __weak weakSelf = self;
	dispatch_block_t completion = ^{
		weakSelf.userInteractionEnabled = YES;
		if (!animated && [weakSelf.delegate respondsToSelector:@selector(dayPlannerView:didScroll:)]) {
			[weakSelf.delegate dayPlannerView:weakSelf didScroll:options];
		}
	};
	
	if (options == MGCDayPlannerScrollTime) {
		self.userInteractionEnabled = NO;
		offset.y = y;
		[self setTimedEventsViewContentOffset:offset animated:animated completion:completion];
	}
	else if (options == MGCDayPlannerScrollDate) {
		self.userInteractionEnabled = NO;
		offset.x = x;
		[self setTimedEventsViewContentOffset:offset animated:animated completion:completion];
	}
	else if (options == MGCDayPlannerScrollDateTime) {
		self.userInteractionEnabled = NO;
		offset.x = x;
		[self setTimedEventsViewContentOffset:offset animated:animated completion:^(void){
			CGPoint offset = CGPointMake(weakSelf.timedEventsView.contentOffset.x, y);
			[weakSelf setTimedEventsViewContentOffset:offset animated:animated completion:completion];
		}];
	}
}

// public
- (void)pageForwardAnimated:(BOOL)animated date:(NSDate**)date
{
	NSDate *next = [self nextDateForPagingAfterDate:self.visibleDays.start];
	if (date != nil)
		*date = next;
	[self scrollToDate:next options:MGCDayPlannerScrollDate animated:animated];
}

// public
- (void)pageBackwardsAnimated:(BOOL)animated date:(NSDate**)date
{
	NSDate *prev = [self prevDateForPagingBeforeDate:self.firstVisibleDate];
	if (date != nil)
		*date = prev;
	[self scrollToDate:prev options:MGCDayPlannerScrollDate animated:animated];
}

// returns the latest date to be shown on the left side of the view,
// nil if the day planner has no date range.
- (NSDate*)maxScrollableDate
{
    if (self.dateRange != nil) {
        NSUInteger numVisible = MIN(self.numberOfVisibleDays, [self.dateRange components:NSCalendarUnitDay forCalendar:self.calendar].day);
		NSDateComponents *comps = [NSDateComponents new];
		comps.day = -numVisible;
		return [self.calendar dateByAddingComponents:comps toDate:self.dateRange.end options:0];
	}
	return nil;
}

// retuns the earliest date to be shown on the left side of the view,
// nil if the day planner has no date range.
- (NSDate*)minScrollableDate
{
	return self.dateRange != nil ? self.dateRange.start : nil;
}

// if the view shows at least 7 days, returns the next start of a week after date,
// otherwise returns date plus the number of visible days, within the limits of the view day range
- (NSDate*)nextDateForPagingAfterDate:(NSDate*)date
{
	NSAssert(date, @"nextPageForPagingAfterDate: was passed nil date");
	
	NSDate *nextDate;
	if (self.numberOfVisibleDays >= 7) {
		nextDate = [self.calendar mgc_nextStartOfWeekForDate:date];
	}
	else {
		NSDateComponents *comps = [NSDateComponents new];
		comps.day = self.numberOfVisibleDays;
		nextDate = [self.calendar dateByAddingComponents:comps toDate:date options:0];
	}
	
	NSDate *maxScrollable = [self maxScrollableDate];
	if (maxScrollable != nil && [nextDate compare:maxScrollable] == NSOrderedDescending) {
		nextDate = maxScrollable;
	}
	return nextDate;
}

// If the view shows at least 7 days, returns the previous start of a week before date,
// otherwise returns date minus the number of visible days, within the limits of the view day range
- (NSDate*)prevDateForPagingBeforeDate:(NSDate*)date
{
	NSAssert(date, @"prevDateForPagingBeforeDate: was passed nil date");
	
	NSDate *prevDate;
	if (self.numberOfVisibleDays >= 7) {
		prevDate = [self.calendar mgc_startOfWeekForDate:date];
		if ([prevDate isEqualToDate:date]) {
			NSDateComponents* comps = [NSDateComponents new];
			comps.day = -7;
			prevDate = [self.calendar dateByAddingComponents:comps toDate:date options:0];
		}
	}
	else {
		NSDateComponents *comps = [NSDateComponents new];
		comps.day = -self.numberOfVisibleDays;
		prevDate = [self.calendar dateByAddingComponents:comps toDate:date options:0];
	}
	
	NSDate *minScrollable = [self minScrollableDate];
	if (minScrollable != nil && [prevDate compare:minScrollable] == NSOrderedAscending) {
		prevDate = minScrollable;
	}
	return prevDate;
	
}

#pragma mark - Subviews

- (UICollectionView*)timedEventsView
{
    if (!_timedEventsView) {
		_timedEventsView = [[UICollectionView alloc] initWithFrame:CGRectZero collectionViewLayout:self.timedEventsViewLayout];
		_timedEventsView.backgroundColor = [UIColor clearColor];
		_timedEventsView.dataSource = self;
		_timedEventsView.delegate = self;
		_timedEventsView.showsVerticalScrollIndicator = NO;
		_timedEventsView.showsHorizontalScrollIndicator = NO;
		_timedEventsView.scrollsToTop = NO;
		_timedEventsView.decelerationRate = UIScrollViewDecelerationRateFast;
		_timedEventsView.allowsSelection = NO;
		_timedEventsView.directionalLockEnabled = YES;
		
		[_timedEventsView registerClass:MGCEventCell.class forCellWithReuseIdentifier:EventCellReuseIdentifier];
        [_timedEventsView registerClass:UICollectionReusableView.class forSupplementaryViewOfKind:DimmingViewKind withReuseIdentifier:DimmingViewReuseIdentifier];
		UILongPressGestureRecognizer *longPress = [UILongPressGestureRecognizer new];
		[longPress addTarget:self action:@selector(handleLongPress:)];
		[_timedEventsView addGestureRecognizer:longPress];
		
		UITapGestureRecognizer *tap = [UITapGestureRecognizer new];
		[tap addTarget:self action:@selector(handleTap:)];
		[_timedEventsView addGestureRecognizer:tap];
		
		UIPinchGestureRecognizer *pinch = [UIPinchGestureRecognizer new];
		[pinch addTarget:self action:@selector(handlePinch:)];
		[_timedEventsView addGestureRecognizer:pinch];
	}
	return _timedEventsView;
}

- (UICollectionView*)allDayEventsView
{
	if (!_allDayEventsView && self.showsAllDayEvents) {
		_allDayEventsView = [[UICollectionView alloc] initWithFrame:CGRectZero collectionViewLayout:self.allDayEventsViewLayout];
		_allDayEventsView.backgroundColor = [UIColor clearColor];
		_allDayEventsView.dataSource = self;
		_allDayEventsView.delegate = self;
		_allDayEventsView.showsVerticalScrollIndicator = YES;
		_allDayEventsView.showsHorizontalScrollIndicator = NO;
		_allDayEventsView.decelerationRate = UIScrollViewDecelerationRateFast;
		_allDayEventsView.allowsSelection = NO;
		_allDayEventsView.directionalLockEnabled = YES;
		
		[_allDayEventsView registerClass:MGCEventCell.class forCellWithReuseIdentifier:EventCellReuseIdentifier];
		
		//[_allDayEventsView registerClass:UICollectionReusableView.class forSupplementaryViewOfKind:MoreEventsViewKind withReuseIdentifier:MoreEventsViewReuseIdentifier];  // test
		
		UILongPressGestureRecognizer *longPress = [UILongPressGestureRecognizer new];
		[longPress addTarget:self action:@selector(handleLongPress:)];
		[_allDayEventsView addGestureRecognizer:longPress];
		
		UITapGestureRecognizer *tap = [UITapGestureRecognizer new];
		[tap addTarget:self action:@selector(handleTap:)];
		[_allDayEventsView addGestureRecognizer:tap];

	}
	return _allDayEventsView;
}

- (UICollectionView*)dayColumnsView
{
	if (!_dayColumnsView) {
        MGCDayColumnViewFlowLayout *layout = [MGCDayColumnViewFlowLayout new];
		layout.scrollDirection = UICollectionViewScrollDirectionHorizontal;
		layout.minimumInteritemSpacing = 0;
		layout.minimumLineSpacing = 0;
        
		_dayColumnsView = [[UICollectionView alloc] initWithFrame:CGRectZero collectionViewLayout:layout];
		_dayColumnsView.backgroundColor = [UIColor clearColor];
		_dayColumnsView.dataSource = self;
		_dayColumnsView.delegate = self;
		_dayColumnsView.showsHorizontalScrollIndicator = NO;
		_dayColumnsView.decelerationRate = UIScrollViewDecelerationRateFast;
		_dayColumnsView.scrollEnabled = NO;
		_dayColumnsView.allowsSelection = NO;
		
		[_dayColumnsView registerClass:MGCDayColumnCell.class forCellWithReuseIdentifier:DayColumnCellReuseIdentifier];
	}
	return _dayColumnsView;
}

- (UIScrollView*)timeScrollView
{
	if (!_timeScrollView) {
		_timeScrollView = [[UIScrollView alloc]initWithFrame:CGRectZero];
		_timeScrollView.backgroundColor = [UIColor clearColor];
		_timeScrollView.delegate = self;
		_timeScrollView.showsVerticalScrollIndicator = NO;
		_timeScrollView.decelerationRate = UIScrollViewDecelerationRateFast;
		_timeScrollView.scrollEnabled = NO;
		
		_timeRowsView = [[MGCTimeRowsView alloc]initWithFrame:CGRectZero];
        _timeRowsView.delegate = self;
        _timeRowsView.timeColor = self.timeSeparatorsColor;
        _timeRowsView.currentTimeColor = self.currentTimeColor;
		_timeRowsView.hourSlotHeight = self.hourSlotHeight;
        _timeRowsView.hourRange = self.hourRange;
		_timeRowsView.insetsHeight = self.eventsViewInnerMargin;
		_timeRowsView.timeColumnWidth = self.timeColumnWidth;
		_timeRowsView.contentMode = UIViewContentModeRedraw;
		[_timeScrollView addSubview:_timeRowsView];
	}
	return _timeScrollView;
}

- (UIView*)allDayEventsBackgroundView
{
	if (!_allDayEventsBackgroundView) {
		_allDayEventsBackgroundView = [[UIView alloc] initWithFrame:CGRectZero];
		_allDayEventsBackgroundView.backgroundColor = [UIColor colorWithRed:.8 green:.8 blue:.83 alpha:1.];
		_allDayEventsBackgroundView.clipsToBounds = YES;
		_allDayEventsBackgroundView.layer.borderColor = [UIColor lightGrayColor].CGColor;
		_allDayEventsBackgroundView.layer.borderWidth = 1;
	}
	return _allDayEventsBackgroundView;
}


#pragma mark - Layouts

- (MGCTimedEventsViewLayout*)timedEventsViewLayout
{
	if (!_timedEventsViewLayout) {
		_timedEventsViewLayout = [MGCTimedEventsViewLayout new];
		_timedEventsViewLayout.delegate = self;
		_timedEventsViewLayout.dayColumnSize = self.dayColumnSize;
        _timedEventsViewLayout.coveringType = self.eventCoveringType == TimedEventCoveringTypeComplex ? TimedEventCoveringTypeComplex : TimedEventCoveringTypeClassic;
	}
	return _timedEventsViewLayout;
}

- (MGCAllDayEventsViewLayout*)allDayEventsViewLayout
{
	if (!_allDayEventsViewLayout && self.showsAllDayEvents) {
		_allDayEventsViewLayout = [MGCAllDayEventsViewLayout new];
		_allDayEventsViewLayout.delegate = self;
		_allDayEventsViewLayout.dayColumnWidth = self.dayColumnSize.width;
		_allDayEventsViewLayout.eventCellHeight = self.allDayEventCellHeight;
		//_allDayEventsViewLayout.maxContentHeight = 45; // test
	}
	return _allDayEventsViewLayout;
}

#pragma mark - Event view manipulation

- (void)registerClass:(Class)viewClass forEventViewWithReuseIdentifier:(NSString*)identifier
{
	[self.reuseQueue registerClass:viewClass forObjectWithReuseIdentifier:identifier];
}

- (MGCEventView*)dequeueReusableViewWithIdentifier:(NSString*)identifier forEventOfType:(MGCEventType)type atIndex:(NSUInteger)index date:(NSDate*)date
{
	return (MGCEventView*)[self.reuseQueue dequeueReusableObjectWithReuseIdentifier:identifier];
}

#pragma mark - Zooming

- (void)handlePinch:(UIPinchGestureRecognizer*)gesture
{
	if (!self.zoomingEnabled) return;
	
	if (gesture.state == UIGestureRecognizerStateBegan) {
		self.hourSlotHeightForGesture = self.hourSlotHeight;
	}
	else if (gesture.state == UIGestureRecognizerStateChanged) {
		if (gesture.numberOfTouches > 1) {
			CGFloat hourSlotHeight = self.hourSlotHeightForGesture * gesture.scale;
			
			if (hourSlotHeight != self.hourSlotHeight) {
				self.hourSlotHeight = hourSlotHeight;

                if ([self.delegate respondsToSelector:@selector(dayPlannerViewDidZoom:)]) {
					[self.delegate dayPlannerViewDidZoom:self];
				}
			}
		}
	}
}

#pragma mark - Selection

- (void)handleTap:(UITapGestureRecognizer*)gesture
{
	if (gesture.state == UIGestureRecognizerStateEnded)
	{
		[self deselectEventWithDelegate:YES]; // deselect previous
		
		UICollectionView *view = (UICollectionView*)gesture.view;
		CGPoint pt = [gesture locationInView:view];
		
		NSIndexPath *path = [view indexPathForItemAtPoint:pt];
		if (path)  // a cell was touched
		{
			NSDate *date = [self dateFromDayOffset:path.section];
			MGCEventType type = (view == self.timedEventsView) ? MGCTimedEventType : MGCAllDayEventType;
			
			[self selectEventWithDelegate:YES type:type atIndex:path.item date:date];
		}
	}
}

// public
- (MGCEventView*)selectedEventView
{
	if (self.selectedCellIndexPath) {
		MGCEventCell *cell = [self collectionViewCellForEventOfType:self.selectedCellType atIndexPath:self.selectedCellIndexPath];
		return cell.eventView;
	}
	return nil;
}

// tellDelegate is used to distinguish between user selection (touch) where delegate is informed,
// and programmatically selected events where delegate is not informed
-(void)selectEventWithDelegate:(BOOL)tellDelegate type:(MGCEventType)type atIndex:(NSUInteger)index date:(NSDate*)date
{
	[self deselectEventWithDelegate:tellDelegate];
	
	if (self.allowsSelection) {
		NSInteger section = [self dayOffsetFromDate:date];
		NSIndexPath *path = [NSIndexPath indexPathForItem:index inSection:section];
		
		MGCEventCell *cell = [self collectionViewCellForEventOfType:type atIndexPath:path];
		if (cell)
		{
			BOOL shouldSelect = YES;
			if (tellDelegate && [self.delegate respondsToSelector:@selector(dayPlannerView:shouldSelectEventOfType:atIndex:date:)]) {
				shouldSelect = [self.delegate dayPlannerView:self shouldSelectEventOfType:type atIndex:index date:date];
			}

			if (shouldSelect) {
				cell.selected = YES;
				self.selectedCellIndexPath = path;
				self.selectedCellType = type;
				
				if (tellDelegate && [self.delegate respondsToSelector:@selector(dayPlannerView:didSelectEventOfType:atIndex:date:)]) {
					[self.delegate dayPlannerView:self didSelectEventOfType:type atIndex:path.item date:date];
				}
			}
		}
	}
}

// public
- (void)selectEventOfType:(MGCEventType)type atIndex:(NSUInteger)index date:(NSDate*)date
{
	[self selectEventWithDelegate:NO type:type atIndex:index date:date];
}

// tellDelegate is used to distinguish between user deselection (touch) where delegate is informed,
// and programmatically deselected events where delegate is not informed
- (void)deselectEventWithDelegate:(BOOL)tellDelegate
{
	if (self.allowsSelection && self.selectedCellIndexPath)
	{
		MGCEventCell *cell = [self collectionViewCellForEventOfType:self.selectedCellType atIndexPath:self.selectedCellIndexPath];
		cell.selected = NO;
		
		NSDate *date = [self dateFromDayOffset:self.selectedCellIndexPath.section];
		if (tellDelegate && [self.delegate respondsToSelector:@selector(dayPlannerView:didDeselectEventOfType:atIndex:date:)]) {
			[self.delegate dayPlannerView:self didDeselectEventOfType:self.selectedCellType atIndex:self.selectedCellIndexPath.item date:date];
		}
		
		self.selectedCellIndexPath = nil;
	}
}

// public
- (void)deselectEvent
{
	[self deselectEventWithDelegate:NO];
}

#pragma mark - Event views interaction

// For non modifiable events like holy days, birthdays... for which delegate method
// shouldStartMovingEventOfType returns NO, we bounce animate the cell when user tries to move it
- (void)bounceAnimateCell:(MGCEventCell*)cell
{
	CGRect frame = cell.frame;
	
	[UIView animateWithDuration:0.2 animations:^{
		[UIView setAnimationRepeatCount:2];
		cell.frame = CGRectInset(cell.frame, -4, -2);
	} completion:^(BOOL finished){
		cell.frame = frame;
	}];
}

- (CGRect)rectForNewEventOfType:(MGCEventType)type atDate:(NSDate*)date
{
	NSUInteger section = [self dayOffsetFromDate:date];
	CGFloat x = section * self.dayColumnSize.width;
	
	if (type == MGCTimedEventType) {
        CGFloat y =  [self offsetFromTime:self.durationForNewTimedEvent rounding:0];
 		CGRect rect = CGRectMake(x, y, self.dayColumnSize.width, self.interactiveCellTimedEventHeight);
		return [self convertRect:rect fromView:self.timedEventsView];
	}
	else if (type == MGCAllDayEventType) {
		CGRect rect = CGRectMake(x, 0, self.dayColumnSize.width, self.allDayEventCellHeight);
		return [self convertRect:rect fromView:self.allDayEventsView];
	}
	
	return CGRectNull;
}

- (void)handleLongPress:(UILongPressGestureRecognizer*)gesture
{
	CGPoint ptSelf = [gesture locationInView:self];

	// long press on a cell or an empty space in the view
	if (gesture.state == UIGestureRecognizerStateBegan)
	{
		[self endInteraction]; // in case previous interaction did not end properly
		
		[self setUserInteractionEnabled:NO];
		
		// where did the gesture start ?
		UICollectionView *view = (UICollectionView*)gesture.view;
		MGCEventType type = (view == self.timedEventsView) ? MGCTimedEventType : MGCAllDayEventType;
		NSIndexPath *path = [view indexPathForItemAtPoint:[gesture locationInView:view]];
		
		if (path) {	// a cell was touched
			if (![self beginMovingEventOfType:type atIndexPath:path]) {
				gesture.enabled = NO;
				gesture.enabled = YES;
			}
			else {
				self.interactiveCellTouchPoint = [gesture locationInView:self.interactiveCell];
			}
		}
		else {		// an empty space was touched
            CGFloat createEventSlotHeight = floor(self.durationForNewTimedEvent * self.hourSlotHeight / 60.0f / 60.0f);
			NSDate *date = [self dateAtPoint:CGPointMake(ptSelf.x, ptSelf.y - createEventSlotHeight / 2) rounded:YES];
						
			if (![self beginCreateEventOfType:type atDate:date]) {
				gesture.enabled = NO;
				gesture.enabled = YES;
			}
		}
	}
	// interactive cell was moved
	else if (gesture.state == UIGestureRecognizerStateChanged)
	{
		[self moveInteractiveCellAtPoint:[gesture locationInView:self]];
	}
	// finger was lifted
	else if (gesture.state == UIGestureRecognizerStateEnded)
	{
		[self.dragTimer invalidate];
		self.dragTimer = nil;
		//[self scrollViewDidEndScrolling:self.controllingScrollView];
		
		NSDate *date = [self dateAtPoint:self.interactiveCell.frame.origin rounded:YES];
        
		if (!self.isInteractiveCellForNewEvent) // existing event
		{
			if (!self.acceptsTarget) {
				[self endInteraction];
			}
			else if (date && [self.dataSource respondsToSelector:@selector(dayPlannerView:moveEventOfType:atIndex:date:toType:date:)]) {
				[self.dataSource dayPlannerView:self moveEventOfType:self.movingEventType atIndex:self.movingEventIndex date:self.movingEventDate toType:self.interactiveCellType date:date];
			}
		}
		else  // new event
		{
			if (!self.acceptsTarget) {
				[self endInteraction];
			}
			else if (date && [self.dataSource respondsToSelector:@selector(dayPlannerView:createNewEventOfType:atDate:)]) {
				[self.dataSource dayPlannerView:self createNewEventOfType:self.interactiveCellType atDate:date];
			}
		}
		
		[self setUserInteractionEnabled:YES];
		//[self endInteraction];
	}
	else if (gesture.state == UIGestureRecognizerStateCancelled)
	{
		[self setUserInteractionEnabled:YES];
	}
}

- (BOOL)beginCreateEventOfType:(MGCEventType)type atDate:(NSDate*)date
{
	NSAssert([self.visibleDays containsDate:date], @"beginCreateEventOfType:atDate for non visible date");

	if (!self.canCreateEvents) return NO;
	
    self.interactiveCellTimedEventHeight = floor(self.durationForNewTimedEvent * self.hourSlotHeight / 60.0f / 60.0f);
    
	self.isInteractiveCellForNewEvent = YES;
	self.interactiveCellType = type;
	self.interactiveCellTouchPoint = CGPointMake(0, self.interactiveCellTimedEventHeight / 2);
	self.interactiveCellDate = date;
	
	self.interactiveCell = [[MGCInteractiveEventView alloc]initWithFrame:CGRectZero];

	if ([self.dataSource respondsToSelector:@selector(dayPlannerView:viewForNewEventOfType:atDate:)]) {
		self.interactiveCell.eventView = [self.dataSource dayPlannerView:self viewForNewEventOfType:type atDate:date];
		NSAssert(self.interactiveCell, @"dayPlannerView:viewForNewEventOfType:atDate can't return nil");
	}
	else {
        MGCStandardEventView *eventView = [[MGCStandardEventView alloc]initWithFrame:CGRectZero];
        eventView.title = NSLocalizedString(@"New Event", nil);
        self.interactiveCell.eventView = eventView;
	}
	
	self.acceptsTarget = YES;
	if ([self.dataSource respondsToSelector:@selector(dayPlannerView:canCreateNewEventOfType:atDate:)]) {
		if (![self.dataSource dayPlannerView:self canCreateNewEventOfType:type atDate:date]) {
			self.interactiveCell.forbiddenSignVisible = YES;
			self.acceptsTarget = NO;
		}
	}
	
    CGRect rect = [self rectForNewEventOfType:type atDate:date];
	self.interactiveCell.frame = rect;
	[self addSubview:self.interactiveCell];
	self.interactiveCell.hidden = NO;
	
	return YES;
}

- (BOOL)beginMovingEventOfType:(MGCEventType)type atIndexPath:(NSIndexPath*)path
{
	if (!self.canMoveEvents) return NO;
	
	UICollectionView *view = (type == MGCTimedEventType) ? self.timedEventsView : self.allDayEventsView;
	NSDate *date = [self dateFromDayOffset:path.section];
	
	if ([self.dataSource respondsToSelector:@selector(dayPlannerView:shouldStartMovingEventOfType:atIndex:date:)]) {
		if (![self.dataSource dayPlannerView:self shouldStartMovingEventOfType:type atIndex:path.item date:date]) {
			
			MGCEventCell *cell = (MGCEventCell*)[view cellForItemAtIndexPath:path];
			[self bounceAnimateCell:cell];
			return NO;
		}
	}
	
	self.movingEventType = type;
	self.movingEventIndex = path.item;
	
	self.isInteractiveCellForNewEvent = NO;
	self.interactiveCellType = type;
	
	MGCEventCell *cell = (MGCEventCell*)[view cellForItemAtIndexPath:path];
	MGCEventView *eventView = cell.eventView;
	
	// copy the cell
	self.interactiveCell = [[MGCInteractiveEventView alloc]initWithFrame:CGRectZero];
	self.interactiveCell.eventView = [eventView copy];
	
	// adjust the frame
	CGRect frame = [self convertRect:cell.frame fromView:view];
	if (type == MGCTimedEventType) {
		frame.size.width = self.dayColumnSize.width;
	}
	//frame.size.width = cell.frame.size.width; // TODO: this is wrong for all day events
	self.interactiveCell.frame = frame;
	
    self.interactiveCellDate = [self dateAtPoint:self.interactiveCell.frame.origin rounded:YES];
    self.movingEventDate = self.interactiveCellDate;
    
	// record the height of the cell (this is necessary when we move back from AllDayEventType to TimedEventType
	self.interactiveCellTimedEventHeight = (type == MGCTimedEventType ? frame.size.height : self.hourSlotHeight);
	
	self.acceptsTarget = YES;
	//[self.interactiveCell didTransitionToEventType:type];  // TODO: fix
	
	//self.interactiveCell.selected = YES;
	[self addSubview:self.interactiveCell];
	self.interactiveCell.hidden = NO;
	
	return YES;
}

- (void)updateMovingCellAtPoint:(CGPoint)point
{
	CGPoint ptDayColumnsView = [self convertPoint:point toView:self.dayColumnsView];
	CGPoint ptEventsView = [self.timedEventsView convertPoint:point fromView:self];
	
	NSUInteger section = ptDayColumnsView.x / self.dayColumnSize.width;
	CGPoint origin = CGPointMake(section * self.dayColumnSize.width, ptDayColumnsView.y);
	origin = [self convertPoint:origin fromView:self.dayColumnsView];
	
	CGSize size = self.interactiveCell.frame.size; // cell size
	
	MGCEventType type = MGCTimedEventType;
	if (self.showsAllDayEvents && point.y < CGRectGetMinY(self.timedEventsView.frame)) {
		type = MGCAllDayEventType;
	}
	
	BOOL didTransition = type != self.interactiveCellType;
	
	self.interactiveCellType = type;
	
	self.acceptsTarget = YES;
	
	NSDate *date = [self dateAtPoint:self.interactiveCell.frame.origin rounded:YES];
	self.interactiveCellDate = date;
	
	if (self.isInteractiveCellForNewEvent) {
		if ([self.dataSource respondsToSelector:@selector(dayPlannerView:canCreateNewEventOfType:atDate:)]) {
			if (date && ![self.dataSource dayPlannerView:self canCreateNewEventOfType:type atDate:date]) {
				self.acceptsTarget = NO;
			}
		}
	}
	else {
		if ([self.dataSource respondsToSelector:@selector(dayPlannerView:canMoveEventOfType:atIndex:date:toType:date:)]) {
			if (date && ![self.dataSource dayPlannerView:self canMoveEventOfType:self.movingEventType atIndex:self.movingEventIndex date:self.movingEventDate toType:type date:date]) {
				self.acceptsTarget = NO;
			}
		}
	}
	
	self.interactiveCell.forbiddenSignVisible = !self.acceptsTarget;
	
	if (self.interactiveCellType == MGCTimedEventType) {
		size.height = self.interactiveCellTimedEventHeight;
			
		// constraint position
		ptEventsView.y -= self.interactiveCellTouchPoint.y;
		ptEventsView.y = fmaxf(ptEventsView.y, self.eventsViewInnerMargin);
		ptEventsView.y = fminf(ptEventsView.y, self.timedEventsView.contentSize.height - self.eventsViewInnerMargin);
			
		origin.y = [self convertPoint:ptEventsView fromView:self.timedEventsView].y;
		origin.y = fmaxf(origin.y, self.timedEventsView.frame.origin.y);
		
        self.timeRowsView.timeMark = [self timeFromOffset:ptEventsView.y rounding:0];;
	}
	else {
		size.height = self.allDayEventCellHeight;
		origin.y = self.allDayEventsView.frame.origin.y; // top of the view
	}
	
	CGRect cellFrame = self.interactiveCell.frame;
	
	NSTimeInterval animationDur = (origin.x != cellFrame.origin.x) ? .02 : .15;
	
	cellFrame.origin = origin;
	cellFrame.size = size;
	[UIView animateWithDuration:animationDur delay:0 options:/*UIViewAnimationOptionBeginFromCurrentState|*/UIViewAnimationOptionCurveEaseIn animations:^{
		self.interactiveCell.frame = cellFrame;
	} completion:^(BOOL finished) {
		if (didTransition) {
			[self.interactiveCell.eventView didTransitionToEventType:self.interactiveCellType];
		}
	}];
}

// point in self coordinates
- (void)moveInteractiveCellAtPoint:(CGPoint)point
{
	CGRect rightScrollRect = CGRectMake(CGRectGetMaxX(self.bounds) - 30, 0, 30, self.bounds.size.height);
	CGRect leftScrollRect = CGRectMake(0, 0, self.timeColumnWidth + 20, self.bounds.size.height);
	CGRect downScrollRect = CGRectMake(self.timeColumnWidth, CGRectGetMaxY(self.bounds) - 30, self.bounds.size.width, 30);
	CGRect upScrollRect = CGRectMake(self.timeColumnWidth, self.timedEventsView.frame.origin.y, self.bounds.size.width, 30);
	
	if (self.dragTimer) {
		[self.dragTimer invalidate];
		self.dragTimer = nil;
	}
	
	// speed depends on day column width
	NSTimeInterval ti = (self.dayColumnSize.width / 100.) * 0.05;
	
	if (CGRectContainsPoint(rightScrollRect, point)) {
		// progressive speed
		ti /= (point.x - rightScrollRect.origin.x) / 30;
		self.dragTimer = [NSTimer scheduledTimerWithTimeInterval:ti target:self selector:@selector(dragTimerDidFire:) userInfo:@{@"direction": @(ScrollDirectionLeft)} repeats:YES];
	}
	else if (CGRectContainsPoint(leftScrollRect, point)) {
		ti /= (CGRectGetMaxX(leftScrollRect) - point.x) / 30;
		self.dragTimer = [NSTimer scheduledTimerWithTimeInterval:ti target:self selector:@selector(dragTimerDidFire:) userInfo:@{@"direction": @(ScrollDirectionRight)} repeats:YES];
	}
	else if (CGRectContainsPoint(downScrollRect, point)) {
		self.dragTimer = [NSTimer scheduledTimerWithTimeInterval:0.05 target:self selector:@selector(dragTimerDidFire:) userInfo:@{@"direction": @(ScrollDirectionDown)} repeats:YES];
	}
	else if (CGRectContainsPoint(upScrollRect, point)) {
		self.dragTimer = [NSTimer scheduledTimerWithTimeInterval:0.05 target:self selector:@selector(dragTimerDidFire:) userInfo:@{@"direction": @(ScrollDirectionUp)} repeats:YES];
	}
	
	[self updateMovingCellAtPoint:point];
}

- (void)dragTimerDidFire:(NSTimer*)timer
{
	//NSLog(@"dragTimerDidFire");
	
	ScrollDirection direction = [[timer.userInfo objectForKey:@"direction"] unsignedIntegerValue];
	
	CGPoint offset = self.timedEventsView.contentOffset;
	if (direction == ScrollDirectionLeft) {
		offset.x += self.dayColumnSize.width;
		offset.x = fminf(offset.x, self.timedEventsView.contentSize.width - self.timedEventsView.bounds.size.width);
	}
	else if (direction == ScrollDirectionRight) {
		offset.x -= self.dayColumnSize.width;
		offset.x = fmaxf(offset.x, 0);
	}
	else if (direction == ScrollDirectionDown) {
		offset.y += 20;
		offset.y = fminf(offset.y, self.timedEventsView.contentSize.height - self.timedEventsView.bounds.size.height);
	}
	else if (direction == ScrollDirectionUp) {
		offset.y -= 20;
		offset.y = fmaxf(offset.y, 0);
	}
	
	// This test is important, because if we can't move (at the start or end of content),
	// setContentOffset will have no effect, and will not send scrollViewDidEndScrollingAnimation:
	// so we won't get any chance to reset everything
	if (!CGPointEqualToPoint(self.timedEventsView.contentOffset, offset)) {
		[self setTimedEventsViewContentOffset:offset animated:NO completion:nil];
		
		// scrolling will be enabled again in scrollViewDidEndScrolling:
	}
}

- (void)endInteraction
{
	if (self.interactiveCell) {
		self.interactiveCell.hidden = YES;
		[self.interactiveCell removeFromSuperview];
		self.interactiveCell = nil;
        
        [self.dragTimer invalidate];
        self.dragTimer = nil;
	}
	self.interactiveCellTouchPoint = CGPointZero;
	self.timeRowsView.timeMark = 0;
}

#pragma mark - Reloading content

// this is called whenever we recenter the views during scrolling
// or when the number of visible days or the date range changes
- (void)reloadCollectionViews
{
	//NSLog(@"reloadCollectionsViews");
	
	[self deselectEventWithDelegate:YES];
    
    CGSize dayColumnSize = self.dayColumnSize;
    
    self.timedEventsViewLayout.dayColumnSize = dayColumnSize;
    self.allDayEventsViewLayout.dayColumnWidth = dayColumnSize.width;
    self.allDayEventsViewLayout.eventCellHeight = self.allDayEventCellHeight;
    
    [self.dayColumnsView reloadData];
	[self.timedEventsView reloadData];
    [self.allDayEventsView reloadData];

    if (!self.controllingScrollView) {  // only if we're not scrolling
       dispatch_async(dispatch_get_main_queue(), ^{ [self setupSubviews]; });
    }
}

// public
- (void)reloadAllEvents
{
	//NSLog(@"reloadAllEvents");
	
	[self deselectEventWithDelegate:YES];
	
	[self.allDayEventsView reloadData];
	[self.timedEventsView reloadData];
	
	if (!self.controllingScrollView) {
		dispatch_async(dispatch_get_main_queue(), ^{ [self setupSubviews]; });
	}
	
	[self.loadedDaysRange enumerateDaysWithCalendar:self.calendar usingBlock:^(NSDate *date, BOOL *stop) {
		[self refreshEventMarkForColumnAtDate:date];
	}];
}

- (void)refreshEventMarkForColumnAtDate:(NSDate*)date
{
	NSInteger section = [self dayOffsetFromDate:date];
	NSIndexPath *path = [NSIndexPath indexPathForItem:0 inSection:section];
	MGCDayColumnCell *cell = (MGCDayColumnCell*)[self.dayColumnsView cellForItemAtIndexPath:path];
	if (cell) {
		NSUInteger count = [self numberOfAllDayEventsAtDate:date] + [self numberOfTimedEventsAtDate:date];
		if (count > 0) {
			cell.accessoryTypes |= MGCDayColumnCellAccessoryDot;
		}
		else {
			cell.accessoryTypes &= ~MGCDayColumnCellAccessoryDot;
		}
	}
}

// public
- (void)reloadEventsAtDate:(NSDate*)date
{
	//NSLog(@"reloadEventsAtDate %@", date);

	[self deselectEventWithDelegate:YES];
	
	if ([self.loadedDaysRange containsDate:date]) {
	
        // we have to reload everything for the all-day events view because some events might span several days
		[self.allDayEventsView reloadData];
        
		if (!self.controllingScrollView) {
			// only if we're not scrolling
			[self setupSubviews];
		}
        NSInteger section = [self dayOffsetFromDate:date];
        
        // for some reason, reloadSections: does not work properly. See comment for ignoreNextInvalidation
        self.timedEventsViewLayout.ignoreNextInvalidation = YES; 
        [self.timedEventsView reloadData];
		
        MGCTimedEventsViewLayoutInvalidationContext *context = [MGCTimedEventsViewLayoutInvalidationContext new];
        context.invalidatedSections = [NSIndexSet indexSetWithIndex:section];
        [self.timedEventsView.collectionViewLayout invalidateLayoutWithContext:context];

		[self refreshEventMarkForColumnAtDate:date];
	}
}

// public
- (void)reloadDimmedTimeRanges
{
    [self.dimmedTimeRangesCache removeAllObjects];
    
    MGCTimedEventsViewLayoutInvalidationContext *context = [MGCTimedEventsViewLayoutInvalidationContext new];
    context.invalidatedSections = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, self.numberOfLoadedDays)];
    context.invalidateEventCells = NO;
    context.invalidateDimmingViews = YES;
    [self.timedEventsView.collectionViewLayout invalidateLayoutWithContext:context];
}

// public
- (void)insertEventOfType:(MGCEventType)type withDateRange:(MGCDateRange*)range
{
	NSInteger start = MAX([self dayOffsetFromDate:range.start], 0);
	NSInteger end = MIN([self dayOffsetFromDate:range.end], self.numberOfLoadedDays);
	
	NSMutableArray *indexPaths = [NSMutableArray array];
	for (NSInteger section = start; section <= end; section++) {
		NSDate *date = [self dateFromDayOffset:section];
		NSInteger num = [self.dataSource dayPlannerView:self numberOfEventsOfType:type atDate:date];
		NSIndexPath *path = [NSIndexPath indexPathForItem:num inSection:section];
		
		[indexPaths addObject:path];
	}
	
	
	if (type == MGCAllDayEventType) {
		//[self.allDayEventsView reloadSections:[NSIndexSet indexSetWithIndex:section]];
		[self.allDayEventsView insertItemsAtIndexPaths:indexPaths];
	}
	else if (type == MGCTimedEventType) {
		//[self.timedEventsView reloadSections:[NSIndexSet indexSetWithIndex:section]];
		[self.timedEventsView insertItemsAtIndexPaths:indexPaths];
	}
}

// public
- (BOOL)setActivityIndicatorVisible:(BOOL)visible forDate:(NSDate*)date
{
	if (visible) {
		[self.loadingDays addObject:date];
	}
	else {
		[self.loadingDays removeObject:date];
	}
	
	if ([self.loadedDaysRange containsDate:date]) {
		NSIndexPath *path = [NSIndexPath indexPathForItem:0 inSection:[self dayOffsetFromDate:date]];
		MGCDayColumnCell *cell = (MGCDayColumnCell*)[self.dayColumnsView cellForItemAtIndexPath:path];
		if (cell) {
			[cell setActivityIndicatorVisible:visible];
			return YES;
		}
	}
	return NO;
}

- (void)setupSubviews
{
    CGFloat allDayEventsViewHeight = 2;
	if (self.showsAllDayEvents) {
		allDayEventsViewHeight = fmaxf(self.allDayEventCellHeight + 4, self.allDayEventsView.contentSize.height);
		allDayEventsViewHeight = fminf(allDayEventsViewHeight, self.allDayEventCellHeight * 2.5 + 6);
	}
	CGFloat timedEventViewTop = self.dayHeaderHeight + allDayEventsViewHeight;
	CGFloat timedEventsViewWidth = self.bounds.size.width - self.timeColumnWidth;
	CGFloat timedEventsViewHeight = self.bounds.size.height - (self.dayHeaderHeight + allDayEventsViewHeight);
	
	//self.backgroundView.frame = CGRectMake(0, self.dayHeaderHeight, self.bounds.size.width, self.bounds.size.height - self.dayHeaderHeight);
	self.backgroundView.frame = CGRectMake(self.timeColumnWidth, self.dayHeaderHeight + allDayEventsViewHeight, timedEventsViewWidth, timedEventsViewHeight);
	self.backgroundView.frame = CGRectMake(0, timedEventViewTop, self.bounds.size.width, timedEventsViewHeight);
	if (!self.backgroundView.superview) {
		[self addSubview:self.backgroundView];
	}
	
	// x pos and width are adjusted in order to "hide" left and rigth borders
	self.allDayEventsBackgroundView.frame = CGRectMake(-1, self.dayHeaderHeight, self.bounds.size.width + 2, allDayEventsViewHeight);
	if (!self.allDayEventsBackgroundView.superview) {
		[self addSubview:self.allDayEventsBackgroundView];
	}
	
//	self.dayColumnsView.frame = CGRectMake(self.timeColumnWidth, 0, timedEventsViewWidth, self.bounds.size.height);
//	if (!self.dayColumnsView.superview) {
//		[self addSubview:self.dayColumnsView];
//	}
	
	self.allDayEventsView.frame = CGRectMake(self.timeColumnWidth, self.dayHeaderHeight, timedEventsViewWidth, allDayEventsViewHeight);
	if (!self.allDayEventsView.superview) {
		[self addSubview:self.allDayEventsView];
	}
	
    self.timedEventsView.frame = CGRectMake(self.timeColumnWidth, timedEventViewTop, timedEventsViewWidth, timedEventsViewHeight);
    if (!self.timedEventsView.superview) {
        [self addSubview:self.timedEventsView];
    }

	self.timeScrollView.contentSize = CGSizeMake(self.bounds.size.width, self.dayColumnSize.height);
	self.timeRowsView.frame = CGRectMake(0, 0, self.timeScrollView.contentSize.width, self.timeScrollView.contentSize.height);

	self.timeScrollView.frame = CGRectMake(0, timedEventViewTop, self.bounds.size.width, timedEventsViewHeight);
	if (!self.timeScrollView.superview) {
		[self addSubview:self.timeScrollView];
	}
	
	self.timeRowsView.showsCurrentTime = [self.visibleDays containsDate:[NSDate date]];
	
    self.timeScrollView.userInteractionEnabled = NO;
    
    
    self.dayColumnsView.frame = CGRectMake(self.timeColumnWidth, 0, timedEventsViewWidth, self.bounds.size.height);
    if (!self.dayColumnsView.superview) {
        [self addSubview:self.dayColumnsView];
    }

    self.dayColumnsView.userInteractionEnabled = NO;
//	self.timedEventsView.frame = CGRectMake(self.timeColumnWidth, timedEventViewTop, timedEventsViewWidth, timedEventsViewHeight);
//	if (!self.timedEventsView.superview) {
//		[self addSubview:self.timedEventsView];
//	}

    // make sure collection views are synchronized
    self.dayColumnsView.contentOffset = CGPointMake(self.timedEventsView.contentOffset.x, 0);
    self.timeScrollView.contentOffset = CGPointMake(0, self.timedEventsView.contentOffset.y);
    self.allDayEventsView.contentOffset = CGPointMake(self.timedEventsView.contentOffset.x, self.allDayEventsView.contentOffset.y);

	if (self.dragTimer == nil && self.interactiveCell && self.interactiveCellDate) {
		CGRect frame = self.interactiveCell.frame;
        frame.origin = [self offsetFromDate:self.interactiveCellDate eventType:self.interactiveCellType];
        frame.size.width = self.dayColumnSize.width;
		self.interactiveCell.frame = frame;
        self.interactiveCell.hidden = (self.interactiveCellType == MGCTimedEventType && !CGRectIntersectsRect(self.timedEventsView.frame, frame));
	}
	
	[self.allDayEventsView flashScrollIndicators];
}

#pragma mark - UIView

- (void)layoutSubviews
{
	//NSLog(@"layout subviews");

    [super layoutSubviews];
    
    CGSize dayColumnSize = self.dayColumnSize;
    
    self.timeRowsView.hourSlotHeight = self.hourSlotHeight;
    self.timeRowsView.timeColumnWidth = self.timeColumnWidth;
    self.timeRowsView.insetsHeight = self.eventsViewInnerMargin;
    
    self.timedEventsViewLayout.dayColumnSize = dayColumnSize;
    self.allDayEventsViewLayout.dayColumnWidth = dayColumnSize.width;
    self.allDayEventsViewLayout.eventCellHeight = self.allDayEventCellHeight;
    
	[self setupSubviews];
	[self updateVisibleDaysRange];
}

#pragma mark - MGCTimeRowsViewDelegate

- (NSAttributedString*)timeRowsView:(MGCTimeRowsView *)view attributedStringForTimeMark:(MGCDayPlannerTimeMark)mark time:(NSTimeInterval)ti
{
    if ([self.delegate respondsToSelector:@selector(dayPlannerView:attributedStringForTimeMark:time:)]) {
        return [self.delegate dayPlannerView:self attributedStringForTimeMark:mark time:ti];
    }
    return nil;
}

#pragma mark - UICollectionViewDataSource

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView*)collectionView
{
	return self.numberOfLoadedDays;
}

// public
- (NSInteger)numberOfTimedEventsAtDate:(NSDate*)date
{
    NSInteger section = [self dayOffsetFromDate:date];
	return [self.timedEventsView numberOfItemsInSection:section];
}

// public
- (NSInteger)numberOfAllDayEventsAtDate:(NSDate*)date
{
    if (!self.showsAllDayEvents) return 0;
	
	NSInteger section = [self dayOffsetFromDate:date];
	return [self.allDayEventsView numberOfItemsInSection:section];
}

// public
- (NSArray*)visibleEventViewsOfType:(MGCEventType)type
{
	NSMutableArray *views = [NSMutableArray array];
	if (type == MGCTimedEventType) {
		NSArray *visibleCells = [self.timedEventsView visibleCells];
		for (MGCEventCell *cell in visibleCells) {
			[views addObject:cell.eventView];
		}
	}
	else if (type == MGCAllDayEventType) {
		NSArray *visibleCells = [self.allDayEventsView visibleCells];
		for (MGCEventCell *cell in visibleCells) {
			[views addObject:cell.eventView];
		}
	}
	return views;
}

- (MGCEventCell*)collectionViewCellForEventOfType:(MGCEventType)type atIndexPath:(NSIndexPath*)indexPath
{
	MGCEventCell *cell = nil;
	if (type == MGCTimedEventType) {
		cell = (MGCEventCell*)[self.timedEventsView cellForItemAtIndexPath:indexPath];
	}
	else if (type == MGCAllDayEventType) {
		cell = (MGCEventCell*)[self.allDayEventsView cellForItemAtIndexPath:indexPath];
	}
	return cell;
}

- (NSInteger)collectionView:(UICollectionView*)collectionView numberOfItemsInSection:(NSInteger)section
{
	if (collectionView == self.timedEventsView) {
		NSDate *date = [self dateFromDayOffset:section];
		return [self.dataSource dayPlannerView:self numberOfEventsOfType:MGCTimedEventType atDate:date];
	}
	else if (collectionView == self.allDayEventsView) {
        if (!self.showsAllDayEvents) return 0;
		NSDate *date = [self dateFromDayOffset:section];
		return [self.dataSource dayPlannerView:self numberOfEventsOfType:MGCAllDayEventType atDate:date];
	}
	return 1; // for dayColumnView
}

- (UICollectionViewCell*)dayColumnCellAtIndexPath:(NSIndexPath*)indexPath
{
    MGCDayColumnCell *dayCell = [self.dayColumnsView dequeueReusableCellWithReuseIdentifier:DayColumnCellReuseIdentifier forIndexPath:indexPath];
    dayCell.headerHeight = self.dayHeaderHeight;
    dayCell.separatorColor = self.daySeparatorsColor;
    dayCell.dotColor = self.eventIndicatorDotColor;

    NSDate *date = [self dateFromDayOffset:indexPath.section];
    
    NSUInteger weekDay = [self.calendar components:NSCalendarUnitWeekday fromDate:date].weekday;
    NSUInteger accessoryTypes = weekDay == self.calendar.firstWeekday ? MGCDayColumnCellAccessorySeparator : MGCDayColumnCellAccessoryBorder;
    
    NSAttributedString *attrStr = nil;
    if ([self.delegate respondsToSelector:@selector(dayPlannerView:attributedStringForDayHeaderAtDate:)]) {
        attrStr = [self.delegate dayPlannerView:self attributedStringForDayHeaderAtDate:date];
    }
    
    if (attrStr) {
        dayCell.dayLabel.attributedText = attrStr;
    }
    else {
        
        static NSDateFormatter *dateFormatter = nil;
        if (dateFormatter == nil) {
            dateFormatter = [NSDateFormatter new];
        }
        dateFormatter.dateFormat = self.dateFormat ?: @"d MMM\neeeee";

        NSString *s = [dateFormatter stringFromDate:date];
        
        NSMutableParagraphStyle *para = [NSMutableParagraphStyle new];
        para.alignment = NSTextAlignmentCenter;
        
        UIFont *font = [UIFont systemFontOfSize:14];
        UIColor *color = [self.calendar isDateInWeekend:date] ? [UIColor lightGrayColor] : [UIColor blackColor];
        
        if ([self.calendar mgc_isDate:date sameDayAsDate:[NSDate date]]) {
            accessoryTypes |= MGCDayColumnCellAccessoryMark;
            dayCell.markColor = self.tintColor;
            color = [UIColor whiteColor];
            font = [UIFont boldSystemFontOfSize:14];
        }
        
        NSAttributedString *as = [[NSAttributedString alloc]initWithString:s attributes:@{ NSParagraphStyleAttributeName: para, NSFontAttributeName: font, NSForegroundColorAttributeName: color }];
        dayCell.dayLabel.attributedText = as;
    }
    
    if ([self.loadingDays containsObject:date]) {
        [dayCell setActivityIndicatorVisible:YES];
    }
    
    NSUInteger count = [self numberOfAllDayEventsAtDate:date] + [self numberOfTimedEventsAtDate:date];
    if (count > 0) {
        accessoryTypes |= MGCDayColumnCellAccessoryDot;
    }
    
    dayCell.accessoryTypes = accessoryTypes;
    return dayCell;
}

- (UICollectionViewCell*)dequeueCellForEventOfType:(MGCEventType)type atIndexPath:(NSIndexPath*)indexPath
{
	NSDate *date = [self dateFromDayOffset:indexPath.section];
	NSUInteger index = indexPath.item;
	MGCEventView *cell = [self.dataSource dayPlannerView:self viewForEventOfType:type atIndex:index date:date];
	
	MGCEventCell *cvCell = nil;
	if (type == MGCTimedEventType) {
		cvCell = (MGCEventCell*)[self.timedEventsView dequeueReusableCellWithReuseIdentifier:EventCellReuseIdentifier forIndexPath:indexPath];
	}
	else if (type == MGCAllDayEventType) {
		cvCell = (MGCEventCell*)[self.allDayEventsView dequeueReusableCellWithReuseIdentifier:EventCellReuseIdentifier forIndexPath:indexPath];
	}
	
	cvCell.eventView = cell;
	if ([self.selectedCellIndexPath isEqual:indexPath] && self.selectedCellType == type) {
		cvCell.selected = YES;
	}
		
	return cvCell;
}

- (UICollectionViewCell*)collectionView:(UICollectionView*)collectionView cellForItemAtIndexPath:(NSIndexPath*)indexPath
{
	if (collectionView == self.timedEventsView) {
		return [self dequeueCellForEventOfType:MGCTimedEventType atIndexPath:indexPath];
	}
	else if (collectionView == self.allDayEventsView) {
		return [self dequeueCellForEventOfType:MGCAllDayEventType atIndexPath:indexPath];
	}
	else if (collectionView == self.dayColumnsView) {
		return [self dayColumnCellAtIndexPath:indexPath];
	}
	return nil;
}

- (UICollectionReusableView*)collectionView:(UICollectionView*)collectionView viewForSupplementaryElementOfKind:(NSString*)kind atIndexPath:(NSIndexPath*)indexPath
{
    if ([kind isEqualToString:DimmingViewKind]) {
        UICollectionReusableView *view = [self.timedEventsView dequeueReusableSupplementaryViewOfKind:DimmingViewKind withReuseIdentifier:DimmingViewReuseIdentifier forIndexPath:indexPath];
        view.backgroundColor = self.dimmingColor;
        
        return view;
    }
    ///// test
    else if ([kind isEqualToString:MoreEventsViewKind]) {
        UICollectionReusableView *view = [self.allDayEventsView dequeueReusableSupplementaryViewOfKind:MoreEventsViewKind withReuseIdentifier:MoreEventsViewReuseIdentifier forIndexPath:indexPath];
        
        view.autoresizesSubviews = YES;
        
        NSUInteger hiddenCount = [self.allDayEventsViewLayout numberOfHiddenEventsInSection:indexPath.section];
        UILabel *label = [[UILabel alloc]initWithFrame:view.bounds];
        label.text = [NSString stringWithFormat:NSLocalizedString(@"%d more...", nil), hiddenCount];
        label.textColor = [UIColor blackColor];
        label.font = [UIFont systemFontOfSize:11];
        label.autoresizingMask = UIViewAutoresizingFlexibleHeight|UIViewAutoresizingFlexibleWidth;
        
        [view.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
        [view addSubview:label];
        
        return view;
    }
}

#pragma mark - MGCTimedEventsViewLayoutDelegate

- (CGRect)collectionView:(UICollectionView *)collectionView layout:(MGCTimedEventsViewLayout *)layout rectForEventAtIndexPath:(NSIndexPath *)indexPath
{
    NSDate *date = [self dateFromDayOffset:indexPath.section];
    
    MGCDateRange *dayRange = [self scrollableTimeRangeForDate:date];
    
    MGCDateRange* eventRange = [self.dataSource dayPlannerView:self dateRangeForEventOfType:MGCTimedEventType atIndex:indexPath.item date:date];
    NSAssert(eventRange, @"[AllDayEventsViewLayoutDelegate dayPlannerView:dateRangeForEventOfType:atIndex:date:] cannot return nil!");
    
    [eventRange intersectDateRange:dayRange];
    
    if (!eventRange.isEmpty) {
        CGFloat y1 = [self offsetFromDate:eventRange.start];
        CGFloat y2 = [self offsetFromDate:eventRange.end];
        
        return CGRectMake(0, y1, 0, y2 - y1);
    }
    return CGRectNull;
}

- (NSArray*)dimmedTimeRangesAtDate:(NSDate*)date
{
    NSMutableArray *ranges = [NSMutableArray array];
        
    if ([self.delegate respondsToSelector:@selector(dayPlannerView:numberOfDimmedTimeRangesAtDate:)]) {
        NSInteger count = [self.delegate dayPlannerView:self numberOfDimmedTimeRangesAtDate:date];
        
        if (count > 0 && [self.delegate respondsToSelector:@selector(dayPlannerView:dimmedTimeRangeAtIndex:date:)]) {
            MGCDateRange *dayRange = [self scrollableTimeRangeForDate:date];

            for (NSUInteger i = 0; i < count; i++) {
                MGCDateRange *range = [self.delegate dayPlannerView:self dimmedTimeRangeAtIndex:i date:date];
                
                [range intersectDateRange:dayRange];
                    
                if (!range.isEmpty) {
                    [ranges addObject:range];
                }
            }
        }
    }
    return ranges;
}

- (NSArray*)collectionView:(UICollectionView *)collectionView layout:(MGCTimedEventsViewLayout *)layout dimmingRectsForSection:(NSUInteger)section
{
    NSDate *date = [self dateFromDayOffset:section];

    NSArray *ranges = [self.dimmedTimeRangesCache objectForKey:date];
    if (!ranges) {
        ranges = [self dimmedTimeRangesAtDate:date];
        [self.dimmedTimeRangesCache setObject:ranges forKey:date];
    }
     
    NSMutableArray *rects = [NSMutableArray arrayWithCapacity:ranges.count];

    for (MGCDateRange *range in ranges) {
        if (!range.isEmpty) {
            CGFloat y1 = [self offsetFromDate:range.start];
            CGFloat y2 = [self offsetFromDate:range.end];
            
            [rects addObject:[NSValue valueWithCGRect:CGRectMake(0, y1, 0, y2 - y1)]];
        }
    }
    return rects;
}


#pragma mark - MGCAllDayEventsViewLayoutDelegate

- (NSRange)collectionView:(UICollectionView*)view layout:(MGCAllDayEventsViewLayout*)layout dayRangeForEventAtIndexPath:(NSIndexPath*)indexPath
{
	NSDate *date = [self dateFromDayOffset:indexPath.section];
	MGCDateRange *dateRange = [self.dataSource dayPlannerView:self dateRangeForEventOfType:MGCAllDayEventType atIndex:indexPath.item date:date];
	NSAssert(dateRange, @"[AllDayEventsViewLayoutDelegate dayPlannerView:dateRangeForEventOfType:atIndex:date:] cannot return nil!");
	
	if ([dateRange.start compare:self.startDate] == NSOrderedAscending)
		dateRange.start = self.startDate;
	
	NSUInteger startSection = [self dayOffsetFromDate:dateRange.start];
	NSUInteger length = [dateRange components:NSCalendarUnitDay forCalendar:self.calendar].day;
	
	return NSMakeRange(startSection, length);
}

// TODO: implement
- (AllDayEventInset)collectionView:(UICollectionView*)view layout:(MGCAllDayEventsViewLayout*)layout insetsForEventAtIndexPath:(NSIndexPath*)indexPath
{
	return AllDayEventInsetNone;
}

#pragma mark - UICollectionViewDelegate

//- (void)collectionView:(UICollectionView*)collectionView willDisplayCell:(UICollectionViewCell*)cell forItemAtIndexPath:(NSIndexPath*)indexPath
//{
//}
//
//- (void)collectionView:(UICollectionView*)collectionView didEndDisplayingCell:(UICollectionViewCell*)cell forItemAtIndexPath:(NSIndexPath*)indexPath
//{
//}

// this is only supported on iOS 9 and above
- (CGPoint)collectionView:(UICollectionView *)collectionView targetContentOffsetForProposedContentOffset:(CGPoint)proposedContentOffset
{
    if (self.scrollTargetDate) {
        NSInteger targetSection = [self dayOffsetFromDate:self.scrollTargetDate];
        proposedContentOffset.x  = targetSection * self.dayColumnSize.width;
    }
    return proposedContentOffset;
}

#pragma mark - Scrolling utilities

// The difficulty with scrolling is that:
// - we have to synchronize between the different collection views
// - we have to restrict dragging to one direction at a time
// - we have to recenter the views when needed to make the infinite scrolling possible
// - we have to deal with possibly nested scrolls (animating or tracking while decelerating...)


// this is a single entry point for scrolling, called by scrollViewWillBeginDragging: when dragging starts,
// and before any "programmatic" scrolling outside of an already started scroll operation, like scrollToDate:animated:
// If direction is ScrollDirectionUnknown, it will be determined on first scrollViewDidScroll: received
- (void)scrollViewWillStartScrolling:(UIScrollView*)scrollView direction:(ScrollDirection)direction
{
    NSAssert(scrollView == self.timedEventsView || scrollView == self.allDayEventsView, @"For synchronizing purposes, only timedEventsView or allDayEventsView are allowed to scroll");
	
	if (self.controllingScrollView) {
		NSAssert(scrollView == self.controllingScrollView, @"Scrolling on two different views at the same time is not allowed");

		// we might be dragging while decelerating on the same view, but scrolling will be
		// locked according to the initial axis
	}
	
	//NSLog(@"scrollViewWillStartScrolling direction: %d", (int)direction);
	
	//[self deselectEventWithDelegate:YES];
	
	if (self.controllingScrollView == nil) {
		// we have to restrict dragging to one view at a time
		// until the whole scroll operation finishes.
		
		if (scrollView == self.timedEventsView) {
			self.allDayEventsView.scrollEnabled = NO;
		}
		else if (scrollView == self.allDayEventsView) {
			self.timedEventsView.scrollEnabled = NO;
		}
		
		// note which view started scrolling - for synchronizing,
		// and the start offset in order to determine direction
		self.controllingScrollView = scrollView;
		self.scrollStartOffset = scrollView.contentOffset;
		self.scrollDirection = direction;
	}
}

// even though directionalLockEnabled is set on both scrolling-enabled scrollviews,
// one can still scroll diagonally if the scrollview is dragged in both directions at the same time.
// This is not what we want!
- (void)lockScrollingDirection
{
	NSAssert(self.controllingScrollView, @"Trying to lock scrolling direction while no scroll operation has started");
	
	CGPoint contentOffset = self.controllingScrollView.contentOffset;
	if (self.scrollDirection == ScrollDirectionUnknown) {
		// determine direction
		if (fabs(self.scrollStartOffset.x - contentOffset.x) < fabs(self.scrollStartOffset.y - contentOffset.y)) {
			self.scrollDirection = ScrollDirectionVertical;
		}
		else {
			self.scrollDirection = ScrollDirectionHorizontal;
		}
	}
	
	// lock scroll position of the scrollview according to detected direction
	if (self.scrollDirection & ScrollDirectionVertical) {
		[self.controllingScrollView	setContentOffset:CGPointMake(self.scrollStartOffset.x, contentOffset.y)];
	}
	else if (self.scrollDirection & ScrollDirectionHorizontal) {
		[self.controllingScrollView setContentOffset:CGPointMake(contentOffset.x, self.scrollStartOffset.y)];
	}
}

// calculates the new start date, given a date to be the first visible on the left.
// if offset is not nil, it contains on return the number of days between this new start date
// and the first visible date.
- (NSDate*)startDateForFirstVisibleDate:(NSDate*)date dayOffset:(NSUInteger*)offset
{
	NSAssert(date, @"startDateForFirstVisibleDate:dayOffset: was passed nil date");
	
	date = [self.calendar mgc_startOfDayForDate:date];
	
	NSDateComponents *comps = [NSDateComponents new];
	comps.day = -kDaysLoadingStep * self.numberOfVisibleDays;
	NSDate *start = [self.calendar dateByAddingComponents:comps toDate:date options:0];
	
	// stay within the limits of our date range
	if (self.dateRange && [start compare:self.dateRange.start] == NSOrderedAscending) {
		start = self.dateRange.start;
	}
	else if (self.maxStartDate && [start compare:self.maxStartDate] == NSOrderedDescending) {
		start = self.maxStartDate;
	}
	
	if (offset) {
		*offset = abs((int)[self.calendar components:NSCalendarUnitDay fromDate:start toDate:date options:0].day);
	}
	return start;
}

// if necessary, recenters horizontally the controlling scroll view to permit infinite scrolling.
// this is called by scrollViewDidScroll:
// returns YES if we loaded new pages, NO otherwise
- (BOOL)recenterIfNeeded
{
	NSAssert(self.controllingScrollView, @"Trying to recenter with no controlling scroll view");
	
	CGFloat xOffset = self.controllingScrollView.contentOffset.x;
	CGFloat xContentSize = self.controllingScrollView.contentSize.width;
	CGFloat xPageSize = self.controllingScrollView.bounds.size.width;
	
	// this could eventually be tweaked - for now we recenter when we have less than a page on one or the other side
	if (xOffset < xPageSize || xOffset + 2 * xPageSize > xContentSize) {
		NSDate *newStart = [self startDateForFirstVisibleDate:self.visibleDays.start dayOffset:nil];
		NSInteger diff = [self.calendar components:NSCalendarUnitDay fromDate:self.startDate toDate:newStart options:0].day;
		
		if (diff != 0) {
			self.startDate = newStart;
			[self reloadCollectionViews];
			
			CGFloat newXOffset = -diff * self.dayColumnSize.width + self.controllingScrollView.contentOffset.x;
			[self.controllingScrollView setContentOffset:CGPointMake(newXOffset, self.controllingScrollView.contentOffset.y)];
			return YES;
		}
	}
	return NO;
}

// this is called by scrollViewDidScroll: to synchronize the collections views
// vertically (timedEventsView with timeRowsView), and horizontally (allDayEventsView with timedEventsView and dayColumnsView)
- (void)synchronizeScrolling
{
	NSAssert(self.controllingScrollView, @"Synchronizing scrolling with no controlling scroll view");
	
	CGPoint contentOffset = self.controllingScrollView.contentOffset;
	
	if (self.controllingScrollView == self.allDayEventsView && self.scrollDirection & ScrollDirectionHorizontal) {
		
		self.dayColumnsView.contentOffset = CGPointMake(contentOffset.x, 0);
		self.timedEventsView.contentOffset = CGPointMake(contentOffset.x, self.timedEventsView.contentOffset.y);
	}
	else if (self.controllingScrollView == self.timedEventsView) {
		
		if (self.scrollDirection & ScrollDirectionHorizontal) {
			self.dayColumnsView.contentOffset = CGPointMake(contentOffset.x, 0);
			self.allDayEventsView.contentOffset = CGPointMake(contentOffset.x, self.allDayEventsView.contentOffset.y);
		}
		else {
			self.timeScrollView.contentOffset = CGPointMake(0, contentOffset.y);
		}
	}
}

// this is called at the end of every scrolling operation, initiated by user or programatically
- (void)scrollViewDidEndScrolling:(UIScrollView*)scrollView
{
	//NSLog(@"scrollViewDidEndScrolling");
	
	// reset everything
	if (scrollView == self.controllingScrollView) {
		ScrollDirection direction = self.scrollDirection;
		
		self.scrollDirection = ScrollDirectionUnknown;
		self.timedEventsView.scrollEnabled = YES;
		self.allDayEventsView.scrollEnabled = YES;
		self.controllingScrollView = nil;
		
		if (self.scrollViewAnimationCompletionBlock) {
			dispatch_async(dispatch_get_main_queue(), self.scrollViewAnimationCompletionBlock);
			self.scrollViewAnimationCompletionBlock =  nil;
		}
		
        if (direction == ScrollDirectionHorizontal) {
            [self setupSubviews];  // allDayEventsView might need to be resized
        }
        
		if ([self.delegate respondsToSelector:@selector(dayPlannerView:didEndScrolling:)]) {
			MGCDayPlannerScrollType type = direction == ScrollDirectionHorizontal ? MGCDayPlannerScrollDate : MGCDayPlannerScrollTime;
			[self.delegate dayPlannerView:self didEndScrolling:type];
		}
	}
}

																					
// this is the entry point for every programmatic scrolling of the timed events view
- (void)setTimedEventsViewContentOffset:(CGPoint)offset animated:(BOOL)animated completion:(void (^)(void))completion
{
	// animated programmatic scrolling is prohibited while another scrolling operation is in progress
	if (self.controllingScrollView)  return;
    
	CGPoint prevOffset = self.timedEventsView.contentOffset;

    if (animated && !CGPointEqualToPoint(offset, prevOffset)) {
        [[UIDevice currentDevice]endGeneratingDeviceOrientationNotifications];
    }

	self.scrollViewAnimationCompletionBlock = completion;
		
	[self scrollViewWillStartScrolling:self.timedEventsView direction:ScrollDirectionUnknown];
	[self.timedEventsView setContentOffset:offset animated:animated];
	
	if (!animated || CGPointEqualToPoint(offset, prevOffset)) {
		[self scrollViewDidEndScrolling:self.timedEventsView];
	}
}

- (void)updateVisibleDaysRange
{
	MGCDateRange *oldRange = self.previousVisibleDays;
	MGCDateRange *newRange = self.visibleDays;
	
	if ([oldRange isEqual:newRange]) return;
	
	if ([oldRange intersectsDateRange:newRange]) {
		MGCDateRange *range = [oldRange copy];
		[range unionDateRange:newRange];
		
		[range enumerateDaysWithCalendar:self.calendar usingBlock:^(NSDate *date, BOOL *stop){
			if ([oldRange containsDate:date] && ![newRange containsDate:date] &&
				[self.delegate respondsToSelector:@selector(dayPlannerView:didEndDisplayingDate:)])
			{
				[self.delegate dayPlannerView:self didEndDisplayingDate:date];
			}
			else if ([newRange containsDate:date] && ![oldRange containsDate:date] &&
				[self.delegate respondsToSelector:@selector(dayPlannerView:willDisplayDate:)])
			{
				[self.delegate dayPlannerView:self willDisplayDate:date];
			}
		}];
	}
	else {
		[oldRange enumerateDaysWithCalendar:self.calendar usingBlock:^(NSDate *date, BOOL *stop){
			if ([self.delegate respondsToSelector:@selector(dayPlannerView:didEndDisplayingDate:)]) {
				[self.delegate dayPlannerView:self didEndDisplayingDate:date];
			}
		}];
		[newRange enumerateDaysWithCalendar:self.calendar usingBlock:^(NSDate *date, BOOL *stop){
			if ([self.delegate respondsToSelector:@selector(dayPlannerView:willDisplayDate:)]) {
				[self.delegate dayPlannerView:self willDisplayDate:date];
			}
		}];
	}
	
	self.previousVisibleDays = newRange;
}

#pragma mark - UIScrollViewDelegate

- (void)scrollViewWillBeginDragging:(UIScrollView*)scrollView
{
	//NSLog(@"scrollViewWillBeginDragging");
	
	// direction will be determined on first scrollViewDidScroll: received
	[self scrollViewWillStartScrolling:scrollView direction:ScrollDirectionUnknown];
}

- (void)scrollViewDidScroll:(UIScrollView*)scrollview
{
    // avoid looping
	if (scrollview != self.controllingScrollView)
		return;
    
	//NSLog(@"scrollViewDidScroll");
	
	[self lockScrollingDirection];
	
	if (self.scrollDirection & ScrollDirectionHorizontal) {
		[self recenterIfNeeded];
	}
	
	[self synchronizeScrolling];
	
	[self updateVisibleDaysRange];
	
	if ([self.delegate respondsToSelector:@selector(dayPlannerView:didScroll:)]) {
		MGCDayPlannerScrollType type = self.scrollDirection == ScrollDirectionHorizontal ? MGCDayPlannerScrollDate : MGCDayPlannerScrollTime;
		[self.delegate dayPlannerView:self didScroll:type];
	}
}

- (void)scrollViewWillEndDragging:(UIScrollView*)scrollView withVelocity:(CGPoint)velocity targetContentOffset:(inout CGPoint*)targetContentOffset
{
    //NSLog(@"scrollViewWillEndDragging horzVelocity: %f", velocity.x);
    
    if (!(self.scrollDirection & ScrollDirectionHorizontal)) return;
    
    CGFloat xOffset = targetContentOffset->x;
    
    if (fabs(velocity.x) < .7 || !self.pagingEnabled) {
        // stick to nearest section
        NSInteger section = roundf(targetContentOffset->x / self.dayColumnSize.width);
        xOffset = section * self.dayColumnSize.width;
        self.scrollTargetDate = [self dateFromDayOffset:section];
    }
    else if (self.pagingEnabled) {
        NSDate *date;
        
        // scroll to next page
        if (velocity.x > 0) {
            date = [self nextDateForPagingAfterDate:self.visibleDays.start];
         }
        // scroll to previous page
        else {
            date = [self prevDateForPagingBeforeDate:self.firstVisibleDate];
        }
        NSInteger section = [self dayOffsetFromDate:date];
        xOffset = [self xOffsetFromDayOffset:section];
        self.scrollTargetDate = [self dateFromDayOffset:section];
    }
        
    xOffset = fminf(fmax(xOffset, 0), scrollView.contentSize.width - scrollView.bounds.size.width);
    targetContentOffset->x = xOffset;
}


- (void)scrollViewDidEndDragging:(UIScrollView*)scrollView willDecelerate:(BOOL)decelerate
{
	//NSLog(@"scrollViewDidEndDragging decelerate: %d", decelerate);
	
	// (decelerate = NO and scrollView.decelerating = YES) means that a second scroll operation
	// started on the same scrollview while decelerating.
	// in that (rare) case, don't end up the operation, which could mess things up.
	// ex: swipe vertically and soon after swipe forward
	
	if (!decelerate && !scrollView.decelerating) {
		[self scrollViewDidEndScrolling:scrollView];
	}

    if (decelerate) {
        [[UIDevice currentDevice]endGeneratingDeviceOrientationNotifications];
    }
}

- (void)scrollViewDidEndDecelerating:(UIScrollView*)scrollView
{
	//NSLog(@"scrollViewDidEndDecelerating");

	[self scrollViewDidEndScrolling:scrollView];
    
    [[UIDevice currentDevice]beginGeneratingDeviceOrientationNotifications];
}

- (void)scrollViewDidEndScrollingAnimation:(UIScrollView*)scrollView
{
	//NSLog(@"scrollViewDidEndScrollingAnimation");

	[self scrollViewDidEndScrolling:scrollView];
    
    [[UIDevice currentDevice]beginGeneratingDeviceOrientationNotifications];
}


#pragma mark - UICollectionViewDelegateFlowLayout

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
    CGSize dayColumnSize = self.dayColumnSize;
    return CGSizeMake(dayColumnSize.width, self.bounds.size.height);
}

@end
