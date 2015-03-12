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

typedef void(^EventSaveCompletionBlockType)(BOOL);


static NSString* const EventCellReuseIdentifier = @"EventCellReuseIdentifier";


@interface MGCMonthPlannerEKViewController ()<UIPopoverControllerDelegate, UINavigationControllerDelegate, EKEventEditViewDelegate, EKEventViewDelegate>

@property (nonatomic) NSCache *cachedMonths;						// cache of events:  { month_startDate: { day: [events] } }
@property (nonatomic) dispatch_queue_t bgQueue;						// dispatch queue for loading events
@property (nonatomic) NSMutableOrderedSet *datesForMonthsToLoad;	// dates for months of which we want to load events
@property (nonatomic) MGCDateRange *visibleMonths;					// range of months currently shown
@property (nonatomic) NSUInteger selectedEventIndex;				// index of currently selected event cell
@property (nonatomic) NSDate *selectedEventDate;					// date of currently selected event cell
@property (nonatomic) EKEvent *movedEvent;
@property EKEvent* savedEvent;
@property (nonatomic, copy) EventSaveCompletionBlockType saveCompletion;
@property (nonatomic) BOOL accessGranted;
@property (nonatomic) NSDateFormatter *dateFormatter;

@end


@implementation MGCMonthPlannerEKViewController

// designated initializer
- (instancetype)initWithEventStore:(EKEventStore*)eventStore
{
	if (self = [super initWithNibName:nil bundle:nil]) {
		_eventStore = eventStore;
		if (eventStore == nil) {
			_eventStore = [[EKEventStore alloc]init];
		}
		
		[[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(reloadEvents) name:EKEventStoreChangedNotification object:self.eventStore];
		
		_cachedMonths = [[OSCache alloc]init];
		_bgQueue = dispatch_queue_create("MGCMonthPlannerEKViewController.bgQueue", NULL);
		_dateFormatter = [NSDateFormatter new];
		_dateFormatter.dateStyle = NSDateFormatterNoStyle;
		_dateFormatter.timeStyle = NSDateFormatterShortStyle;
		
		[self checkEventStoreAccessForCalendar];
	}
	return self;
}

- (void)reloadEvents
{
	[self.cachedMonths removeAllObjects];
	[self loadEventsIfNeeded];
}

- (void)saveEvent:(EKEvent*)event completion:(void (^)(BOOL saved))completion
{
	if (event.hasRecurrenceRules) {
		self.savedEvent = event;
		self.saveCompletion = completion;
		
		NSString *title = NSLocalizedString(@"This is a repeating event.", nil);
		NSString *msg = NSLocalizedString(@"What do you want to modify?", nil);
		UIAlertView *sheet = [[UIAlertView alloc]initWithTitle:title message:msg delegate:self cancelButtonTitle:NSLocalizedString(@"Cancel", nil) otherButtonTitles:NSLocalizedString(@"This event only", nil), NSLocalizedString(@"All future events", nil), nil];
		
		[sheet show];
	}
	else {
		NSError *error;
		
		BOOL saved = [self.eventStore saveEvent:event span:EKSpanThisEvent commit:YES error:&error];
		if (!saved) {
			NSLog(@"Error - Could not save event: %@", error.description);
		}
		
		if (completion != nil) {
			completion(saved);
		}
		self.saveCompletion = nil;
	}
}

- (void)showEditControllerForEventAtIndex:(NSUInteger)index date:(NSDate*)date rect:(CGRect)rect
{
	EKEvent *ev = [self eventAtIndex:index date:date];
	if (ev)
	{
		EKEventViewController *eventController = [EKEventViewController new];
		eventController.event = ev;
		eventController.delegate = self;
		eventController.allowsEditing = YES;
		eventController.allowsCalendarPreview = YES;
		
		UINavigationController* nc = [[UINavigationController alloc] initWithRootViewController:eventController];
		nc.delegate = self;
		nc.navigationBarHidden = YES;
		
		self.eventPopover = [[UIPopoverController alloc]initWithContentViewController:nc];
		self.eventPopover.delegate = self;
		
		[self.eventPopover presentPopoverFromRect:rect inView:self.monthPlannerView permittedArrowDirections:UIPopoverArrowDirectionAny animated:NO];
	}
}

- (void)showPopoverForNewEvent:(EKEvent*)ev withCell:(MGCEventView*)cell
{
	EKEventEditViewController *eventController = [EKEventEditViewController new];
	eventController.event = ev;
	eventController.eventStore = self.eventStore;
	eventController.editViewDelegate = self; // called only when event is deleted
	eventController.modalInPopover = YES;
	
	self.eventPopover = [[UIPopoverController alloc]initWithContentViewController:eventController];
	self.eventPopover.delegate = self;
	
	[self.eventPopover presentPopoverFromRect:cell.bounds inView:cell permittedArrowDirections:UIPopoverArrowDirectionLeft|UIPopoverArrowDirectionRight animated:NO];
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
	
	if (self.accessGranted) {
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
	
	NSUInteger numDaysInRange = [range components:NSDayCalendarUnit forCalendar:self.calendar].day;
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
	
	NSUInteger months = [visibleRange components:NSMonthCalendarUnit forCalendar:self.calendar].month;
	
	for (int i = 0; i < months; i++)
	{
		NSDateComponents *dc = [NSDateComponents new];
		dc.month = i;
		NSDate *date = [self.calendar dateByAddingComponents:dc toDate:visibleRange.start options:0];
		
		if (![self.cachedMonths objectForKey:date])
			[self addMonthToLoadingQueue:date];
	}
}

#pragma mark - Calendar access authorization

- (void)checkEventStoreAccessForCalendar
{
	EKAuthorizationStatus status = [EKEventStore authorizationStatusForEntityType:EKEntityTypeEvent];
	
	switch (status) {
		case EKAuthorizationStatusAuthorized:
			[self accessGrantedForCalendar];
			break;
			
		case EKAuthorizationStatusNotDetermined:
			[self requestCalendarAccess];
			break;
			
		case EKAuthorizationStatusDenied:
		case EKAuthorizationStatusRestricted:
			[self accessDeniedForCalendar];
	}
}

// Prompt the user for access to their Calendar
- (void)requestCalendarAccess
{
	[self.eventStore requestAccessToEntityType:EKEntityTypeEvent completion:^(BOOL granted, NSError *error) {
		if (granted) {
			MGCMonthPlannerEKViewController * __weak weakSelf = self;
			dispatch_async(dispatch_get_main_queue(), ^{
				[weakSelf accessGrantedForCalendar];
			});
		}
	}];
}

// This method is called when the user has granted permission to Calendar
- (void)accessGrantedForCalendar
{
	self.accessGranted = YES;
	
	NSArray *calendars = [self.eventStore calendarsForEntityType:EKEntityTypeEvent];
	self.visibleCalendars = [NSSet setWithArray:calendars];
	
	[self reloadEvents];
}

- (void)accessDeniedForCalendar
{
	NSString *title = NSLocalizedString(@"Warning", nil);
	NSString *msg = NSLocalizedString(@"Access to the calendar was not authorized", nil);
	UIAlertView *alert = [[UIAlertView alloc] initWithTitle:title message:msg delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
	[alert show];
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
		NSInteger numDays = [range components:NSDayCalendarUnit forCalendar:self.calendar].day;
		
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
	self.selectedEventDate = date;
	self.selectedEventIndex = index;
	
	MGCEventView *cell = [view cellForEventAtIndex:index date:date];
	if (cell)
	{
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
	[self saveEvent:self.movedEvent completion:^(BOOL completion) {
		[self.monthPlannerView endInteraction];
	}];
	
	self.movedEvent = nil;
	
	[self.monthPlannerView endInteraction];
}

#pragma mark - EKEventEditViewDelegate

- (void)eventEditViewController:(EKEventEditViewController *)controller didCompleteWithAction:(EKEventEditViewAction)action
{
	[self.monthPlannerView endInteraction];
	[self.eventPopover dismissPopoverAnimated:NO];
}

#pragma mark - EKEventViewDelegate

- (void)eventViewController:(EKEventViewController *)controller didCompleteWithAction:(EKEventViewAction)action
{
	//[self.monthView endSelection];
	[self.eventPopover dismissPopoverAnimated:NO]; // TODO: why does this give a warning upon event deletion ?
}

#pragma mark - UIPopoverControllerDelegate

- (BOOL)popoverControllerShouldDismissPopover:(UIPopoverController*)popoverController
{
	[self.monthPlannerView deselectEventCellAtIndex:self.selectedEventIndex date:self.selectedEventDate];
	return YES;
}

- (void)popoverControllerDidDismissPopover:(UIPopoverController*)popoverController
{
	[self.monthPlannerView endInteraction];
}

- (void)popoverController:(UIPopoverController*)popoverController willRepositionPopoverToRect:(inout CGRect*)rect inView:(inout UIView**)view
{
	MGCEventView *cell = [self.monthPlannerView cellForEventAtIndex:self.selectedEventIndex date:self.selectedEventDate];
	if (cell)
	{
		CGRect newRect = [self.monthPlannerView convertRect:cell.bounds fromView:cell];
		*rect = newRect;
	}
}

#pragma mark - UINavigationControllerDelegate

- (void)navigationController:(UINavigationController *)navigationController willShowViewController:(UIViewController *)viewController animated:(BOOL)animated
{
	if ([viewController isKindOfClass:[EKEventViewController class]]) {
		[navigationController setNavigationBarHidden:YES animated:NO];
	}
	else {
		[navigationController setNavigationBarHidden:NO animated:NO];
	}
}

#pragma mark - UIAlertViewDelegate

// Called when a button is clicked. The view will be automatically dismissed after this call returns
- (void)alertView:(UIAlertView*)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
	NSAssert(self.savedEvent, @"Saved event is nil");
	
	BOOL saved = NO;
	
	if (buttonIndex != 0) {
		EKSpan span = EKSpanThisEvent;
		
		if (buttonIndex == 1) {
			span = EKSpanThisEvent;
		}
		else if (buttonIndex == 2) {
			span = EKSpanFutureEvents;
		}
		
		NSError *error;
		
		saved = [self.eventStore saveEvent:self.savedEvent span:span commit:YES error:&error];
		if (!saved) {
			NSLog(@"Error - Could not save event: %@", error.description);
		}
	}
	
	if (self.saveCompletion != nil) {
		self.saveCompletion(saved);
	}
	
	self.saveCompletion = nil;
	self.savedEvent = nil;
}


@end
