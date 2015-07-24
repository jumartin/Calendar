//
//  MGCDayPlannerEKViewController.m
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

#import "MGCDayPlannerEKViewController.h"
#import "MGCStandardEventView.h"
#import "NSCalendar+MGCAdditions.h"
#import "MGCDateRange.h"
#import "OSCache.h"


typedef enum {
	TimedEventType = 1,
	AllDayEventType = 2,
	AnyEventType = TimedEventType|AllDayEventType
} EventType;


typedef void(^EventSaveCompletionBlockType)(BOOL);


static const NSUInteger cacheSize = 400;	// size of the cache (in days)
static NSString* const EventCellReuseIdentifier = @"EventCellReuseIdentifier";



@interface MGCDayPlannerEKViewController () <UIPopoverControllerDelegate, UINavigationControllerDelegate, EKEventEditViewDelegate, EKEventViewDelegate>

@property (nonatomic) dispatch_queue_t bgQueue;			// dispatch queue for loading events
@property (nonatomic) NSMutableOrderedSet *daysToLoad;	// dates for months of which we want to load events
@property (nonatomic, readonly) NSCache *eventsCache;
@property EKEvent* savedEvent;
@property (nonatomic, copy) EventSaveCompletionBlockType saveCompletion;
@property (nonatomic) BOOL accessGranted;
@property (nonatomic) UIPopoverController *eventPopover;
@property (nonatomic) NSUInteger createdEventType;
@property (nonatomic, copy) NSDate *createdEventDate;

@end


@implementation MGCDayPlannerEKViewController

@synthesize eventsCache = _eventsCache;

- (instancetype)initWithEventStore:(EKEventStore*)eventStore
{
	if (self = [super initWithNibName:nil bundle:nil]) {
		_eventStore = eventStore;
		if (eventStore == nil) {
			_eventStore = [[EKEventStore alloc]init];
		}
		
		[[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(reloadEvents) name:EKEventStoreChangedNotification object:self.eventStore];

		_eventsCache = [[OSCache alloc]init];
		_eventsCache.countLimit = cacheSize;
		//_eventsCache.delegate = self;
	
		_bgQueue = dispatch_queue_create("MGCDayPlannerEKViewController.bgQueue", NULL);
		
		[self checkEventStoreAccessForCalendar];
	}
	return self;
}

- (void)reloadEvents
{
	[self.eventsCache removeAllObjects];
	[self fetchEventsInDateRange:self.dayPlannerView.visibleDays];
	[self.dayPlannerView reloadAllEvents];
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

- (void)showEditControllerForEventOfType:(MGCEventType)type atIndex:(NSUInteger)index date:(NSDate*)date
{
	EKEvent *ev = [self eventOfType:type atIndex:index date:date];
	
	MGCEventView *view = [self.dayPlannerView eventViewOfType:type atIndex:index date:date];
	
	EKEventViewController *eventController = [EKEventViewController new];
	eventController.event = ev;
	eventController.delegate = self;
	eventController.allowsEditing = YES;
	eventController.allowsCalendarPreview = YES;
	
	UINavigationController* nc = [[UINavigationController alloc] initWithRootViewController:eventController];
	nc.delegate = self;
	
	self.eventPopover = [[UIPopoverController alloc]initWithContentViewController:nc];
	self.eventPopover.delegate = self;
	
	CGRect visibleRect = CGRectIntersection(self.dayPlannerView.bounds, [self.dayPlannerView convertRect:view.bounds fromView:view]);
	[self.eventPopover presentPopoverFromRect:visibleRect inView:self.dayPlannerView permittedArrowDirections:UIPopoverArrowDirectionLeft|UIPopoverArrowDirectionRight animated:NO];
}

- (void)showPopoverForNewEvent:(EKEvent*)ev
{
	EKEventEditViewController *eventController = [EKEventEditViewController new];
	eventController.event = ev;
	eventController.eventStore = self.eventStore;
	eventController.editViewDelegate = self; // called only when event is deleted
	eventController.modalInPopover = YES;
	
	self.eventPopover = [[UIPopoverController alloc]initWithContentViewController:eventController];
	self.eventPopover.delegate = self;
	
	CGRect cellRect = [self.dayPlannerView rectForNewEventOfType:self.createdEventType atDate:self.createdEventDate];
	CGRect visibleRect = CGRectIntersection(self.dayPlannerView.bounds, cellRect);
	
	[self.eventPopover presentPopoverFromRect:visibleRect inView:self.dayPlannerView permittedArrowDirections:UIPopoverArrowDirectionLeft|UIPopoverArrowDirectionRight animated:NO];
}

#pragma mark - UIViewController

- (instancetype)initWithNibName:(NSString*)nibNameOrNil bundle:(NSBundle*)nibBundleOrNil
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
	
	self.dayPlannerView.calendar = self.calendar;
	[self.dayPlannerView registerClass:MGCStandardEventView.class forEventViewWithReuseIdentifier:EventCellReuseIdentifier];
}

- (void)didReceiveMemoryWarning
{
	[super didReceiveMemoryWarning];
}

#pragma mark - Properties

- (void)setCalendar:(NSCalendar*)calendar
{
	_calendar = calendar;
	self.dayPlannerView.calendar = calendar;
}

- (void)setVisibleCalendars:(NSSet*)visibleCalendars
{
	_visibleCalendars = visibleCalendars;
	[self.dayPlannerView reloadAllEvents];
}

#pragma mark - Loading events

- (void)fetchEventsInDateRange:(MGCDateRange*)range
{
	range.start = [self.calendar mgc_startOfDayForDate:range.start];
	range.end = [self.calendar mgc_nextStartOfDayForDate:range.end];
	
	[range enumerateDaysWithCalendar:self.calendar usingBlock:^(NSDate *date, BOOL *stop) {
		NSDate *dayEnd = [self.calendar mgc_nextStartOfDayForDate:date];
		NSArray *events = [self fetchEventsFrom:date to:dayEnd calendars:nil];
		[self.eventsCache setObject:events forKey:date];
	}];
}

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

// returns the events dictionary for given date
// try to load it from the cache, or create it if needed
- (NSArray*)eventsForDay:(NSDate*)date
{
	NSDate *dayStart = [self.calendar mgc_startOfDayForDate:date];
	
	NSArray *events = [self.eventsCache objectForKey:dayStart];
	
	if (!events) {  // cache miss: create dictionary...
		NSDate *dayEnd = [self.calendar mgc_nextStartOfDayForDate:dayStart];
		events = [self fetchEventsFrom:dayStart to:dayEnd calendars:nil];
		[self.eventsCache setObject:events forKey:dayStart];
	}
	
	return events;
}

- (NSArray*)eventsOfType:(EventType)type forDay:(NSDate*)date
{
	NSArray *events = [self eventsForDay:date];
	
	NSMutableArray *filteredEvents = [NSMutableArray new];
	[events enumerateObjectsUsingBlock:^(EKEvent *ev, NSUInteger idx, BOOL *stop) {
		
		if ([self.visibleCalendars containsObject:ev.calendar]) {
			if (type & AllDayEventType && ev.isAllDay)
				[filteredEvents addObject:ev];
			else if (type & TimedEventType && !ev.isAllDay)
				[filteredEvents addObject:ev];
		}
	}];
	
	return filteredEvents;
}

- (EKEvent*)eventOfType:(MGCEventType)type atIndex:(NSUInteger)index date:(NSDate*)date
{
	NSArray *events = nil;
	
	if (type == MGCAllDayEventType) {
		events = [self eventsOfType:AllDayEventType forDay:date];
	}
	else if (type == MGCTimedEventType) {
		events = [self eventsOfType:TimedEventType forDay:date];
	}
	
	return [events objectAtIndex:index];
}

- (void)bg_loadEventsAtDate:(NSDate*)date
{
	//NSLog(@"bg_loadEventsAtDate: %@", date);
	
	NSDate *dayStart = [self.calendar mgc_startOfDayForDate:date];
	
	[self eventsOfType:AnyEventType forDay:dayStart];
	
	dispatch_async(dispatch_get_main_queue(), ^{
		[self.dayPlannerView reloadEventsAtDate:date];
		[self.dayPlannerView setActivityIndicatorVisible:NO forDate:dayStart];
	});
}

- (void)bg_loadOneDay
{
	__block NSDate *date;
	
	dispatch_sync(dispatch_get_main_queue(), ^{
		if ((date = [self.daysToLoad firstObject])) {
			[self.daysToLoad removeObject:date];
		}
		
		if (![self.dayPlannerView.visibleDays containsDate:date]) {
			date = nil;
		}
	});
	
	if (date) {
		[self bg_loadEventsAtDate:date];
	}
}

- (BOOL)loadEventsAtDate:(NSDate*)date
{
	NSDate *dayStart = [self.calendar mgc_startOfDayForDate:date];
	
	if (![self.eventsCache objectForKey:dayStart]) {
		[self.dayPlannerView setActivityIndicatorVisible:YES forDate:dayStart];
		
		if (!self.daysToLoad) {
			self.daysToLoad = [NSMutableOrderedSet orderedSet];
		}
		
		[self.daysToLoad addObject:dayStart];
		
		dispatch_async(self.bgQueue, ^{	[self bg_loadOneDay]; });
		
		return YES;
	}
	return NO;
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
			 MGCDayPlannerEKViewController * __weak weakSelf = self;
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

#pragma mark - MGCDayPlannerViewDataSource

- (NSInteger)dayPlannerView:(MGCDayPlannerView*)weekView numberOfEventsOfType:(MGCEventType)type atDate:(NSDate*)date
{
	NSInteger count = 0;
	
	if (![self loadEventsAtDate:date]) {
		if (type == MGCAllDayEventType) {
			count = [[self eventsOfType:AllDayEventType forDay:date]count];
		}
		else {
			count = [[self eventsOfType:TimedEventType forDay:date]count];
		}
	}
	return count;
}

- (MGCEventView*)dayPlannerView:(MGCDayPlannerView*)view viewForEventOfType:(MGCEventType)type atIndex:(NSUInteger)index date:(NSDate*)date
{
	EKEvent *ev = [self eventOfType:type atIndex:index date:date];
	
	MGCStandardEventView *evCell = (MGCStandardEventView*)[view dequeueReusableViewWithIdentifier:EventCellReuseIdentifier forEventOfType:type atIndex:index date:date];
	evCell.font = [UIFont systemFontOfSize:11];
	evCell.title = ev.title;
	evCell.subtitle = ev.location;
	evCell.color = [UIColor colorWithCGColor:ev.calendar.CGColor];
	evCell.style = MGCStandardEventViewStylePlain|MGCStandardEventViewStyleSubtitle;
	evCell.style |= (type == MGCAllDayEventType) ?: MGCStandardEventViewStyleBorder;
	return evCell;
}

- (MGCDateRange*)dayPlannerView:(MGCDayPlannerView*)view dateRangeForEventOfType:(MGCEventType)type atIndex:(NSUInteger)index date:(NSDate*)date
{
	EKEvent *ev = [self eventOfType:type atIndex:index date:date];
	
	NSDate *end = ev.endDate;
	if (type == MGCAllDayEventType) {
		end = [self.calendar mgc_nextStartOfDayForDate:end];
	}
	
	return [MGCDateRange dateRangeWithStart:ev.startDate end:end];
}

- (BOOL)dayPlannerView:(MGCDayPlannerView*)view shouldStartMovingEventOfType:(MGCEventType)type atIndex:(NSUInteger)index date:(NSDate*)date
{
	EKEvent *ev = [self eventOfType:type atIndex:index date:date];
	return ev.calendar.allowsContentModifications;
}

- (BOOL)dayPlannerView:(MGCDayPlannerView*)view canMoveEventOfType:(MGCEventType)type atIndex:(NSUInteger)index date:(NSDate*)date toType:(MGCEventType)targetType date:(NSDate*)targetDate
{
	EKEvent *ev = [self eventOfType:type atIndex:index date:date];
	return ev.calendar.allowsContentModifications;
}

- (void)dayPlannerView:(MGCDayPlannerView*)view moveEventOfType:(MGCEventType)type atIndex:(NSUInteger)index date:(NSDate*)date toType:(MGCEventType)targetType date:(NSDate*)targetDate
{
	EKEvent *ev = [self eventOfType:type atIndex:index date:date];
	
	if (ev) {
		NSDateComponents *duration = [self.calendar components:NSMinuteCalendarUnit fromDate:ev.startDate toDate:ev.endDate options:0];
		if (ev.allDay && targetType == MGCTimedEventType) {
			duration.minute = 60;
		}
		NSDate *end = [self.calendar dateByAddingComponents:duration toDate:targetDate options:0];
		
		// allDay property has to be set before start and end dates !
		ev.allDay = (targetType == MGCAllDayEventType);
		ev.startDate = targetDate;
		ev.endDate = end;
		
		[self saveEvent:ev completion:^(BOOL completion) {
			[self.dayPlannerView endInteraction];
		}];
	}
}

- (MGCEventView*)dayPlannerView:(MGCDayPlannerView*)view viewForNewEventOfType:(MGCEventType)type atDate:(NSDate*)date
{
	EKCalendar *defaultCalendar = [self.eventStore defaultCalendarForNewEvents];
	
	MGCStandardEventView *evCell = [MGCStandardEventView new];
	evCell.title = NSLocalizedString(@"New Event", nil);
	evCell.color = [UIColor colorWithCGColor:defaultCalendar.CGColor];
	return evCell;
}

- (void)dayPlannerView:(MGCDayPlannerView *)view createNewEventOfType:(MGCEventType)type atDate:(NSDate*)date
{
	self.createdEventType = type;
	self.createdEventDate = date;
	
	EKEvent *ev = [EKEvent eventWithEventStore:self.eventStore];
	ev.startDate = date;
	NSDateComponents *comps = [NSDateComponents new];
	comps.hour = 1;
	ev.endDate = [self.calendar dateByAddingComponents:comps toDate:date options:0];
	ev.allDay = (type == MGCAllDayEventType) ? YES : NO;
	
	[self showPopoverForNewEvent:ev];
}

#pragma mark - MGCDayPlannerViewDelegate

- (void)dayPlannerView:(MGCDayPlannerView*)view didSelectEventOfType:(MGCEventType)type atIndex:(NSUInteger)index date:(NSDate*)date
{
	[self showEditControllerForEventOfType:type atIndex:index date:date];
}

- (void)dayPlannerView:(MGCDayPlannerView*)view willDisplayDate:(NSDate*)date
{
	//NSLog(@"will display %@", date);
	[self loadEventsAtDate:date];
}

- (void)dayPlannerView:(MGCDayPlannerView*)view didEndDisplayingDate:(NSDate*)date
{
	//NSLog(@"did end displaying %@", date);
	[self.daysToLoad removeObject:date];
}

#pragma mark - EKEventEditViewDelegate

- (void)eventEditViewController:(EKEventEditViewController *)controller didCompleteWithAction:(EKEventEditViewAction)action
{
	[self.dayPlannerView endInteraction];
	[self.eventPopover dismissPopoverAnimated:NO];
	self.createdEventDate = nil;
}

#pragma mark - EKEventViewDelegate

- (void)eventViewController:(EKEventViewController *)controller didCompleteWithAction:(EKEventViewAction)action
{
	[self.dayPlannerView deselectEvent];
	[self.eventPopover dismissPopoverAnimated:NO]; // TODO: why does this give a warning upon event deletion ?
}

#pragma mark - UIPopoverControllerDelegate

- (void)popoverControllerDidDismissPopover:(UIPopoverController*)popoverController
{
	[self.dayPlannerView deselectEvent];
}

- (void)popoverController:(UIPopoverController*)popoverController willRepositionPopoverToRect:(inout CGRect*)rect inView:(inout UIView *__autoreleasing*)view
{
	if (popoverController == self.eventPopover) {
		CGRect cellRect;
		if (self.createdEventDate) {
			cellRect = [self.dayPlannerView rectForNewEventOfType:self.createdEventType atDate:self.createdEventDate];
		}
		else {
			UIView *cell = self.dayPlannerView.selectedEventView;
			cellRect = [self.dayPlannerView convertRect:cell.bounds fromView:cell];
			
		}
		CGRect visibleRect = CGRectIntersection(self.dayPlannerView.bounds, cellRect);
		if (CGRectIsNull(visibleRect)) {
			rect->origin.x = cellRect.origin.x;
			rect->origin.y = fminf(cellRect.origin.y, CGRectGetMaxY(self.dayPlannerView.bounds));
			rect->size.width = cellRect.size.width;
		}
		else {
			*rect = visibleRect;
		}
	}
}

#pragma mark - UINavigationControllerDelegate

- (void)navigationController:(UINavigationController *)navigationController willShowViewController:(UIViewController *)viewController animated:(BOOL)animated
{
	// Hide navigation bar when showing events details, show it otherwise (e.g when moving to calendars or alarms controller)
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

