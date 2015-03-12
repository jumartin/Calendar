//
//  MGCMonthPlannerViewController.m
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

#import "MGCMonthPlannerViewController.h"

@interface MGCMonthPlannerViewController ()

@end

@implementation MGCMonthPlannerViewController

- (MGCMonthPlannerView*)monthPlannerView
{
	return (MGCMonthPlannerView*)self.view;
}

- (void)setMonthPlannerView:(MGCMonthPlannerView*)monthPlannerView
{
	[super setView:monthPlannerView];
	
	if (!monthPlannerView.dataSource)
		monthPlannerView.dataSource = self;
	
	if (!monthPlannerView.delegate)
		monthPlannerView.delegate = self;
}

- (void)loadView
{
	if (self.nibName)
	{
		[super loadView];
		NSAssert(self.monthPlannerView != nil, @"NIB file did not set monthPlannerView property.");
		return;
	}
	
	MGCMonthPlannerView *monthPlannerView = [[MGCMonthPlannerView alloc]initWithFrame:CGRectZero];
	monthPlannerView.autoresizingMask = UIViewAutoresizingFlexibleHeight|UIViewAutoresizingFlexibleWidth;
	self.monthPlannerView = monthPlannerView;
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

#pragma mark - MGCMonthPlannerViewDataSource

- (NSInteger)monthPlannerView:(MGCMonthPlannerView*)view numberOfEventsAtDate:(NSDate*)date
{
	return 0;
}

- (MGCEventView*)monthPlannerView:(MGCMonthPlannerView*)view cellForEventAtIndex:(NSUInteger)index date:(NSDate*)date
{
	assert(@"monthPlannerView:cellForEventAtIndex:date: has to implemented in MGCMonthPlannerViewController subclasses.");
	return nil;
}

- (MGCDateRange*)monthPlannerView:(MGCMonthPlannerView*)view dateRangeForEventAtIndex:(NSUInteger)index date:(NSDate*)date
{
	assert(@"monthPlannerView:dateRangeForEventAtIndex:date: has to implemented in MGCMonthPlannerViewController subclasses.");
	return nil;
}

- (MGCEventView*)monthPlannerView:(MGCMonthPlannerView *)view cellForNewEventAtDate:(NSDate*)date
{
	assert(@"monthPlannerView:cellForNewEventAtDate: has to implemented in MGCMonthPlannerViewController subclasses.");
	return nil;
}


@end
