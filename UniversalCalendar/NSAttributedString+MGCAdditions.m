//
//  NSAttributedString+MGCAdditions.m
//  Graphical Calendars Library for iOS
//
//  Distributed under the MIT License
//  Get the latest version from here:
//
//	https://github.com/jumartin/Calendar
//
//  Copyright (c) 2014-2016 Julien Martin
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

#import "NSAttributedString+MGCAdditions.h"


NSString * const MGCCircleMarkAttributeName = @"MGCCircleMarkAttributeName";


@implementation MGCCircleMark

- (instancetype)init
{
    if (self = [super init]) {
        _color = [UIColor redColor];
        _borderColor = [UIColor clearColor];
        _margin = 5.;
    }
    return self;
}

@end


@implementation NSMutableAttributedString (MGCAdditions)

- (void)processCircleMarksInRange:(NSRange)range
{
    [self enumerateAttribute:MGCCircleMarkAttributeName inRange:range options:0 usingBlock:^(id  _Nullable value, NSRange subrange, BOOL * _Nonnull stop) {
        
        if (value) {
            MGCCircleMark *circleMark = (MGCCircleMark*)value;
            
            NSAttributedString *subAttrStr = [self attributedSubstringFromRange:subrange];
            UIImage *image = [subAttrStr imageWithCircleMark:circleMark];
            
            NSTextAttachment *attachment = [NSTextAttachment new];
            attachment.image = image;
            attachment.bounds = CGRectMake(circleMark.margin, circleMark.yOffset, attachment.image.size.width, attachment.image.size.height);
            NSAttributedString *imgStr = [NSAttributedString attributedStringWithAttachment:attachment];
            
            [self replaceCharactersInRange:subrange withAttributedString:imgStr];
        }
    }];
}

@end


@implementation NSAttributedString (MGCAdditions)

- (UIImage*)imageWithCircleMark:(MGCCircleMark*)mark
{
    CGSize maxSize = CGSizeMake(CGFLOAT_MAX, CGFLOAT_MAX);
    CGRect strRect = [self boundingRectWithSize:maxSize options:NSStringDrawingUsesLineFragmentOrigin context:nil];
    CGFloat markWidth = fmaxf(strRect.size.width, strRect.size.height) + 2. * mark.margin;
    CGRect markRect = CGRectMake(0, 0, markWidth, markWidth);
    
    UIGraphicsBeginImageContextWithOptions(markRect.size, NO, 0.0f);
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    CGContextSaveGState(ctx);
    
    CGContextSetStrokeColorWithColor(ctx, mark.borderColor.CGColor);
    CGContextSetFillColorWithColor(ctx, mark.color.CGColor);
    
    CGContextAddEllipseInRect(ctx, CGRectInset(markRect, 1, 1));
    CGContextDrawPath(ctx, kCGPathFillStroke);
    
    strRect.origin = CGPointMake(markWidth/2. - strRect.size.width/2., markWidth/2. - strRect.size.height/2.);
    [self drawWithRect:strRect options:NSStringDrawingUsesLineFragmentOrigin context:nil];
    
    CGContextRestoreGState(ctx);
    UIImage *img = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return img;
}

- (NSAttributedString*)attributedStringWithProcessedCircleMarksInRange:(NSRange)range
{
    NSMutableAttributedString *attrStr = [self mutableCopy];
    [attrStr processCircleMarksInRange:range];
    return attrStr;
}

@end
