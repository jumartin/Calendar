//
//  MGCYearCalendarView.m
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

#import "MGCYearCalendarView.h"
#import "MGCYearCalendarMonthCell.h"
#import "MGCMonthMiniCalendarView.h"
#import "MGCYearCalendarMonthHeaderView.h"
#import "NSCalendar+MGCAdditions.h"
#import "Constant.h"


// reuse identifiers for collection view cells and supplementary views
static NSString* const MonthCellReuseIdentifier = @"MonthCellReuseIdentifier";
static NSString* const YearHeaderReuseIdentifier = @"YearHeaderReuseIdentifier";

static const NSUInteger kYearsLoadingStep = 10;			// number of years in a loaded page = 2 * kYearsLoadingStep  + 1
static const CGFloat kCellMinimumSpacing = 25;			// minimum distance between month cells
static const CGFloat kDefaultDayFontSize = 13;			// default font size for the day ordinals
static const CGFloat kDefaultMonthHeaderFontSize = 20;	// default font size for the month headers
static const CGFloat kDefaultYearHeaderFontSize = 40;	// deafult font size for the year headers

static const CGFloat kCellMinimumSpacingiPhone = 0;			// minimum distance between month cells
static const CGFloat kDefaultDayFontSizeiPhone = 7;			// default font size for the day ordinals
static const CGFloat kDefaultMonthHeaderFontSizeiPhone = 12;	// default font size for the month headers
static const CGFloat kDefaultYearHeaderFontSizeiPhone = 20;	// deafult font size for the year headers


// forward declaration needed by YearEventsView
@interface MGCYearCalendarView(Scrolling)

- (BOOL)reloadCollectionViewIfNeeded;



@end


// YearEventsView: this is needed for infinite scrolling.
// It seems we only need this subclass of UICollectionView in iOS 6.
// With iOS 7, we can use delegate scrollView:didScroll to recenter the content and adjust the offset.
// In iOS 6, this causes mad (too fast) scrolling! Overriding layoutSubviews works though.
@interface YearEventsView : UICollectionView

@property (nonatomic) MGCYearCalendarView *yearView;

@end

@implementation YearEventsView

- (void)layoutSubviews
{
    [super layoutSubviews];
    [self.yearView reloadCollectionViewIfNeeded];
}

@end


#pragma mark -

@interface MGCYearCalendarView ()<UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, MGCMonthMiniCalendarViewDelegate>

@property (nonatomic, readonly) YearEventsView *eventsView;		// collection view
@property (nonatomic, copy) NSDate *startDate;					// first loaded day in the views (always set to the first day of the year)
@property (nonatomic) NSDate *maxStartDate;						// maximum date for the start of a loaded page of the collection view - set with dateRange, nil for infinite scrolling
@property (nonatomic) NSDateFormatter *dateFormatter;			// used to format month and year headers

@end


@implementation MGCYearCalendarView

// readonly properties whose getter's defined are not auto-synthesized
@synthesize eventsView = _eventsView;

#pragma mark - Initialization

- (void)setup
{
    _calendar = [NSCalendar currentCalendar];
    _startDate = [_calendar mgc_startOfYearForDate:[NSDate date]];
    _dateFormatter = [NSDateFormatter new];
    _dateFormatter.calendar = _calendar;
    if (isiPad) {
        //NSLog(@"---------------- iPAD ------------------");
        _daysFont = [UIFont systemFontOfSize:kDefaultDayFontSize];
        _headerFont = [UIFont boldSystemFontOfSize:kDefaultMonthHeaderFontSize];
    }
    else{
        //NSLog(@"---------------- iPhone ------------------");
        _daysFont = [UIFont systemFontOfSize:kDefaultDayFontSizeiPhone];
        _headerFont = [UIFont boldSystemFontOfSize:kDefaultMonthHeaderFontSizeiPhone];
    }
    
    
    self.backgroundColor = [UIColor clearColor];
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    if (self = [super initWithCoder:aDecoder])
    {
        [self setup];
    }
    return self;
}

- (id)initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame])
    {
        [self setup];
    }
    return self;
}

- (void)setCalendar:(NSCalendar *)calendar
{
    _calendar = calendar;
    
}

#pragma mark - Properties

- (UICollectionViewFlowLayout*)layout
{
    return (UICollectionViewFlowLayout*)self.eventsView.collectionViewLayout;
}

- (void)setDateRange:(MGCDateRange *)dateRange
{
    // nil dateRange means 'inifinite' scrolling
    if (dateRange == nil)
    {
        _dateRange = nil;
        self.maxStartDate = nil;
        return;
    }
    
    // adjust start and end date on year boundaries (always first day of year)
    NSDate *start = [self.calendar mgc_startOfYearForDate:dateRange.start];
    
    NSDateComponents *comps = [NSDateComponents new];
    comps.year = 1;
    NSDate *end = [self.calendar dateByAddingComponents:comps toDate:[self.calendar mgc_startOfYearForDate:dateRange.end] options:0];
    
    _dateRange = [MGCDateRange dateRangeWithStart:start end:end];
    
    // calc max start date
    comps.year = -(2 * kYearsLoadingStep + 1);
    self.maxStartDate = [self.calendar dateByAddingComponents:comps toDate:_dateRange.end options:0];
    if ([self.maxStartDate compare:_dateRange.start] == NSOrderedAscending)
        self.maxStartDate = _dateRange.start;
    
    // adjust startDate if not in new range
    if (![_dateRange containsDate:self.startDate])
        self.startDate = _dateRange.start;
    
    // reload ?
}

- (MGCDateRange*)visibleMonthsRange
{
    MGCDateRange *range = nil;
    
    NSArray *visible = [[self.eventsView indexPathsForVisibleItems]sortedArrayUsingSelector:@selector(compare:)];
    if (visible.count)
    {
        NSDate *first = [self dateForIndexPath:[visible firstObject]];
        NSDate *last = [self dateForIndexPath:[visible lastObject]];
        
        // end date of the range is excluded, so set it to next month
        NSDateComponents *comps = [NSDateComponents new];
        comps.month = 1;
        last = [self.calendar dateByAddingComponents:comps toDate:last options:0];
        
        range = [MGCDateRange dateRangeWithStart:first end:last];
    }
    
    return range;
}


#pragma mark - Utilities

- (NSDate*)dateForIndexPath:(NSIndexPath*)indexPath
{
    NSDateComponents *comp = [NSDateComponents new];
    comp.year = indexPath.section;
    comp.month = indexPath.item;
    return [self.calendar dateByAddingComponents:comp toDate:self.startDate options:0];
}

- (NSInteger)numberOfMonthsForYearAtIndex:(NSInteger)year
{
    NSDate *date = [self dateForIndexPath:[NSIndexPath indexPathForItem:0 inSection:year]];
    return [self.calendar rangeOfUnit:NSCalendarUnitMonth inUnit:NSCalendarUnitYear forDate:date].length;
}

- (CGRect)rectForYearAtIndex:(NSUInteger)year
{
    NSIndexPath *first = [NSIndexPath indexPathForItem:0 inSection:year];
    
    CGFloat top = [self.eventsView layoutAttributesForSupplementaryElementOfKind:UICollectionElementKindSectionHeader atIndexPath:first].frame.origin.y;
    
    NSDate *date = [self dateForIndexPath:first];
    NSUInteger lastMonth = [self.calendar rangeOfUnit:NSCalendarUnitMonth inUnit:NSCalendarUnitYear forDate:date].length - 1;
    
    NSIndexPath *last = [NSIndexPath indexPathForItem:lastMonth inSection:year];
    CGFloat bottom = CGRectGetMaxY([self.eventsView layoutAttributesForItemAtIndexPath:last].frame) + self.layout.sectionInset.bottom;
    
    return CGRectMake(0, top, self.bounds.size.width, bottom - top);
}

- (NSAttributedString*)headerTextForMonthAtIndexPath:(NSIndexPath*)indexPath
{
    NSDate *date = [self dateForIndexPath:indexPath];
    
    if ([self.delegate respondsToSelector:@selector(calendarYearView:headerTextForMonthAtDate:)])
    {
        return [self.delegate calendarYearView:self headerTextForMonthAtDate:date];
    }
    else
    {
        self.dateFormatter.dateFormat = @"MMMM";
        NSString *dateStr = [[self.dateFormatter stringFromDate:date]uppercaseString];
        return [[NSAttributedString alloc]initWithString:dateStr attributes:@{ NSFontAttributeName:self.headerFont }];
    }
}

#pragma mark - Public

- (NSDate*)dateForMonthAtPoint:(CGPoint)pt
{
    pt = [self.eventsView convertPoint:pt fromView:self];
    NSIndexPath *path = [self.eventsView indexPathForItemAtPoint:pt];
    if (path)
    {
        return [self dateForIndexPath:path];
    }
    return nil;
}

-(void)scrollToDate:(NSDate*)date animated:(BOOL)animated
{
    // check if date in range
    if (self.dateRange && ![self.dateRange containsDate:date])
        [NSException raise:@"Invalid parameter" format:@"date %@ is not in range %@ for this calendar view", date, self.dateRange];
    
    NSDate *firstInYear = [self.calendar mgc_startOfYearForDate:date];
    
    // calc new startDate
    NSInteger diff = [self adjustStartDate:firstInYear byNumberOfYears:-kYearsLoadingStep];
    
    [self.eventsView reloadData];
    
    NSIndexPath *top = [NSIndexPath indexPathForItem:0 inSection:diff];
    [self.eventsView scrollToItemAtIndexPath:top atScrollPosition:UICollectionViewScrollPositionTop animated:animated];
    
    if ([self.delegate respondsToSelector:@selector(calendarYearViewDidScroll:)])
    {
        [self.delegate calendarYearViewDidScroll:self];
    }
}

#pragma mark - Scrolling

// adjusts startDate by offsetting date by given years within calendar date range.
// returns the distance in years between date and new start.
- (NSUInteger)adjustStartDate:(NSDate*)date byNumberOfYears:(NSInteger)years
{
	NSDateComponents *comps = [NSDateComponents new];
	comps.year = years;
	NSDate *start = [self.calendar dateByAddingComponents:comps toDate:date options:0];
	
	if ([start compare:self.dateRange.start] == NSOrderedAscending)
	{
		start = self.dateRange.start;
	}
	else if ([start compare:self.maxStartDate] == NSOrderedDescending)
	{
		start = self.maxStartDate;
	}
	
	NSUInteger diff = abs((int)[self.calendar components:NSCalendarUnitYear fromDate:start toDate:date options:0].year);
	
	self.startDate = start;
	return diff;
}

// returns new corresponding offset
- (CGFloat)reloadForTargetContentOffset:(CGFloat)yOffset
{
    CGFloat newYOffset = yOffset;
    
    NSUInteger diff;
    if (yOffset < 0)
    {
        if ((diff = [self adjustStartDate:self.startDate byNumberOfYears:-kYearsLoadingStep]) != 0)
        {
            [self.eventsView reloadData];
            // strangely, layout is not invalidated immediately.
            // we have to call prepareLayout ourselves, otherwise layoutAttributesForItemAtIndexPath: will fail (in rectForYearAtIndex:)
            [self.layout invalidateLayout];
            [self.layout prepareLayout];
            newYOffset = [self rectForYearAtIndex:diff].origin.y + yOffset;
        }
    }
    else if (CGRectGetMaxY(self.eventsView.bounds))
    {
        if ((diff = [self adjustStartDate:self.startDate byNumberOfYears:kYearsLoadingStep]) != 0)
        {
            newYOffset = yOffset - [self rectForYearAtIndex:diff].origin.y;
            [self.eventsView reloadData];
        }
    }
    return newYOffset;
}

// returns YES if collection views were reloaded
- (BOOL)reloadCollectionViewIfNeeded
{
    CGPoint contentOffset = self.eventsView.contentOffset;
    
    if (contentOffset.y < 0.0f || CGRectGetMaxY(self.eventsView.bounds) > self.eventsView.contentSize.height)
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
    if (!_eventsView)
    {
        UICollectionViewFlowLayout *layout = [UICollectionViewFlowLayout new];
        layout.scrollDirection = UICollectionViewScrollDirectionVertical;
        
        _eventsView = [[YearEventsView alloc]initWithFrame:CGRectZero collectionViewLayout:layout];
        _eventsView.yearView = self;
        _eventsView.backgroundColor = [UIColor whiteColor];
        _eventsView.dataSource = self;
        _eventsView.delegate = self;
        _eventsView.showsVerticalScrollIndicator = NO;
        _eventsView.scrollsToTop = NO;
        if(isiPad) {
            //NSLog(@"---------------- iPAD ------------------");
            _eventsView.contentInset = UIEdgeInsetsMake(0, 60, 0, 60);
        }
        else{
            //NSLog(@"---------------- iPhone ------------------");
            _eventsView.contentInset = UIEdgeInsetsMake(0, 0, 0, 0);
        }
        
        
        [_eventsView registerClass:MGCYearCalendarMonthCell.class forCellWithReuseIdentifier:MonthCellReuseIdentifier];
        [_eventsView registerClass:MGCYearCalendarMonthHeaderView.class forSupplementaryViewOfKind:UICollectionElementKindSectionHeader withReuseIdentifier:YearHeaderReuseIdentifier];
    }
    return _eventsView;
}

#pragma mark - UIView

- (void)layoutSubviews
{
    self.eventsView.frame = CGRectMake(0, 0, self.bounds.size.width, self.bounds.size.height);
    
    MGCMonthMiniCalendarView *cal = [MGCMonthMiniCalendarView new];
    cal.calendar = self.calendar;
    cal.daysFont = self.daysFont;
    cal.headerText = [self headerTextForMonthAtIndexPath:[NSIndexPath indexPathForItem:0 inSection:0]];
    CGSize cellSize =  [cal preferredSizeYearWise:YES];
    
    self.layout.itemSize = cellSize;
    
    if (isiPad) {
        //NSLog(@"---------------- iPAD ------------------");
        self.layout.sectionInset = UIEdgeInsetsMake(10, 0, 50, 0);
        self.layout.minimumInteritemSpacing = kCellMinimumSpacing;
        self.layout.minimumLineSpacing = kCellMinimumSpacing;
    }
    else{
        //NSLog(@"---------------- iPhone ------------------");
        self.layout.sectionInset = UIEdgeInsetsMake(0, 0, 0, 0);
        self.layout.minimumInteritemSpacing = kCellMinimumSpacingiPhone;
        self.layout.minimumLineSpacing = kCellMinimumSpacingiPhone;
    }
    
    
    
    
    self.layout.headerReferenceSize = CGSizeMake(self.bounds.size.width, 60);
    if ([self.delegate respondsToSelector:@selector(heightForYearHeaderInCalendarYearView:)])
    {
        CGFloat height = [self.delegate heightForYearHeaderInCalendarYearView:self];
        self.layout.headerReferenceSize = CGSizeMake(0, height);
    }
    
    if (!self.eventsView.superview)
    {
        [self addSubview:self.eventsView];
    }
}

#pragma mark - UICollectionViewDataSource

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView*)collectionView
{
	NSInteger numSections = 2 * kYearsLoadingStep + 1;
	if (self.dateRange)
	{
		NSInteger diff = [self.calendar components:NSCalendarUnitYear fromDate:self.startDate toDate:self.dateRange.end options:0].year;
		if (diff < 3 * kYearsLoadingStep + 1)
			numSections = diff;
	}
	return numSections;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return [self numberOfMonthsForYearAtIndex:section];
}

- (UICollectionViewCell*)collectionView:(UICollectionView*)collectionView cellForItemAtIndexPath:(NSIndexPath*)indexPath
{
    NSDate *date = [self dateForIndexPath:indexPath];
    
    MGCYearCalendarMonthCell* cell = [self.eventsView dequeueReusableCellWithReuseIdentifier:MonthCellReuseIdentifier forIndexPath:indexPath];
    
    cell.calendarView.calendar = self.calendar;
    cell.calendarView.date = date;
    cell.calendarView.daysFont = self.daysFont;
    cell.calendarView.delegate = self;
    cell.calendarView.headerText = [self headerTextForMonthAtIndexPath:indexPath];
    
    cell.calendarView.highlightedDays = nil;
    if ([self.calendar mgc_isDate:date sameMonthAsDate:[NSDate date]])
    {
        NSUInteger i = [self.calendar components:NSCalendarUnitDay fromDate:date toDate:[NSDate date] options:0].day + 1;
        cell.calendarView.highlightedDays = [NSIndexSet indexSetWithIndex:i];
        cell.calendarView.highlightColor = [UIColor redColor];
    }
    
    [cell.calendarView setNeedsDisplay];
    return cell;
}

- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath
{
    UICollectionReusableView *reusableview = nil;
    
    if (kind == UICollectionElementKindSectionHeader)
    {
        MGCYearCalendarMonthHeaderView *headerView = [collectionView dequeueReusableSupplementaryViewOfKind:UICollectionElementKindSectionHeader withReuseIdentifier:YearHeaderReuseIdentifier forIndexPath:indexPath];
        
        NSDate *date = [self dateForIndexPath:indexPath];
        if ([self.delegate respondsToSelector:@selector(calendarYearView:headerTextForYearAtDate:)])
        {
            NSAttributedString *str = [self.delegate calendarYearView:self headerTextForYearAtDate:date];
            headerView.label.attributedText = str;
        }
        else
        {
            self.dateFormatter.dateFormat = @"yyyy";
            NSString *str = [self.dateFormatter stringFromDate:date];
            if (isiPad) {
                //NSLog(@"---------------- iPAD ------------------");
                headerView.label.font = [UIFont systemFontOfSize:kDefaultYearHeaderFontSize];
            }
            else{
                //NSLog(@"---------------- iPhone ------------------");
                headerView.label.font = [UIFont systemFontOfSize:kDefaultYearHeaderFontSizeiPhone];
            }
            headerView.label.text = str;
        }
        
        [headerView setNeedsDisplay];
        reusableview = headerView;
    }
    
    return reusableview;
}

#pragma mark - UICollectionViewDelegateFlowLayout


- (void)scrollViewDidScroll:(UIScrollView*)scrollview
{
    if ([self.delegate respondsToSelector:@selector(calendarYearViewDidScroll:)])
    {
        [self.delegate calendarYearViewDidScroll:self];
    }
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    if ([self.delegate respondsToSelector:@selector(calendarYearView:didSelectMonthAtDate:)])
    {
        NSDate *date = [self dateForIndexPath:indexPath];
        [self.delegate calendarYearView:self didSelectMonthAtDate:date];
    }
}

#pragma mark - MonthCalendarDelegate

//- (UIColor*)monthCalendar:(MonthCalendar*)calendar backgroundColorForDayAtIndex:(NSUInteger)index
//{
//	return [UIColor yellowColor];
//}

@end
