//
//  MGCEventKitSupport.m
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

#import <Foundation/Foundation.h>
#import "MGCEventKitSupport.h"


@interface MGCEventKitSupport ()<UIAlertViewDelegate>

@property (nonatomic) EKEvent* savedEvent;
@property (nonatomic, copy) EventSaveCompletionBlockType saveCompletion;

@end


@implementation MGCEventKitSupport

@synthesize eventStore = _eventStore;


// designated initializer
- (instancetype)initWithEventStore:(EKEventStore*)eventStore
{
    if (self = [super init]) {
        _eventStore = eventStore;
    }
    return self;
}

- (EKEventStore*)eventStore
{
    if (_eventStore == nil) {
        _eventStore = [EKEventStore new];
    }
    return _eventStore;
}

#pragma mark - Calendar access authorization

- (void)checkEventStoreAccessForCalendar:(void (^)(BOOL accessGranted))completion
{
    EKAuthorizationStatus status = [EKEventStore authorizationStatusForEntityType:EKEntityTypeEvent];
    
    switch (status) {
        case EKAuthorizationStatusAuthorized:
            [self accessGrantedForCalendar];
            completion(YES);
            break;
            
        case EKAuthorizationStatusNotDetermined:
            [self requestCalendarAccess:completion];
            break;
            
        case EKAuthorizationStatusDenied:
        case EKAuthorizationStatusRestricted:
            [self accessDeniedForCalendar];
            completion(NO);
    }
}

- (void)requestCalendarAccess:(void (^)(BOOL accessGranted))completion
{
    [self.eventStore requestAccessToEntityType:EKEntityTypeEvent completion:^(BOOL granted, NSError *error) {
        if (granted) {
            MGCEventKitSupport * __weak weakSelf = self;
            dispatch_async(dispatch_get_main_queue(), ^{
                [weakSelf accessGrantedForCalendar];
                completion(YES);
            });
        }
    }];
}

- (void)accessGrantedForCalendar
{
    _accessGranted = YES;
}

- (void)accessDeniedForCalendar
{
    NSString *title = NSLocalizedString(@"Warning", nil);
    NSString *msg = NSLocalizedString(@"Access to the calendar was not authorized", nil);
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:title message:msg delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
    [alert show];
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



@implementation MGCEKEventViewController

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    UIPopoverPresentationController *popController = self.parentViewController.popoverPresentationController;
    BOOL isPopoverPresented = popController && popController.arrowDirection != UIPopoverArrowDirectionUnknown;
    
    // navigation bar is hidden by default when EKEventViewController is presented fullscreen
    if (self.presentingViewController && !isPopoverPresented) {
        self.navigationController.navigationBarHidden = NO;
        // self.navigationController.toolbarHidden = YES;
    }
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    // this fixes a problem when EKEventViewController is pushed
    // that causes a white bar to show on the bottom when returning to the previous view controller
    self.navigationController.toolbarHidden = YES;
}

@end
