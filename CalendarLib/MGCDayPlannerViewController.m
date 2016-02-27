//
//  MGCDayPlannerViewController.m
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

#import "MGCDayPlannerViewController.h"
#import "MGCDateRange.h"

@interface MGCDayPlannerViewController ()

@property (nonatomic, copy) NSDate *firstVisibleDayForRotation;

@end

@implementation MGCDayPlannerViewController

- (MGCDayPlannerView*)dayPlannerView
{
	return (MGCDayPlannerView*)self.view;
}

- (void)setDayPlannerView:(MGCDayPlannerView*)dayPlannerView
{
	[super setView:dayPlannerView];
	
	if (!dayPlannerView.dataSource)
		dayPlannerView.dataSource = self;
	
	if (!dayPlannerView.delegate)
		dayPlannerView.delegate = self;
}

#pragma mark - UIViewController

- (void)loadView
{
	MGCDayPlannerView *dayPlannerView = [[MGCDayPlannerView alloc]initWithFrame:CGRectZero];
	dayPlannerView.autoresizingMask = UIViewAutoresizingFlexibleHeight|UIViewAutoresizingFlexibleWidth;
	self.dayPlannerView = dayPlannerView;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

#pragma mark - MGCDayPlannerViewDataSource

- (NSInteger)dayPlannerView:(MGCDayPlannerView *)view numberOfEventsOfType:(MGCEventType)type atDate:(NSDate *)date
{
	return 0;
}

- (MGCEventView*)dayPlannerView:(MGCDayPlannerView*)view viewForEventOfType:(MGCEventType)type atIndex:(NSUInteger)index date:(NSDate*)date
{
	NSLog(@"dayPlannerView:viewForEventOfType:atIndex:date: has to implemented in MGCDayPlannerViewController subclasses.");
	return nil;
}

- (MGCDateRange*)dayPlannerView:(MGCDayPlannerView*)view dateRangeForEventOfType:(MGCEventType)type atIndex:(NSUInteger)index date:(NSDate*)date
{
	NSLog(@"dayPlannerView:dateRangeForEventOfType:atIndex:date: has to implemented in MGCDayPlannerViewController subclasses.");
	return nil;
}

#pragma mark - MGCDayPlannerViewDelegate

- (void)dayPlannerView:(MGCDayPlannerView*)view willStartMovingCellForEventOfType:(MGCEventType)type atIndex:(NSUInteger)index date:(NSDate*)date
{
}

- (void)dayPlannerView:(MGCDayPlannerView*)view didMoveEventToDate:(NSDate*)date type:(MGCEventType)type
{
}

@end
