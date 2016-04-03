//
//  MonthSettingsViewController.m
//  CalendarDemo - Graphical Calendars Library for iOS
//
//  Copyright (c) 2014-2015 Julien Martin. All rights reserved.
//

#import "MonthSettingsViewController.h"
#import "MGCDateRange.h"
#import "NSCalendar+MGCAdditions.h"
#import "MGCStandardEventView.h"


const NSUInteger kStyleSection = 1;
const NSUInteger kPagingSection = 2;
const NSUInteger kDateRangeSection = 4;


@interface MonthSettingsViewController ()

@property (nonatomic) NSDateFormatter *dateFormatter;

@property (nonatomic) IBOutlet UIDatePicker *startDatePicker;
@property (nonatomic) IBOutlet UITableViewCell *startDateCell;
@property (nonatomic) IBOutlet UILabel *startDateLabel;

@property (nonatomic) IBOutlet UIDatePicker *endDatePicker;
@property (nonatomic) IBOutlet UITableViewCell *endDateCell;
@property (nonatomic) IBOutlet UILabel *endDateLabel;

@property (nonatomic) BOOL showsStartDatePicker, showsEndDatePicker;

@property (nonatomic) IBOutlet UISwitch *fillGridSwitch;
@property (nonatomic) IBOutlet UISwitch *horzLinesSwitch;
@property (nonatomic) IBOutlet UISwitch *vertLinesSwitch;
@property (nonatomic) IBOutlet UISwitch *monthHeadersSwitch;
@property (nonatomic) IBOutlet UISwitch *eventSelectionSwitch;

@end


@implementation MonthSettingsViewController

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

- (void)setStyle
{
    MGCMonthPlannerGridStyle gridStyle = 0;
    if (self.fillGridSwitch.on) gridStyle |= MGCMonthPlannerGridStyleFill;
    if (self.horzLinesSwitch.on) gridStyle |= MGCMonthPlannerGridStyleHorizontalLines;
    if (self.vertLinesSwitch.on) gridStyle |= MGCMonthPlannerGridStyleVerticalLines;
    self.monthPlannerView.gridStyle = gridStyle;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	
	self.dateFormatter = [[NSDateFormatter alloc] init];
    self.dateFormatter.dateFormat = @"MMMM YYYY";
		
	if (self.monthPlannerView.dateRange) {
		self.startDatePicker.date = self.monthPlannerView.dateRange.start;
		self.startDateLabel.text = [self.dateFormatter stringFromDate:self.startDatePicker.date];
		
		NSDate *end = [self.monthPlannerView.dateRange.end dateByAddingTimeInterval:-1];
        self.endDatePicker.date = end;
		self.endDateLabel.text = [self.dateFormatter stringFromDate:end];
		
        self.startDatePicker.maximumDate = self.monthPlannerView.dateRange.end; //end;
		self.endDatePicker.minimumDate = self.monthPlannerView.dateRange.start;
		
		self.startDateCell.accessoryView = [self makeCancelAccessoryView];
		self.endDateCell.accessoryView = [self makeCancelAccessoryView];
	}
		
    self.fillGridSwitch.on = self.monthPlannerView.gridStyle & MGCMonthPlannerGridStyleFill;
    self.horzLinesSwitch.on = self.monthPlannerView.gridStyle & MGCMonthPlannerGridStyleHorizontalLines;
    self.vertLinesSwitch.on = self.monthPlannerView.gridStyle & MGCMonthPlannerGridStyleVerticalLines;
    
    self.monthHeadersSwitch.on = !(self.monthPlannerView.monthHeaderStyle & MGCMonthHeaderStyleHidden);
    self.eventSelectionSwitch.on = self.monthPlannerView.allowsSelection;
    
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
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
		NSDate *start = [self.monthPlannerView.calendar mgc_startOfMonthForDate:self.startDatePicker.date];
		NSDate *end = [self.monthPlannerView.calendar mgc_nextStartOfMonthForDate:self.endDatePicker.date];
		self.monthPlannerView.dateRange = [MGCDateRange dateRangeWithStart:start end:end];
	}
	else {
		self.monthPlannerView.dateRange = nil;
	}
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath*)indexPath
{
    if (indexPath.section == kStyleSection) {
        self.monthPlannerView.style = indexPath.item;
        [tableView reloadSections:[NSIndexSet indexSetWithIndex:kStyleSection] withRowAnimation:UITableViewRowAnimationNone];
        return;
    }
    else if (indexPath.section == kPagingSection) {
        self.monthPlannerView.pagingMode = indexPath.item;
        [tableView reloadSections:[NSIndexSet indexSetWithIndex:kPagingSection] withRowAnimation:UITableViewRowAnimationNone];
        return;
    }

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

- (UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [super tableView:tableView cellForRowAtIndexPath:indexPath];
    if (indexPath.section == kStyleSection) {
        cell.accessoryType = (self.monthPlannerView.style == indexPath.item) ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
    }
    else if (indexPath.section == kPagingSection) {
        cell.accessoryType = (self.monthPlannerView.pagingMode == indexPath.item) ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
    }
    return cell;
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
	if (indexPath.section == kDateRangeSection && ((indexPath.row == 1 && !self.showsStartDatePicker) || (indexPath.row == 3 && !self.showsEndDatePicker))) {
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

- (IBAction)switchToggled:(UISwitch*)sender
{
    if (sender == self.fillGridSwitch || sender == self.horzLinesSwitch || sender == self.vertLinesSwitch) {
        [self setStyle];
    }
    else if (sender == self.monthHeadersSwitch) {
        self.monthPlannerView.monthHeaderStyle = self.monthHeadersSwitch.on ? MGCMonthHeaderStyleShort : MGCMonthHeaderStyleHidden;
    }
    else if (sender == self.eventSelectionSwitch) {
        self.monthPlannerView.allowsSelection = sender.on;
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

