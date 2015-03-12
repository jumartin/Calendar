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

@property (nonatomic, strong) NSDateFormatter *dateFormatter;

@property (nonatomic, weak) IBOutlet UILabel *visibleDaysLabel;
@property (nonatomic, weak) IBOutlet UIStepper *visibleDaysStepper;

@property (nonatomic) IBOutlet UISwitch *pagingSwitch;
@property (nonatomic) IBOutlet UISwitch *zoomingSwitch;

@property (nonatomic) IBOutlet UISwitch *allDayEventSwitch;

@property (nonatomic, strong) IBOutlet UIDatePicker *startDatePicker;
@property (nonatomic, strong) IBOutlet UITableViewCell *startDateCell;
@property (nonatomic) IBOutlet UILabel *startDateLabel;

@property (nonatomic, strong) IBOutlet UIDatePicker *endDatePicker;
@property (nonatomic, strong) IBOutlet UITableViewCell *endDateCell;
@property (nonatomic) IBOutlet UILabel *endDateLabel;

@property (nonatomic) BOOL showsStartDatePicker, showsEndDatePicker;

@property (nonatomic) IBOutlet UISwitch *eventCreationSwitch;
@property (nonatomic) IBOutlet UISwitch *eventMovingSwitch;
@property (nonatomic) IBOutlet UISwitch *eventSelectionSwitch;

@property (nonatomic) IBOutlet UISwitch *customCellSwitch;

@end


@implementation WeekSettingsViewController

- (UIView*)makeCancelAccessoryView
{
	UIView *view = [[UIView alloc]initWithFrame:CGRectMake(0, 0, 30, 22)];
	
	UIButton *cancelButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
	cancelButton.frame = CGRectMake(8, 0, 22, 22);
	[cancelButton setTitle:@"x" forState:UIControlStateNormal];
	cancelButton.clipsToBounds = YES;
	cancelButton.layer.cornerRadius = 5;
	cancelButton.layer.borderWidth = 1;
	cancelButton.layer.borderColor = [[UIColor blueColor]CGColor];
	[cancelButton addTarget:self action:@selector(accessoryButtonTapped:withEvent:) forControlEvents:UIControlEventTouchUpInside];
	
	[view addSubview:cancelButton];
	return view;
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

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section
{
	if (section == 2 && [self.startDatePicker.date compare:self.endDatePicker.date] != NSOrderedAscending) {
		return 20;
	}
	return 0;
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
	NSDate* date = self.dayPlannerView.visibleDays.start;
	self.visibleDaysLabel.text = [NSString stringWithFormat:@"%1.0f", sender.value];
	self.dayPlannerView.numberOfVisibleDays  = sender.value;
	if (sender.value <= 3) {
		self.dayPlannerView.dateFormat = @"eeee d MMMM";
	}
	else {
		self.dayPlannerView.dateFormat = @"eeeee\nd MMM";
	}
	[self.dayPlannerView scrollToDate:date options:MGCDayPlannerScrollDate animated:NO];
}

- (IBAction)switchToggled:(UISwitch*)sender
{
	if (sender == self.pagingSwitch) {
		self.dayPlannerView.pagingEnabled = sender.on;
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

