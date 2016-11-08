//
//  WeekSettingsViewController.m
//  CalendarDemo - Graphical Calendars Library for iOS
//
//  Copyright (c) 2014-2015 Julien Martin. All rights reserved.
//

#import "WeekSettingsViewController.h"
#import "MGCDateRange.h"
#import "NSCalendar+MGCAdditions.h"
#import "MGCStandardEventView.h"


@interface CustomEventView : MGCStandardEventView
@end

@implementation CustomEventView

- (id)initWithFrame:(CGRect)frame
{
	if (self = [super initWithFrame:frame]) {
		self.layer.cornerRadius = 6;
		self.layer.borderWidth = 1;
		self.layer.borderColor = [[UIColor lightGrayColor]CGColor];
		//self.clipsToBounds = YES;
	}
	return self;
}

@end


@interface WeekSettingsViewController ()

@property (nonatomic) NSDateFormatter *dateFormatter;

@property (nonatomic) MGCDayPlannerView *dayPlannerView;

@property (nonatomic) IBOutlet UILabel *visibleDaysLabel;
@property (nonatomic) IBOutlet UIStepper *visibleDaysStepper;

@property (nonatomic) IBOutlet UILabel *firstHourLabel;
@property (nonatomic) IBOutlet UIStepper *firstHourStepper;

@property (nonatomic) IBOutlet UILabel *lastHourLabel;
@property (nonatomic) IBOutlet UIStepper *lastHourStepper;

@property (nonatomic) IBOutlet UISwitch *pagingSwitch;
@property (nonatomic) IBOutlet UISwitch *zoomingSwitch;

@property (nonatomic) IBOutlet UISwitch *allDayEventSwitch;

@property (nonatomic) IBOutlet UIDatePicker *startDatePicker;
@property (nonatomic) IBOutlet UITableViewCell *startDateCell;
@property (nonatomic) IBOutlet UILabel *startDateLabel;

@property (nonatomic) IBOutlet UIDatePicker *endDatePicker;
@property (nonatomic) IBOutlet UITableViewCell *endDateCell;
@property (nonatomic) IBOutlet UILabel *endDateLabel;

@property (nonatomic) BOOL showsStartDatePicker, showsEndDatePicker;

@property (nonatomic) IBOutlet UISwitch *eventCreationSwitch;
@property (nonatomic) IBOutlet UISwitch *eventMovingSwitch;
@property (nonatomic) IBOutlet UISwitch *eventSelectionSwitch;

@property (nonatomic) IBOutlet UISwitch *customCellSwitch;
@property (nonatomic) IBOutlet UISwitch *dimmedTimeRangeSwitch;

@end


@implementation WeekSettingsViewController

- (UIView*)makeCancelAccessoryView
{
	UIView *view = [[UIView alloc]initWithFrame:CGRectMake(0, 0, 30, 18)];
	
	UIButton *cancelButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
	cancelButton.frame = CGRectMake(12, 0, 18, 18);
	[cancelButton setTitle:@"x" forState:UIControlStateNormal];
    cancelButton.titleLabel.font = [UIFont systemFontOfSize:13 weight:UIFontWeightBlack];
    cancelButton.tintColor = [UIColor blackColor];
    cancelButton.contentEdgeInsets = UIEdgeInsetsMake(0, 0, 2, 0);
	cancelButton.clipsToBounds = YES;
	cancelButton.layer.cornerRadius = 9;
	cancelButton.layer.borderWidth = 1;
	cancelButton.layer.borderColor = [[UIColor grayColor]CGColor];
	[cancelButton addTarget:self action:@selector(accessoryButtonTapped:withEvent:) forControlEvents:UIControlEventTouchUpInside];
	
	[view addSubview:cancelButton];
	return view;
}

- (MGCDayPlannerView*)dayPlannerView
{
    return self.weekViewController.dayPlannerView;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	
	self.dateFormatter = [[NSDateFormatter alloc] init];
	[self.dateFormatter setDateStyle:NSDateFormatterShortStyle];
	[self.dateFormatter setTimeStyle:NSDateFormatterNoStyle];

	self.allDayEventSwitch.on = self.dayPlannerView.showsAllDayEvents;
	
	self.visibleDaysStepper.value = self.dayPlannerView.numberOfVisibleDays;
	self.visibleDaysLabel.text = [NSString stringWithFormat:@"%d", (int)self.dayPlannerView.numberOfVisibleDays];
	
    self.firstHourStepper.value = self.dayPlannerView.hourRange.location;
    self.firstHourLabel.text = [NSString stringWithFormat:@"%d", (int)self.dayPlannerView.hourRange.location];
 
    self.lastHourStepper.value = NSMaxRange(self.dayPlannerView.hourRange);
    self.lastHourLabel.text = [NSString stringWithFormat:@"%d", (int)NSMaxRange(self.dayPlannerView.hourRange)];
    
    self.lastHourStepper.minimumValue = self.firstHourStepper.value + 1;
    self.firstHourStepper.maximumValue = self.lastHourStepper.value - 1;
    
	self.pagingSwitch.on = self.dayPlannerView.pagingEnabled;
	self.zoomingSwitch.on = self.dayPlannerView.zoomingEnabled;
	
	if (self.dayPlannerView.dateRange) {
		self.startDatePicker.date = self.dayPlannerView.dateRange.start;
		self.startDateLabel.text = [self.dateFormatter stringFromDate:self.startDatePicker.date];
		
		NSDate *end = [self.dayPlannerView.dateRange.end dateByAddingTimeInterval:-1];
		self.endDatePicker.date = end;
		self.endDateLabel.text = [self.dateFormatter stringFromDate:end];
		
		self.startDatePicker.maximumDate = end;
		self.endDatePicker.minimumDate = self.dayPlannerView.dateRange.start;
		
		self.startDateCell.accessoryView = [self makeCancelAccessoryView];
		self.endDateCell.accessoryView = [self makeCancelAccessoryView];
	}
	
	self.eventCreationSwitch.on = self.dayPlannerView.canCreateEvents;
	self.eventMovingSwitch.on = self.dayPlannerView.canMoveEvents;
	self.eventSelectionSwitch.on = self.dayPlannerView.allowsSelection;
    
    self.dimmedTimeRangeSwitch.on = self.weekViewController.showDimmedTimeRanges;
    
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Utilities

- (void)accessoryButtonTapped:(UIControl*)button withEvent:(UIEvent*)event
{
	NSIndexPath *indexPath = [self.tableView indexPathForRowAtPoint:[[[event touchesForView:button] anyObject] locationInView:self.tableView]];
	if (indexPath != nil) {
		[self.tableView.delegate tableView:self.tableView accessoryButtonTappedForRowWithIndexPath:indexPath];
	}
}

- (void)setDateRange
{
	if (![self.startDateLabel.text isEqualToString:@"None"] && ![self.endDateLabel.text isEqualToString:@"None"]) {
		NSDate *start = self.startDatePicker.date;
		NSDate *end = [self.dayPlannerView.calendar mgc_nextStartOfDayForDate:self.endDatePicker.date];
		self.dayPlannerView.dateRange = [MGCDateRange dateRangeWithStart:start end:end];
	}
	else {
		self.dayPlannerView.dateRange = nil;
	}
}


#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath*)indexPath
{
	UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
	[tableView beginUpdates];
	
	if (cell == self.startDateCell) {
		self.showsStartDatePicker = !self.showsStartDatePicker;
		self.endDatePicker.minimumDate = self.startDatePicker.date;
		
		if (!self.showsStartDatePicker) {
			[self setDateRange];
		}
		else {
			self.showsEndDatePicker = NO;
			self.startDateLabel.text = [self.dateFormatter stringFromDate:self.startDatePicker.date];
			self.startDateCell.accessoryView = [self makeCancelAccessoryView];
		}
	}
	else if (cell == self.endDateCell) {
		self.showsEndDatePicker = !self.showsEndDatePicker;
		self.startDatePicker.maximumDate = self.endDatePicker.date;
		
		if (!self.showsEndDatePicker) {
			[self setDateRange];
		}
		else {
			self.showsStartDatePicker = NO;
			self.endDateLabel.text = [self.dateFormatter stringFromDate:self.endDatePicker.date];
			self.endDateCell.accessoryView = [self makeCancelAccessoryView];
		}
	}

	[tableView reloadData];
	[self.tableView endUpdates];
	
	[self.tableView scrollToRowAtIndexPath:indexPath atScrollPosition:UITableViewScrollPositionMiddle animated:YES];
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
	if (indexPath.section == 2 && ((indexPath.row == 1 && !self.showsStartDatePicker) || (indexPath.row == 3 && !self.showsEndDatePicker))) {
		return 0;
	}
	return [super tableView:tableView heightForRowAtIndexPath:indexPath];
}

- (void)tableView:(UITableView*)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath*)indexPath
{
	UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
	if (cell == self.startDateCell) {
		self.startDateLabel.text = @"None";
		[self.startDateCell.accessoryView removeFromSuperview];
		self.startDateCell.accessoryView = nil;
		[self setDateRange];
	}
	else if (cell == self.endDateCell) {
		self.endDateLabel.text = @"None";
		[self.endDateCell.accessoryView removeFromSuperview];
		self.endDateCell.accessoryView = nil;
		[self setDateRange];
	}
}

#pragma mark - Actions

- (IBAction)stepperChanged:(UIStepper*)sender
{
    if (sender == self.visibleDaysStepper) {
        self.visibleDaysLabel.text = [NSString stringWithFormat:@"%1.0f", sender.value];
        self.dayPlannerView.numberOfVisibleDays  = sender.value;
        if (sender.value <= 3) {
            self.dayPlannerView.dateFormat = @"eeee d MMMM";
        }
        else {
            self.dayPlannerView.dateFormat = @"eeeee\nd MMM";
        }
    }
    else if (sender == self.firstHourStepper) {
        self.lastHourStepper.minimumValue = self.firstHourStepper.value + 1;
        self.firstHourLabel.text = [NSString stringWithFormat:@"%d", (int)self.firstHourStepper.value];
        self.dayPlannerView.hourRange = NSMakeRange(self.firstHourStepper.value, self.lastHourStepper.value - self.firstHourStepper.value);
    }
    else if (sender == self.lastHourStepper) {
        self.firstHourStepper.maximumValue = self.lastHourStepper.value - 1;
        self.lastHourLabel.text = [NSString stringWithFormat:@"%d", (int)self.lastHourStepper.value];
        self.dayPlannerView.hourRange = NSMakeRange(self.firstHourStepper.value, self.lastHourStepper.value - self.firstHourStepper.value);
    }
}

- (IBAction)switchToggled:(UISwitch*)sender
{
	if (sender == self.pagingSwitch) {
		self.dayPlannerView.pagingEnabled = sender.on;
        [self.dayPlannerView reloadDimmedTimeRanges];
	}
	else if (sender == self.zoomingSwitch) {
		self.dayPlannerView.zoomingEnabled = sender.on;
	}
	else if (sender == self.allDayEventSwitch) {
		self.dayPlannerView.showsAllDayEvents = sender.on;
	}
	else if (sender == self.eventCreationSwitch) {
		self.dayPlannerView.canCreateEvents = sender.on;
	}
	else if (sender == self.eventMovingSwitch) {
		self.dayPlannerView.canMoveEvents = sender.on;
	}
	else if (sender == self.eventSelectionSwitch) {
		self.dayPlannerView.allowsSelection = sender.on;
	}
	else if (sender == self.customCellSwitch) {
		if (sender.on) {
			[self.dayPlannerView registerClass:nil forEventViewWithReuseIdentifier:@"EventCellReuseIdentifier"];
			[self.dayPlannerView registerClass:CustomEventView.class forEventViewWithReuseIdentifier:@"EventCellReuseIdentifier"];
		}
		else {
			[self.dayPlannerView registerClass:nil forEventViewWithReuseIdentifier:@"EventCellReuseIdentifier"];
			[self.dayPlannerView registerClass:MGCStandardEventView.class forEventViewWithReuseIdentifier:@"EventCellReuseIdentifier"];
		}
		[self.dayPlannerView reloadAllEvents];
	}
    else if (sender == self.dimmedTimeRangeSwitch) {
        self.weekViewController.showDimmedTimeRanges = sender.on;
        [self.dayPlannerView reloadDimmedTimeRanges];
    }
}

- (IBAction)dateAction:(id)sender
{
	if (sender == self.startDatePicker) {
		self.startDateLabel.text = [self.dateFormatter stringFromDate:self.startDatePicker.date];
		self.startDateCell.accessoryView = [self makeCancelAccessoryView];
	}
	else if (sender == self.endDatePicker) {
		self.endDateLabel.text = [self.dateFormatter stringFromDate:self.endDatePicker.date];
		self.endDateCell.accessoryView = [self makeCancelAccessoryView];
	}
}

@end

