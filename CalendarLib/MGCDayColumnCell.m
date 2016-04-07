//
//  MGCDayColumnCell.m
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

#import "MGCDayColumnCell.h"


static const CGFloat dotSize = 4;


@interface MGCDayColumnCell ()

@property (nonatomic) UIActivityIndicatorView *activityIndicatorView;
@property (nonatomic) CAShapeLayer *dotLayer;
@property (nonatomic) CALayer *leftBorder;

@end


@implementation MGCDayColumnCell

- (instancetype)initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame]) {
		_markColor = [UIColor blackColor];
		_dotColor = [UIColor blueColor];
        _separatorColor = [UIColor lightGrayColor];
		_headerHeight = 50;
		
		_dayLabel = [[UILabel alloc] initWithFrame:CGRectNull];
		_dayLabel.numberOfLines = 0;
		_dayLabel.adjustsFontSizeToFitWidth = YES;
		_dayLabel.minimumScaleFactor = .7;
		[self.contentView addSubview:_dayLabel];
		
		_dotLayer = [CAShapeLayer layer];
		CGPathRef dotPath = CGPathCreateWithEllipseInRect(CGRectMake(0, 0, dotSize, dotSize), NULL);
		_dotLayer.path = dotPath;
		_dotLayer.bounds = CGPathGetBoundingBox(dotPath);
		CGPathRelease(dotPath);
		_dotLayer.fillColor = _markColor.CGColor;
		_dotLayer.hidden = YES;
		[self.contentView.layer addSublayer:_dotLayer];
		
		_leftBorder = [CALayer layer];
		[self.contentView.layer addSublayer:_leftBorder];
	}
    return self;
}

- (void)setActivityIndicatorVisible:(BOOL)visible
{
    if (!visible) {
        [self.activityIndicatorView stopAnimating];
    }
    else if (self.headerHeight > 0) {
        if (!self.activityIndicatorView) {
            self.activityIndicatorView = [[UIActivityIndicatorView alloc]initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
            self.activityIndicatorView.color = [UIColor blackColor];
            self.activityIndicatorView.transform = CGAffineTransformMakeScale(0.6, 0.6);
            [self.contentView addSubview:self.activityIndicatorView];
        }
        [self.activityIndicatorView startAnimating];
    }
}

- (void)prepareForReuse
{
    [super prepareForReuse];
    
    self.accessoryTypes = MGCDayColumnCellAccessoryNone;
    self.markColor = [UIColor blackColor];
    [self setActivityIndicatorVisible:NO];
}

- (void)layoutSubviews
{
	[super layoutSubviews];
	
	static CGFloat kSpace = 2;

	[CATransaction begin];
	[CATransaction setDisableActions:YES];

	if (self.headerHeight != 0) {
		CGSize headerSize = CGSizeMake(self.contentView.bounds.size.width, self.headerHeight);
		CGSize labelSize = CGSizeMake(headerSize.width - 2*kSpace, headerSize.height - (2 * dotSize + 2 * kSpace));
		self.dayLabel.frame = (CGRect) { 2, 0, labelSize };
		
		self.dotLayer.position = CGPointMake(self.contentView.center.x, headerSize.height - 1.2 * dotSize);
		self.dotLayer.fillColor = self.dotColor.CGColor;
		self.activityIndicatorView.center = CGPointMake(self.contentView.center.x, headerSize.height - 1.2 * dotSize);
		
		if (self.accessoryTypes & MGCDayColumnCellAccessoryMark) {
			self.dayLabel.layer.cornerRadius = 6;
			self.dayLabel.layer.backgroundColor = self.markColor.CGColor;
		}
		else  {
			self.dayLabel.layer.cornerRadius = 0;
			self.dayLabel.layer.backgroundColor = [UIColor clearColor].CGColor;
		}
	}
	
	self.dotLayer.hidden = !(self.accessoryTypes & MGCDayColumnCellAccessoryDot) || self.headerHeight == 0;
	self.dayLabel.hidden = (self.headerHeight == 0);

    // border
    CGRect borderFrame = CGRectZero;
    if (self.accessoryTypes & MGCDayColumnCellAccessoryBorder) {
        borderFrame = CGRectMake(0, self.headerHeight, 1./[UIScreen mainScreen].scale, self.contentView.bounds.size.height-self.headerHeight);
    }
    else if (self.accessoryTypes & MGCDayColumnCellAccessorySeparator) {
        borderFrame = CGRectMake(0, 0, 2./[UIScreen mainScreen].scale, self.contentView.bounds.size.height);
    }
    
    self.leftBorder.frame = borderFrame;
    self.leftBorder.borderColor = self.separatorColor.CGColor;
    self.leftBorder.borderWidth = borderFrame.size.width / 2.;

	[CATransaction commit];
}

- (void)setAccessoryTypes:(MGCDayColumnCellAccessoryType)accessoryTypes
{
    _accessoryTypes = accessoryTypes;
    [self setNeedsLayout];
}

@end
