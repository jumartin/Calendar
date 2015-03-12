//
//  MGCMonthPlannerViewDayCell.m
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

#import "MGCMonthPlannerViewDayCell.h"


@implementation MGCMonthPlannerViewDayCell

- (id)initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame]) {
		self.backgroundColor = [UIColor whiteColor];
		
		self.dayLabel = [[UILabel alloc]initWithFrame:CGRectNull];
		self.dayLabel.textAlignment = NSTextAlignmentCenter;
		self.dayLabel.font = [UIFont systemFontOfSize:10];
		[self.contentView addSubview:self.dayLabel];
		
		UIView *view = [UIView new];
		view.backgroundColor = [UIColor colorWithWhite:.7 alpha:.2];
		self.selectedBackgroundView = view;
    }
    return self;
}

- (void)prepareForReuse
{
	self.marked = NO;
}

- (void)setMarked:(BOOL)marked
{
	_marked = marked;
	self.dayLabel.textColor = marked ? [UIColor redColor] : [UIColor blackColor];
	self.dayLabel.layer.cornerRadius = marked ? 10. : 0.;
}

- (void)layoutSubviews
{
	[super layoutSubviews];
	self.dayLabel.frame = CGRectMake(0, 0, self.contentView.bounds.size.width, 20);
}

@end
