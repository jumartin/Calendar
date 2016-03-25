//
//  MGCMonthPlannerEKViewController.m
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

#import <EventKitUI/EventKitUI.h>

#import "MGCMonthPlannerEKViewController.h"
#import "MGCStandardEventView.h"
#import "NSCalendar+MGCAdditions.h"
#import "OSCache.h"
#import "MGCEventKitSupport.h"


static NSString* const EventCellReuseIdentifier = @"EventCellReuseIdentifier";


@interface MGCMonthPlannerEKViewController ()<UINavigationControllerDelegate, EKEventEditViewDelegate, EKEventViewDelegate>

@property (nonatomic) MGCEventKitSupport *eventKitSupport;
@property (nonatomic) NSCache *cachedMonths;						// cache of events:  { month_startDate: { day: [events] } }
@property (nonatomic) dispatch_queue_t bgQueue;						// dispatch queue for loading events
@property (nonatomic) NSMutableOrderedSet *datesForMonthsToLoad;	// dates for months of which we want to load events
@property (nonatomic) MGCDateRange *visibleMonths;					// range of months currently shown
@property (nonatomic) EKEvent *movedEvent;
@property (nonatomic) NSDateFormatter *dateFormatter;

@end


@implementation MGCMonthPlannerEKViewController

// designated initializer
- (instancetype)initWithEventStore:(EKEventStore*)eventStore
{
    if (self = [super initWithNibName:nil bundle:nil]) {
        _eventKitSupport = [[MGCEventKitSupport alloc]initWithEventStore:eventStore];
        
    }
    return self;
}

- (void)reloadEvents
{
    [self.cachedMonths removeAllObjects];
    [self loadEventsIfNeeded];
}

- (void)showEditControllerForEventAtIndex:(NSUInteger)index date:(NSDate*)date rect:(CGRect)rect
{
    EKEvent *ev = [self eventAtIndex:index date:date];
    if (!ev) return;
    
    MGCEKEventViewController *eventController = [MGCEKEventViewController new];
    eventController.event = ev;
    eventController.delegate = self;
    eventController.allowsEditing = YES;
    eventController.allowsCalendarPreview = YES;
        
    UINavigationController *nc = nil;
//    if ([self.delegate respondsToSelector:@selector(dayPlannerEKViewController:navigationControllerForPresentingEventViewController:)]) {
//        nc = [self.delegate dayPlannerEKViewController:self navigationControllerForPresentingEventViewController:eventController];
//    }
//    
    if (nc) {
        [nc pushViewController:eventController animated:YES];
    }
    else {
        nc = [[UINavigationController alloc]initWithRootViewController:eventController];
        nc.modalPresentationStyle = UIModalPresentationPopover;
        eventController.presentationController.delegate = self;
        
        [self showDetailViewController:nc sender:self];
        
        //CGRect visibleRect = CGRectIntersection(self.monthPlannerView.bounds, [self.monthPlannerView convertRect:view.bounds fromView:view]);
        UIPopoverPresentationController *popController = nc.popoverPresentationController;
        popController.permittedArrowDirections = UIPopoverArrowDirectionLeft|UIPopoverArrowDirectionRight;
        popController.delegate = self;
        popController.sourceView = self.monthPlannerView;
        popController.sourceRect = rect;
    }
}

- (void)showPopoverForNewEvent:(EKEvent*)ev withCell:(MGCEventView*)cell
{
    EKEventEditViewController *eventController = [EKEventEditViewController new];
    eventController.event = ev;
    eventController.eventStore = self.eventStore;
    eventController.editViewDelegate = self; // called only when event is deleted
    eventController.modalInPopover = YES;
    eventController.modalPresentationStyle = UIModalPresentationPopover;
    eventController.presentationController.delegate = self;
    
    [self showDetailViewController:eventController sender:self];
    
    UIPopoverPresentationController *popController = eventController.popoverPresentationController;
    popController.permittedArrowDirections = UIPopoverArrowDirectionLeft|UIPopoverArrowDirectionRight;
    popController.delegate = self;
    popController.sourceView = cell;
    popController.sourceRect = cell.bounds;
}

#pragma mark - UIViewController

- (id)initWithNibName:(NSString*)nibNameOrNil bundle:(NSBundle*)nibBundleOrNil
{
    return [self initWithEventStore:nil];
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter]removeObserver:self];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(reloadEvents) name:EKEventStoreChangedNotification object:self.eventStore];
    
    self.cachedMonths = [[OSCache alloc]init];
    
    self.bgQueue = dispatch_queue_create("MGCMonthPlannerEKViewController.bgQueue", NULL);
    
    self.dateFormatter = [NSDateFormatter new];
    self.dateFormatter.dateStyle = NSDateFormatterNoStyle;
    self.dateFormatter.timeStyle = NSDateFormatterShortStyle;
    
    [self.eventKitSupport checkEventStoreAccessForCalendar:^(BOOL granted) {
        if (granted) {
            NSArray *calendars = [self.eventStore calendarsForEntityType:EKEntityTypeEvent];
            self.visibleCalendars = [NSSet setWithArray:calendars];
            [self reloadEvents];
        }
    }];
    
    self.monthPlannerView.calendar = self.calendar;
    [self.monthPlannerView registerClass:MGCStandardEventView.class forEventCellReuseIdentifier:EventCellReuseIdentifier];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    [self loadEventsIfNeeded];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // nothing special to do here, the cache of events cachedMonths will clear by itself.
}

#pragma mark - Properties


- (void)setCalendar:(NSCalendar *)calendar
{
    _calendar = calendar;
    self.dateFormatter.calendar = calendar;
    self.monthPlannerView.calendar = calendar;
}

- (EKEventStore*)eventStore
{
    return self.eventKitSupport.eventStore;
}

- (void)setVisibleCalendars:(NSSet*)visibleCalendars
{
    _visibleCalendars = visibleCalendars;
    [self.monthPlannerView reloadEvents];
}

#pragma mark - Events loading

- (NSArray*)eventsAtDate:(NSDate*)date
{
    NSDate *firstOfMonth = [self.calendar mgc_startOfMonthForDate:date];
    NSMutableDictionary *days = [self.cachedMonths objectForKey:firstOfMonth];
    
    NSPredicate *pred = [NSPredicate predicateWithBlock:^BOOL(EKEvent *ev, NSDictionary *bindings) {
        return [self.visibleCalendars containsObject:ev.calendar];
    }];
    
    NSArray *events = [[days objectForKey:date]filteredArrayUsingPredicate:pred];
    
    return events;
}

- (EKEvent*)eventAtIndex:(NSUInteger)index date:(NSDate*)date
{
    NSArray *events = [self eventsAtDate:date];
    EKEvent *ev = [events objectAtIndex:index];
    return ev;
}

- (MGCDateRange*)visibleMonthsRange
{
    MGCDateRange *visibleMonthsRange = nil;
    
    MGCDateRange *visibleDaysRange = [self.monthPlannerView visibleDays];
    if (visibleDaysRange) {
        NSDate *start = [self.calendar mgc_startOfMonthForDate:visibleDaysRange.start];
        NSDate *end = [self.calendar mgc_nextStartOfMonthForDate:visibleDaysRange.end];
        visibleMonthsRange = [MGCDateRange dateRangeWithStart:start end:end];
    }
    
    return visibleMonthsRange;
}

// returns an array of all events happening between startDate and endDate, sorted by start date
- (NSArray*)fetchEventsFrom:(NSDate*)startDate to:(NSDate*)endDate calendars:(NSArray*)calendars
{
    NSPredicate *predicate = [self.eventStore predicateForEventsWithStartDate:startDate endDate:endDate calendars:calendars];
    
    if (self.eventKitSupport.accessGranted) {
        NSArray *events = [self.eventStore eventsMatchingPredicate:predicate];
        if (events) {
            return [events sortedArrayUsingSelector:@selector(compareStartDateWithEvent:)];
        }
    }
    
    return [NSArray array];
}

- (NSDictionary*)allEventsInDateRange:(MGCDateRange*)range
{
	NSArray *events = [self fetchEventsFrom:range.start to:range.end calendars:nil];
	
	NSUInteger numDaysInRange = [range components:NSCalendarUnitDay forCalendar:self.calendar].day;
	NSMutableDictionary *eventsPerDay = [NSMutableDictionary dictionaryWithCapacity:numDaysInRange];
	
	for (EKEvent *ev in events)
	{
		NSDate *start = [self.calendar mgc_startOfDayForDate:ev.startDate];
		MGCDateRange *eventRange = [MGCDateRange dateRangeWithStart:start end:ev.endDate];
		[eventRange intersectDateRange:range];
		
		[eventRange enumerateDaysWithCalendar:self.calendar usingBlock:^(NSDate *date, BOOL *stop){
			NSMutableArray *events = [eventsPerDay objectForKey:date];
			if (!events) {
				events = [NSMutableArray array];
				[eventsPerDay setObject:events forKey:date];
			}
			
			[events addObject:ev];
		}];
	}
	
	return eventsPerDay;
}

//- (void)cacheEvents:(NSDictionary*)events forMonthStartingAtDate:(NSDate*)date
//{
//	[self.cachedMonths setObject:events forKey:date];
//	//[self.datesForMonthsToLoad removeObject:date];
//	
//	NSDate *rangeEnd = [self.calendar mgc_nextStartOfMonthForDate:date];
//	MGCDateRange *range = [MGCDateRange dateRangeWithStart:date end:rangeEnd];
//	[self.monthPlannerView reloadEventsInRange:range];
//}

- (void)bg_loadMonthStartingAtDate:(NSDate*)date
{
    NSDate *end = [self.calendar mgc_nextStartOfMonthForDate:date];
    MGCDateRange *range = [MGCDateRange dateRangeWithStart:date end:end];
    
    NSDictionary *dic = [self allEventsInDateRange:range];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        
        [self.cachedMonths setObject:dic forKey:date];
        //[self.datesForMonthsToLoad removeObject:date];
        
        NSDate *rangeEnd = [self.calendar mgc_nextStartOfMonthForDate:date];
        MGCDateRange *range = [MGCDateRange dateRangeWithStart:date end:rangeEnd];
        [self.monthPlannerView reloadEventsInRange:range];
        
        //[self cacheEvents:dic forMonthStartingAtDate:date];
    });
}

- (void)bg_loadOneMonth
{
    __block NSDate *date;
    
    dispatch_sync(dispatch_get_main_queue(), ^{
        date = [self.datesForMonthsToLoad firstObject];
        if (date) {
            [self.datesForMonthsToLoad removeObject:date];
        }
        
        if (![self.monthPlannerView.visibleDays intersectsDateRange:self.visibleMonths]) {
            date = nil;
        }
    });
    
    if (date) {
        [self bg_loadMonthStartingAtDate:date];
    }
}

- (void)addMonthToLoadingQueue:(NSDate*)monthStart
{
    if (!self.datesForMonthsToLoad) {
        self.datesForMonthsToLoad = [NSMutableOrderedSet orderedSet];
    }
    
    [self.datesForMonthsToLoad addObject:monthStart];
    
    dispatch_async(self.bgQueue, ^{ [self bg_loadOneMonth]; });
}

- (void)loadEventsIfNeeded
{
	[self.datesForMonthsToLoad removeAllObjects];
	
	MGCDateRange *visibleRange = [self visibleMonthsRange];
	
	NSUInteger months = [visibleRange components:NSCalendarUnitMonth forCalendar:self.calendar].month;
	
	for (int i = 0; i < months; i++)
	{
		NSDateComponents *dc = [NSDateComponents new];
		dc.month = i;
		NSDate *date = [self.calendar dateByAddingComponents:dc toDate:visibleRange.start options:0];
		
		if (![self.cachedMonths objectForKey:date])
			[self addMonthToLoadingQueue:date];
	}
}

#pragma mark - MGCMonthPlannerViewDataSource

- (NSInteger)monthPlannerView:(MGCMonthPlannerView*)view numberOfEventsAtDate:(NSDate*)date
{
    NSUInteger count = [[self eventsAtDate:date]count];
    return count;
}

- (MGCDateRange*)monthPlannerView:(MGCMonthPlannerView *)view dateRangeForEventAtIndex:(NSUInteger)index date:(NSDate *)date
{
    NSArray *events = [self eventsAtDate:date];
    EKEvent *ev = [events objectAtIndex:index];
    
    MGCDateRange *range = nil;
    if (ev)
    {
        range = [MGCDateRange dateRangeWithStart:ev.startDate end:ev.endDate];
    }
    
    return range;
}

- (MGCEventView*)monthPlannerView:(MGCMonthPlannerView*)view cellForEventAtIndex:(NSUInteger)index date:(NSDate *)date
{
	NSArray *events = [self eventsAtDate:date];
	EKEvent *ev = [events objectAtIndex:index];
	
	MGCStandardEventView *evCell = nil;
	if (ev)
	{
		evCell = (MGCStandardEventView*)[view dequeueReusableCellWithIdentifier:EventCellReuseIdentifier forEventAtIndex:index date:date];
		evCell.title = ev.title;
		evCell.subtitle = ev.location;
		evCell.detail = [self.dateFormatter stringFromDate:ev.startDate];
		evCell.color = [UIColor colorWithCGColor:ev.calendar.CGColor];
		
		NSDate *start = [self.calendar mgc_startOfDayForDate:ev.startDate];
		NSDate *end = [self.calendar mgc_nextStartOfDayForDate:ev.endDate];
		MGCDateRange *range = [MGCDateRange dateRangeWithStart:start end:end];
		NSInteger numDays = [range components:NSCalendarUnitDay forCalendar:self.calendar].day;
		
		evCell.style = (ev.isAllDay || numDays > 1 ? MGCStandardEventViewStylePlain : MGCStandardEventViewStyleDefault|MGCStandardEventViewStyleDot);
		evCell.style |= ev.isAllDay ?: MGCStandardEventViewStyleDetail;
	}
	return evCell;
}

- (BOOL)monthPlannerView:(MGCMonthPlannerView*)view canMoveCellForEventAtIndex:(NSUInteger)index date:(NSDate*)date
{
    NSArray *events = [self eventsAtDate:date];
    EKEvent *ev = [events objectAtIndex:index];
    return (ev.calendar.allowsContentModifications);
}

- (MGCEventView*)monthPlannerView:(MGCMonthPlannerView*)view cellForNewEventAtDate:(NSDate*)date
{
    EKCalendar *defaultCalendar = [self.eventStore defaultCalendarForNewEvents];
    
    MGCStandardEventView *evCell = [MGCStandardEventView new];
    evCell.title = NSLocalizedString(@"New Event", nil);
    evCell.color = [UIColor colorWithCGColor:defaultCalendar.CGColor];
    return evCell;
}

#pragma mark - MGCMonthPlannerViewDelegate

- (void)monthPlannerViewDidScroll:(MGCMonthPlannerView *)view
{
    MGCDateRange *visibleMonths = [self visibleMonthsRange];
    
    if (![visibleMonths isEqual:self.visibleMonths]) {
        self.visibleMonths = visibleMonths;
        [self loadEventsIfNeeded];
    }
}

- (void)monthPlannerView:(MGCMonthPlannerView*)view didSelectEventAtIndex:(NSUInteger)index date:(NSDate *)date
{
    MGCEventView *cell = [view cellForEventAtIndex:index date:date];
    if (cell) {
        CGRect rect = [view convertRect:cell.bounds fromView:cell];
        [self showEditControllerForEventAtIndex:index date:date rect:rect];
    }
}

- (void)monthPlannerView:(MGCMonthPlannerView*)view didDeselectEventAtIndex:(NSUInteger)index date:(NSDate *)date
{
}

- (void)monthPlannerView:(MGCMonthPlannerView*)view didSelectDayCellAtDate:(NSDate *)date
{
    NSLog(@"selected day at : %@", date);
}

- (void)monthPlannerView:(MGCMonthPlannerView*)view didShowCell:(MGCEventView*)cell forNewEventAtDate:(NSDate*)date
{
    EKEvent *ev = [EKEvent eventWithEventStore:self.eventStore];
    ev.startDate = date;
    ev.endDate = date;
    ev.allDay = YES;
    
    [self showPopoverForNewEvent:ev withCell:cell];
}

- (void)monthPlannerView:(MGCMonthPlannerView*)view willStartMovingEventAtIndex:(NSUInteger)index date:(NSDate*)date
{
    EKEvent *ev = [self eventAtIndex:index date:date];
    NSAssert(ev, @"Can't find event at index %lu date %@", (unsigned long)index, date);
    self.movedEvent = ev;
}

- (void)monthPlannerView:(MGCMonthPlannerView*)view didMoveEventAtIndex:(NSUInteger)index date:(NSDate*)dateOld toDate:(NSDate*)dateNew
{
    NSAssert(self.movedEvent, @"moved event is nil !");
    
    NSDateComponents *comp = [self.calendar components:NSCalendarUnitMinute fromDate:self.movedEvent.startDate toDate:self.movedEvent.endDate options:0];
    NSDate *endNew = [self.calendar dateByAddingComponents:comp toDate:dateNew options:0];
    
    self.movedEvent.startDate = dateNew;
    self.movedEvent.endDate = endNew;
    
    //NSLog(@"will move ev from %@ to %@", dateOld, dateNew);
    [self.eventKitSupport saveEvent:self.movedEvent completion:^(BOOL completion) {
        [self.monthPlannerView endInteraction];
    }];
    
    self.movedEvent = nil;
    
    [self.monthPlannerView endInteraction];
}

#pragma mark - EKEventEditViewDelegate

- (void)eventEditViewController:(EKEventEditViewController *)controller didCompleteWithAction:(EKEventEditViewAction)action
{
    [self dismissViewControllerAnimated:YES completion:nil];
    [self.monthPlannerView endInteraction];
}

#pragma mark - EKEventViewDelegate

- (void)eventViewController:(EKEventViewController *)controller didCompleteWithAction:(EKEventViewAction)action
{
    [self.monthPlannerView deselectEvent];
    if (controller.presentingViewController) {
        [self dismissViewControllerAnimated:YES completion:nil];
    } else {
        [controller.navigationController popViewControllerAnimated:YES];
    }
}

#pragma mark - UIPopoverPresentationControllerDelegate

//- (UIViewController*)presentationController:(UIPresentationController *)controller viewControllerForAdaptivePresentationStyle:(UIModalPresentationStyle)style
//{
//    if ([controller.presentedViewController isKindOfClass:EKEventEditViewController.class]) {
//        return controller.presentedViewController;
//    }
//    else {
//        UINavigationController *nc = [[UINavigationController alloc]initWithRootViewController:controller.presentedViewController];
//        nc.delegate = self;
//        return nc;
//    }
//}

- (void)popoverPresentationController:(UIPopoverPresentationController *)popoverPresentationController willRepositionPopoverToRect:(inout CGRect *)rect inView:(inout UIView *__autoreleasing  _Nonnull *)view
{
    MGCEventView *cell = self.monthPlannerView.selectedEventView;
    if (cell) {
        CGRect newRect = [self.monthPlannerView convertRect:cell.bounds fromView:cell];
        *rect = newRect;
    }
}

- (void)popoverPresentationControllerDidDismissPopover:(UIPopoverPresentationController *)popoverPresentationController
{
    [self.monthPlannerView deselectEvent];
}

#pragma mark - UINavigationControllerDelegate

//- (void)navigationController:(UINavigationController *)navigationController willShowViewController:(UIViewController *)viewController animated:(BOOL)animated
//{
//}

@end
