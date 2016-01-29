//
//  NSAttributedString+MGCAdditions.m
//  Calendar
//
//  Created by Julien Martin on 03/02/2016.
//  Copyright © 2016 Julien Martin. All rights reserved.
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
