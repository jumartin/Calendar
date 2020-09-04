//
//  MGCMonthPlannerBackgroundView.m
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

#import "MGCMonthPlannerBackgroundView.h"


@implementation MGCMonthPlannerBackgroundView

- (id)initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame]) {
		self.backgroundColor = [UIColor clearColor];
		self.userInteractionEnabled = NO;
		self.gridColor = [UIColor colorWithRed:.6f green:.6f blue:.6f alpha:1.];
        self.lastColumn = 7;
        self.drawHorizontalLines = YES;
        self.drawVerticalLines = YES;
	}
    return self;
}

- (void)layoutSubviews
{
	[super layoutSubviews];
	[self setNeedsDisplay];
}

- (void)drawRect:(CGRect)rect
{
	CGContextRef c = UIGraphicsGetCurrentContext();
	
	CGFloat colWidth = self.numberOfColumns > 0 ? (self.bounds.size.width / self.numberOfColumns) : self.bounds.size.width;
	CGFloat rowHeight = self.numberOfRows > 0 ? (self.bounds.size.height / self.numberOfRows) : self.bounds.size.height;
	
    CGContextSetStrokeColorWithColor(c, self.gridColor.CGColor);
	CGContextSetLineWidth(c, .5);
	
	CGContextBeginPath(c);
    
	CGFloat x1, y1, x2, y2;
	
    if (self.drawHorizontalLines) {
        for (int i = 0; i <= self.numberOfRows && self.numberOfRows != 0; i++) {
            y2 = y1 = rowHeight * i;
            x1 = i == 0 ? self.firstColumn * colWidth : 0;
            x2 = i == self.numberOfRows ? self.lastColumn * colWidth : CGRectGetMaxX(rect);
	
            CGContextMoveToPoint(c, x1, y1);
            CGContextAddLineToPoint(c, x2, y2);
        }
    }
    
    if (self.dayCellHeaderHeight > 0.0f && self.drawBottomDayLabelLines) {
        for (int i = 0; i < self.numberOfRows && self.numberOfRows != 0; i++) {
            y2 = y1 = rowHeight * i + self.dayCellHeaderHeight;
            x1 = i == 0 ? self.firstColumn * colWidth : 0;
            x2 = (i == (self.numberOfRows - 1)) ? self.lastColumn * colWidth : CGRectGetMaxX(rect);
            
            CGContextMoveToPoint(c, x1, y1);
            CGContextAddLineToPoint(c, x2, y2);
        }
    }
	
    if (self.drawVerticalLines) {
        for (int j = 0; j <= self.numberOfColumns; j++) {
            x2 = x1 = colWidth * j;
            y1 = j < self.firstColumn ? rowHeight : 0;
            y2 = j <= self.lastColumn ? self.numberOfRows * rowHeight : (self.numberOfRows - 1) * rowHeight;
		
            CGContextMoveToPoint(c, x1, y1);
            CGContextAddLineToPoint(c, x2, y2);
        }
    }
    
	CGContextStrokePath(c);
}

@end
