//
//  MGCCalendarHeaderCell.m
//  Calendar
//
//  Copyright © 2016 Julien Martin. All rights reserved.
//

#import "MGCCalendarHeaderCell.h"

@interface MGCCalendarHeaderCell ()

@property (nonatomic, assign, getter=isToday) BOOL today;
@property (nonatomic, assign, getter=isWeekend) BOOL weekend;

//colors
@property (nonatomic, strong) UIColor *selectedDayBackgroundColor;
@property (nonatomic, strong) UIColor *selectedDayTextColor;
@property (nonatomic, strong) UIColor *todayColor;
@property (nonatomic, strong) UIColor *weekendColor;


@end

@implementation MGCCalendarHeaderCell

- (instancetype)initWithCoder:(NSCoder*)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {        
        self.selectedDayBackgroundColor = [UIColor darkGrayColor];
        self.selectedDayTextColor = [UIColor whiteColor];
        self.todayColor = [UIColor redColor];
        self.weekendColor = [UIColor grayColor];
    }
    return self;
}

- (void)setDate:(NSDate *)date{
    _date = date;
    
    NSDateFormatter* dateFormatter = [[NSDateFormatter alloc] init];
    
    [dateFormatter setDateFormat:@"E"];
    
    self.dayNameLabel.text = [dateFormatter stringFromDate:date];
    
    [dateFormatter setDateFormat:@"d"];
    
    self.dayNumberLabel.text = [dateFormatter stringFromDate:date];
    
    //the cell is the current day
    self.today = [[NSCalendar currentCalendar] isDate:[NSDate date] inSameDayAsDate:date];
    
    //tthe cell is a weekend day
    self.weekend = [[NSCalendar currentCalendar] isDateInWeekend:date];
}

- (void)setSelected:(BOOL)selected{
    
    [super setSelected:selected];
    
    //force layout to color the view
    [self setNeedsLayout];
    
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    if (self.isSelected) {
        self.dayNumberLabel.backgroundColor = self.selectedDayBackgroundColor;
        self.dayNumberLabel.layer.masksToBounds = YES;
        self.dayNumberLabel.layer.cornerRadius = 15.0;
        self.dayNumberLabel.textColor = self.selectedDayTextColor;
    }
    else {
        self.dayNumberLabel.backgroundColor = [UIColor clearColor];
        self.dayNumberLabel.textColor = self.selectedDayBackgroundColor;
    }
    
    if (self.isToday) {
        self.dayNumberLabel.textColor = self.todayColor;
        self.dayNameLabel.textColor = self.todayColor;
    }
    if (self.isWeekend && !self.isToday) {
        self.dayNumberLabel.textColor = self.weekendColor;
        self.dayNameLabel.textColor = self.weekendColor;
    }
}

- (void)prepareForReuse
{
    [super prepareForReuse];

    self.dayNameLabel.textColor = [UIColor blackColor];
    self.dayNumberLabel.textColor = [UIColor blackColor];
    self.today = NO;
    self.weekend = NO;
    self.selectedDayBackgroundColor = [UIColor darkGrayColor];
    self.selectedDayTextColor = [UIColor whiteColor];
    self.todayColor = [UIColor redColor];
    self.weekendColor = [UIColor grayColor];
}

@end
