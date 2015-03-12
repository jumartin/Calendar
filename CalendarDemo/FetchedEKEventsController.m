//
//  FetchedEKEventsController.m
//  Graphical Calendars Library for iOS
//
//  Created by Julien Martin on 25/10/13.
//  Copyright (c) 2015 Julien Martin. All rights reserved.
//

#import "FetchedEKEventsController.h"
#import "NSCalendar+MGCAdditions.h"
#import "OSCache.h"

static const NSUInteger cacheSize = 400;	// size of the cache (in days)


typedef void(^EventSaveCompletionBlockType)(BOOL);

@interface FetchedEKEventsController ()<UIAlertViewDelegate, NSCacheDelegate>

@property (nonatomic) BOOL accessGranted;
@property (nonatomic) NSCache *eventsCache;
@property EKEvent* savedEvent;
@property (nonatomic, copy) EventSaveCompletionBlockType saveCompletion;

@end


@implementation FetchedEKEventsController

- (id)init
{
	if (self = [super init]) {
		
		_accessGranted = NO;
		_calendar = [NSCalendar currentCalendar];
		
		// init event store
		_eventStore = [[EKEventStore alloc] init];
		
		// check permission and fetch events
		[self checkEventStoreAccessForCalendar];
		
		// register for EventKit notifications
		[[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(eventStoreDidChange:) name:EKEventStoreChangedNotification object:_eventStore];
	}
	return self;
}

- (void)dealloc
{
	[[NSNotificationCenter defaultCenter]removeObserver:self];
}

#pragma mark - Properties

- (NSCache*)eventsCache
{
	if (!_eventsCache) {
		_eventsCache = [[OSCache alloc]init]; //[[NSCache alloc]init];
		_eventsCache.countLimit = cacheSize;
		_eventsCache.delegate = self;
	}
	return _eventsCache;
}

- (void)setVisibleCalendars:(NSSet*)calendars
{
	if (![calendars isEqualToSet:_visibleCalendars]) {
		_visibleCalendars = calendars;
		
		if ([self.delegate respondsToSelector:@selector(fetchedEKEventsController:didChangeVisibleCalendars:)]) {
			[self.delegate fetchedEKEventsController:self didChangeVisibleCalendars:calendars];
		}
	}
}

#pragma mark  - Public methods


- (BOOL)hasEventsInCacheForDay:(NSDate*)date
{
	NSDate *dayStart = [self.calendar mgc_startOfDayForDate:date];
	return ([self.eventsCache objectForKey:dayStart]!= nil);
}

- (NSArray*)eventsOfType:(FetchedEKEventType)type forDay:(NSDate*)date
{
	NSArray *events = [self eventsForDay:date];
	
	NSMutableArray *filteredEvents = [NSMutableArray new];
	[events enumerateObjectsUsingBlock:^(EKEvent *ev, NSUInteger idx, BOOL *stop) {
		
		if ([self.visibleCalendars containsObject:ev.calendar]) {
			if (type & FetchedEKAllDayEventType && ev.isAllDay)
				[filteredEvents addObject:ev];
			else if (type & FetchedEKTimedEventType && !ev.isAllDay)
				[filteredEvents addObject:ev];
		}
	}];
	
	return filteredEvents;
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
			[self.eventsCache setObject:events forKey:date];
		}];
	}
	
	return eventsPerDay;
}

- (void)invalidateCache
{
	//NSLog(@"invalidate cache");
	
	[self.eventsCache removeAllObjects];
	[self reloadEvents];
}

- (void)invalidateCacheForDateRange:(MGCDateRange*)range
{
	//NSLog(@"invalidate cache for date range %@", range);
	
	[range enumerateDaysWithCalendar:self.calendar usingBlock:^(NSDate *date, BOOL *stop) {
		[self.eventsCache removeObjectForKey:date];
	}];
	
	//[self reloadEvents];
}

- (void)saveEvent:(EKEvent*)event completion:(void (^)(BOOL saved))completion
{
	if ([event hasRecurrenceRules])
	{
		self.savedEvent = event;
		self.saveCompletion = completion;
		
		NSString *title = @"Cet événement est récurrent.";
		NSString *msg = @"Que souhaitez-vous modifier ?";
		UIAlertView *sheet = [[UIAlertView alloc]initWithTitle:title message:msg delegate:self cancelButtonTitle:@"Annuler" otherButtonTitles:
							  @"Seulement cet événement",
							  @"Tous les événements à venir", nil];
		[sheet show];
	}
	else
	{
		NSError *error;
		BOOL saved = [self.eventStore saveEvent:event span:EKSpanThisEvent commit:YES error:&error];
		if (!saved)
		{
			NSLog(@"Error: Could not save event :");
			NSLog(@"%@", error.description);
			
			
		}
		if (completion != nil)
		{
			completion(saved);
		}
	}
}

#pragma mark - Fetch events

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

#pragma mark - Access Calendar

// Check the authorization status of our application for Calendar
- (void)checkEventStoreAccessForCalendar
{
    EKAuthorizationStatus status = [EKEventStore authorizationStatusForEntityType:EKEntityTypeEvent];
	
    switch (status)
    {
			// Update our UI if the user has granted access to their Calendar
        case EKAuthorizationStatusAuthorized:
		{
			[self accessGrantedForCalendar];
			break;
		}
			
			// Prompt the user for access to Calendar if there is no definitive answer
        case EKAuthorizationStatusNotDetermined:
		{
			[self requestCalendarAccess];
			break;
		}
			
			// Display a message if the user has denied or restricted access to Calendar
        case EKAuthorizationStatusDenied:
        case EKAuthorizationStatusRestricted:
		{
            NSString *title = @"Attention";
			NSString *msg = @"L'accès de cette application au calendrier n'a pas été autorisée";
			UIAlertView *alert = [[UIAlertView alloc] initWithTitle:title message:msg delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
            [alert show];
			break;
        }
			
		default:
            break;
    }
}

// Prompt the user for access to their Calendar
- (void)requestCalendarAccess
{
    [self.eventStore requestAccessToEntityType:EKEntityTypeEvent completion:^(BOOL granted, NSError *error)
	 {
         if (granted)
         {
             FetchedEKEventsController * __weak weakSelf = self;
             // Let's ensure that our code will be executed from the main queue
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
	
	// notify delegate so it can load events
	[self reloadEvents];
}


#pragma mark - EventKit Notification

- (void)eventStoreDidChange:(NSNotification*)notification
{
	//NSLog(@"event store did change");
	
	self.eventsCache = nil;
	//[self.eventsCache removeAllObjects];
	
	if ([self.delegate respondsToSelector:@selector(fetchedEKEventsControllerDidChangeContent:)]) {
		[self.delegate fetchedEKEventsControllerDidChangeContent:self];
	}
}

- (void)reloadEvents
{
	//NSLog(@"reload events");
	
	if ([self.delegate respondsToSelector:@selector(fetchedEKEventsControllerDidChangeContent:)]) {
		[self.delegate fetchedEKEventsControllerDidChangeContent:self];
	}
}

#pragma mark - UIAlertViewDelegate

// Called when a button is clicked. The view will be automatically dismissed after this call returns
- (void)alertView:(UIAlertView*)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
	NSAssert(self.savedEvent, @"Saved event is nil !");
	
	BOOL saved = NO;
	
	if (buttonIndex != 0)
	{
		EKSpan span = EKSpanThisEvent;
		if (buttonIndex == 1) // span this event
		{
			span = EKSpanThisEvent;
		}
		else if (buttonIndex == 2) // span all future events
		{
			span = EKSpanFutureEvents;
		}
		
		saved = [self.eventStore saveEvent:self.savedEvent span:span commit:YES error:nil];
		if (!saved)
		{
			NSLog(@"Error: Could not save event !");
		}
	}
	
	if (self.saveCompletion != nil)
	{
		self.saveCompletion(saved);
	}
	
	self.saveCompletion = nil;
	self.savedEvent = nil;
}

#pragma mark - NSCacheDelegate

- (void)cache:(NSCache*)cache willEvictObject:(id)obj
{
//	NSDate *start = [[obj firstObject]startDate];
//	NSDate *end = [[obj firstObject]endDate];
//	NSLog(@"cache will evict something between %@ and %@", start, end);
}

@end
