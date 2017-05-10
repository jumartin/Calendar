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

static const CGFloat kHeaderMargin = 1;
static const CGFloat kDotSize = 8;


@interface MGCMonthPlannerViewDayCell ()

@property (nonatomic) CAShapeLayer *dotLayer;

@end


@implementation MGCMonthPlannerViewDayCell

- (id)initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame]) {
        self.headerHeight = 20;
        self.backgroundColor = [UIColor whiteColor];
        
        self.dayLabel = [[UILabel alloc]initWithFrame:CGRectNull];
        self.dayLabel.font = [UIFont systemFontOfSize:[UIFont smallSystemFontSize]];
        self.dayLabel.numberOfLines = 1;
        self.dayLabel.adjustsFontSizeToFitWidth = YES;
        
        [self.contentView addSubview:self.dayLabel];
        
        self.dotLayer = [CAShapeLayer layer];
        self.dotLayer.path = [UIBezierPath bezierPathWithOvalInRect:CGRectMake(0, 0, kDotSize, kDotSize)].CGPath;;
        self.dotLayer.fillColor = [UIColor redColor].CGColor;
        self.dotLayer.hidden = YES;
        [self.contentView.layer addSublayer:self.dotLayer];
      
        UIView *view = [UIView new];
        view.backgroundColor = [UIColor colorWithWhite:.7 alpha:.2];
        self.selectedBackgroundView = view;
    }
    return self;
}

- (void)prepareForReuse
{
    self.showsDot = NO;
}

- (void)setDotColor:(UIColor *)dotColor
{
    self.dotLayer.fillColor = dotColor.CGColor;
}

- (UIColor*)dotColor
{
    return [UIColor colorWithCGColor:self.dotLayer.fillColor];
}

- (void)setShowsDot:(BOOL)showsDot
{
    _showsDot = showsDot;
    
    [CATransaction begin];
    [CATransaction setValue:(id)kCFBooleanTrue forKey: kCATransactionDisableActions];
    self.dotLayer.hidden = !showsDot;
    [CATransaction commit];
}

- (void)setHeaderHeight:(CGFloat)headerHeight
{
    _headerHeight = headerHeight;
    [self setNeedsLayout];
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    CGRect headerFrame = CGRectMake(0, 0, self.contentView.bounds.size.width, self.headerHeight);
    self.dayLabel.frame =  CGRectInset(headerFrame, kHeaderMargin, kHeaderMargin);
    
    CGRect contentFrame = CGRectMake(0, self.headerHeight, self.contentView.bounds.size.width, self.contentView.bounds.size.height - self.headerHeight);
    contentFrame = CGRectInset(contentFrame, kHeaderMargin, kHeaderMargin);
    
    CGFloat dotSize = fminf(fminf(contentFrame.size.height, contentFrame.size.width), kDotSize);
    CGRect dotFrame = CGRectMake(CGRectGetMidX(contentFrame)-dotSize*.5, CGRectGetMidY(contentFrame)-dotSize*.5, dotSize, dotSize);
    
    self.dotLayer.frame = dotFrame;
    
}

@end
