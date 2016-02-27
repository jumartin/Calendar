//
//  MainViewController.m
//  CalendarDemo - Graphical Calendars Library for iOS
//
//  Copyright (c) 2014-2015 Julien Martin. All rights reserved.
//

#import "MainViewController.h"
#import "WeekViewController.h"
#import "MonthViewController.h"
#import "YearViewController.h"
#import "NSCalendar+MGCAdditions.h"
#import "WeekSettingsViewController.h"


typedef enum : NSUInteger
{
    CalendarViewWeekType  = 0,
    CalendarViewMonthType = 1,
    CalendarViewYearType = 2
} CalendarViewType;


@interface MainViewController ()<YearViewControllerDelegate>

@property (nonatomic, strong) NSDateFormatter *dateFormatter;
@property (nonatomic) EKCalendarChooser *calendarChooser;
@property (nonatomic) BOOL firstTimeAppears;

@end


@implementation MainViewController

#pragma mark - UIViewController

- (id)initWithCoder:(NSCoder *)aDecoder
{
    if (self = [super initWithCoder:aDecoder]) {
        _eventStore = [[EKEventStore alloc]init];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    NSString *calID = [[NSUserDefaults standardUserDefaults]stringForKey:@"calendarIdentifier"];
    self.calendar = [NSCalendar mgc_calendarFromPreferenceString:calID];
    
    NSUInteger firstWeekday = [[NSUserDefaults standardUserDefaults]integerForKey:@"firstDay"];
    if (firstWeekday != 0) {
        self.calendar.firstWeekday = firstWeekday;
    } else {
        [[NSUserDefaults standardUserDefaults]registerDefaults:@{ @"firstDay" : @(self.calendar.firstWeekday) }];
    }
    
    self.dateFormatter = [NSDateFormatter new];
    self.dateFormatter.calendar = self.calendar;
    
    if (isiPad) {
        //NSLog(@"---------------- iPAD ------------------");
    }
    else{
        //NSLog(@"---------------- iPhone ------------------");
        self.navigationItem.leftBarButtonItem.customView = self.currentDateLabel;
    }
	
	CalendarViewController *controller = [self controllerForViewType:CalendarViewWeekType];
	[self addChildViewController:controller];
	[self.containerView addSubview:controller.view];
	controller.view.frame = self.containerView.bounds;
	[controller didMoveToParentViewController:self];
	
	self.calendarViewController = controller;
    self.firstTimeAppears = YES;
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    if (self.firstTimeAppears) {
        NSDate *date = [self.calendar mgc_startOfWeekForDate:[NSDate date]];
        [self.calendarViewController moveToDate:date animated:NO];
        self.firstTimeAppears = NO;
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)prepareForSegue:(UIStoryboardSegue*)segue sender:(id)sender
{
    if ([[segue identifier] isEqualToString:@"ShowSettings"])
    {
        WeekSettingsViewController *settingsViewController = [segue destinationViewController];
        
        WeekViewController *weekController = (WeekViewController*)self.calendarViewController;
        settingsViewController.dayPlannerView = weekController.dayPlannerView;
    }
}

#pragma mark - Private

- (CalendarViewController*)controllerForViewType:(CalendarViewType)type
{
    CalendarViewController *controller = nil;
    
    switch (type)
    {
        case CalendarViewWeekType:
        {
            WeekViewController *weekController = [[WeekViewController alloc]initWithEventStore:self.eventStore];
            weekController.calendar = self.calendar;
            weekController.delegate = self;
            controller = weekController;
            break;
        }
        case CalendarViewMonthType:
        {
            MonthViewController *monthController = [[MonthViewController alloc]initWithEventStore:self.eventStore];
            monthController.calendar = self.calendar;
            monthController.delegate = self;
            controller = monthController;
            break;
        }
        case CalendarViewYearType:
        {
            YearViewController *yearController = [[YearViewController alloc]init];
            yearController.calendar = self.calendar;
            yearController.delegate = self;
            controller = yearController;
            break;
        }
        default:
            break;
    }
    return controller;
}

-(void)moveToNewController:(CalendarViewController*)newController atDate:(NSDate*)date
{
    [self.calendarViewController willMoveToParentViewController:nil];
    [self addChildViewController:newController];
    
    [self transitionFromViewController:self.calendarViewController toViewController:newController duration:.5 options:UIViewAnimationOptionTransitionFlipFromLeft animations:^
     {
         newController.view.frame = self.containerView.bounds;
         newController.view.hidden = YES;
     } completion:^(BOOL finished)
     {
         [self.calendarViewController removeFromParentViewController];
         [newController didMoveToParentViewController:self];
         self.calendarViewController = newController;
         [newController moveToDate:date animated:NO];
         newController.view.hidden = NO;
     }];
}

#pragma mark - Actions

-(IBAction)switchControllers:(UISegmentedControl*)sender
{
    self.settingsButtonItem.enabled = NO;
    
    NSDate *date = [self.calendarViewController centerDate];
    CalendarViewController *controller = [self controllerForViewType:sender.selectedSegmentIndex];
    [self moveToNewController:controller atDate:date];
    
    if ([controller isKindOfClass:WeekViewController.class]) {
        self.settingsButtonItem.enabled = YES;
    }
}

- (IBAction)showToday:(id)sender
{
    [self.calendarViewController moveToDate:[NSDate date] animated:YES];
}

- (IBAction)nextPage:(id)sender
{
    [self.calendarViewController moveToNextPageAnimated:YES];
}

- (IBAction)previousPage:(id)sender
{
    [self.calendarViewController moveToPreviousPageAnimated:YES];
}

- (IBAction)showCalendars:(id)sender
{
    if ([self.calendarViewController respondsToSelector:@selector(visibleCalendars)]) {
        self.calendarChooser = [[EKCalendarChooser alloc]initWithSelectionStyle:EKCalendarChooserSelectionStyleMultiple displayStyle:EKCalendarChooserDisplayAllCalendars eventStore:self.eventStore];
        self.calendarChooser.delegate = self;
        self.calendarChooser.showsDoneButton = YES;
        self.calendarChooser.selectedCalendars = self.calendarViewController.visibleCalendars;
    }
    
    if (self.calendarChooser) {
        UINavigationController *nc = [[UINavigationController alloc]initWithRootViewController:self.calendarChooser];
        self.calendarChooser.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc]initWithBarButtonSystemItem:UIBarButtonSystemItemEdit target:self action:@selector(calendarChooserStartEdit)];
        nc.modalPresentationStyle = UIModalPresentationPopover;
 
        [self showDetailViewController:nc sender:self];
        
        UIPopoverPresentationController *popController = nc.popoverPresentationController;
        popController.barButtonItem = (UIBarButtonItem*)sender;
    }
}

- (void)calendarChooserStartEdit
{
    self.calendarChooser.editing = YES;
    self.calendarChooser.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc]initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(calendarChooserEndEdit)];
}

- (void)calendarChooserEndEdit
{
    self.calendarChooser.editing = NO;
    self.calendarChooser.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc]initWithBarButtonSystemItem:UIBarButtonSystemItemEdit target:self action:@selector(calendarChooserStartEdit)];
}

#pragma mark - YearViewControllerDelegate

- (void)yearViewController:(YearViewController*)controller didSelectMonthAtDate:(NSDate*)date
{
    CalendarViewController *controllerNew = [self controllerForViewType:CalendarViewMonthType];
    [self moveToNewController:controllerNew atDate:date];
    self.viewChooser.selectedSegmentIndex = CalendarViewMonthType;
}

#pragma mark - CalendarViewControllerDelegate

- (void)calendarViewController:(CalendarViewController*)controller didShowDate:(NSDate*)date
{
    if (controller.class == YearViewController.class)
        [self.dateFormatter setDateFormat:@"yyyy"];
    else
        [self.dateFormatter setDateFormat:@"MMMM yyyy"];
    
    NSString *str = [self.dateFormatter stringFromDate:date];
    self.currentDateLabel.text = str;
    [self.currentDateLabel sizeToFit];
}

- (void)calendarViewController:(CalendarViewController*)controller didSelectEvent:(EKEvent*)event
{
    //NSLog(@"calendarViewController:didSelectEvent");
}

#pragma mark - MGCDayPlannerEKViewControllerDelegate

- (UINavigationController*)navigationControllerForEKEventViewController
{
//    if (!isiPad) {
//        return self.navigationController;
//    }
    return nil;
}


#pragma mark - EKCalendarChooserDelegate

- (void)calendarChooserSelectionDidChange:(EKCalendarChooser*)calendarChooser
{
    if ([self.calendarViewController respondsToSelector:@selector(setVisibleCalendars:)]) {
        self.calendarViewController.visibleCalendars = calendarChooser.selectedCalendars;
    }
}

- (void)calendarChooserDidFinish:(EKCalendarChooser*)calendarChooser
{
    [self dismissViewControllerAnimated:YES completion:nil];
}


@end
