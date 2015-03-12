//
//  MGCTimeRowsView.m
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

#import "MGCTimeRowsView.h"
#import "NSCalendar+MGCAdditions.h"


@interface MGCTimeRowsView()

@property (nonatomic) NSTimer *timer;
@property (nonatomic) NSUInteger rounding;

@end


@implementation MGCTimeRowsView

- (id)initWithFrame:(CGRect)frame
{
	if (self = [super initWithFrame:frame]) {
		self.backgroundColor = [UIColor clearColor];
		
		_calendar = [NSCalendar currentCalendar];
		_hourSlotHeight = 65;
		_insetsHeight = 45;
		_timeColumnWidth = 40;
		_font = [UIFont boldSystemFontOfSize:12];
		_timeColor = [UIColor lightGrayColor];
		_currentTimeColor = [UIColor redColor];
		_rounding = 15;
		
		self.showsCurrentTime = YES;
	}
	return self;
}

- (void)setShowsCurrentTime:(BOOL)showsCurrentTime
{
	_showsCurrentTime = showsCurrentTime;
	
	[self.timer invalidate];
	if (_showsCurrentTime) {
		self.timer = [NSTimer scheduledTimerWithTimeInterval:60 target:self selector:@selector(timeChanged:) userInfo:nil repeats:YES];
	}
	
	[self setNeedsDisplay];
}

- (BOOL)showsHalfHourLines
{
	return self.hourSlotHeight > 100;
}

- (void)setTimeMark:(NSTimeInterval)timeMark
{
	_timeMark = timeMark;
	[self setNeedsDisplay];
}

- (void)timeChanged:(NSDictionary*)dictionary
{
	[self setNeedsDisplay];
}

// time is the interval since the start of the day
- (CGFloat)yOffsetForTime:(NSTimeInterval)time rounded:(BOOL)rounded
{
	if (rounded) {
		time = roundf(time / (self.rounding * 60)) * (self.rounding * 60);
	}
	
	CGFloat hour = time / 3600.;
	return hour * self.hourSlotHeight + self.insetsHeight;
}

// time is the interval since the start of the day
- (NSString*)stringForTime:(NSTimeInterval)time rounded:(BOOL)rounded minutesOnly:(BOOL)minutesOnly
{
	if (rounded) {
		time = roundf(time / (self.rounding * 60)) * (self.rounding * 60);
	}
	
	int hour = (int)(time / 3600) % 24;
	int minutes = ((int)time % 3600) / 60;

	if (minutesOnly) {
		return [NSString stringWithFormat:@":%02d", minutes];
	}
	return [NSString stringWithFormat:@"%02d:%02d", hour, minutes];
}

- (void)drawRect:(CGRect)rect
{
	const CGFloat kSpacing = 5.;
	const CGFloat dash[2]= {2, 3};
	
	CGContextRef context = UIGraphicsGetCurrentContext();
	
	// calculate rect for current time mark
	NSTimeInterval currentTime = -[[self.calendar mgc_startOfDayForDate:[NSDate date]] timeIntervalSinceNow];
	NSString *s = [self stringForTime:currentTime rounded:NO minutesOnly:NO];
	CGSize size = [s sizeWithAttributes:@{ NSFontAttributeName:self.font }];
	
	CGFloat y = [self yOffsetForTime:currentTime rounded:NO];
	CGPoint pt = CGPointMake(self.timeColumnWidth - (size.width + kSpacing), y - size.height / 2.);
	CGRect rectCurTime = CGRectMake(pt.x, pt.y, size.width, size.height);
	
	// draw current time mark
	if (self.showsCurrentTime) {
		[s drawAtPoint:pt withAttributes:@{ NSFontAttributeName:self.font, NSForegroundColorAttributeName:self.currentTimeColor }];
		CGRect lineRect = CGRectMake(self.timeColumnWidth - kSpacing, y, rect.size.width - self.timeColumnWidth + kSpacing, 1);
		UIRectFill(lineRect);
	}
	
	// calculate rect for the small time mark
	NSString *strTimeMark = [self stringForTime:self.timeMark rounded:YES minutesOnly:YES];
	size = [strTimeMark sizeWithAttributes:@{ NSFontAttributeName:self.font }];
	y = [self yOffsetForTime:self.timeMark rounded:YES];
	CGPoint ptTimeMark = CGPointMake(self.timeColumnWidth - (size.width + kSpacing), y - size.height / 2.);
	CGRect rectTimeMark = CGRectMake(ptTimeMark.x, ptTimeMark.y, size.width, size.height);
	
	BOOL drawTimeMark = (self.timeMark != 0) && !CGRectIntersectsRect(rectTimeMark, rectCurTime);
	
	CGContextSetStrokeColorWithColor(context, self.timeColor.CGColor);
	
	// draw the hour marks
	for (int i = 0; i <= 24; i++) {
		
		s = [NSString stringWithFormat:@"%02d:00", i % 24];
		size = [s sizeWithAttributes:@{ NSFontAttributeName:self.font }];
		y = i * self.hourSlotHeight + self.insetsHeight;
		pt = CGPointMake(self.timeColumnWidth - (size.width + kSpacing), y - size.height / 2.);
		CGRect r = CGRectMake(pt.x, pt.y, size.width, size.height);

		if (!CGRectIntersectsRect(r, rectCurTime) || !self.showsCurrentTime) {
			[s drawAtPoint:pt withAttributes:@{ NSFontAttributeName:self.font, NSForegroundColorAttributeName:self.timeColor }];
		}
		
		CGContextSetLineDash(context, 0, NULL, 0);
		CGContextMoveToPoint(context, self.timeColumnWidth, y),
		CGContextAddLineToPoint(context, self.timeColumnWidth + rect.size.width, y);
		CGContextStrokePath(context);
		
		if (self.showsHalfHourLines && i != 24) {
			y += self.hourSlotHeight / 2;
			CGContextSetLineDash(context, 0, dash, 2);
			CGContextMoveToPoint(context, self.timeColumnWidth, y),
			CGContextAddLineToPoint(context, self.timeColumnWidth + rect.size.width, y);
			CGContextStrokePath(context);
		}
		
		// don't draw time mark if it intersects any other mark
		drawTimeMark &= !CGRectIntersectsRect(r, rectTimeMark);
	}

	if (drawTimeMark) {
		[strTimeMark drawAtPoint:ptTimeMark withAttributes:@{ NSFontAttributeName:self.font, NSForegroundColorAttributeName:self.timeColor }];
	}
}

@end
