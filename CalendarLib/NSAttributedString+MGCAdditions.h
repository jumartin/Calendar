//
//  NSAttributedString+MGCAdditions.h
//  Calendar
//
//  Created by Julien Martin on 03/02/2016.
//  Copyright © 2016 Julien Martin. All rights reserved.
//

#import <Foundation/Foundation.h>


extern NSString * const MGCCircleMarkAttributeName;


// MGCCircleMark can be used as an attribute for NSAttributedString to draw a circle mark behing the text
@interface MGCCircleMark : NSObject

@property (nonatomic) UIColor *borderColor; // default is clear
@property (nonatomic) UIColor *color;       // default is red
@property (nonatomic) CGFloat margin;       // padding on each side of the text
@property (nonatomic) CGFloat yOffset;      // vertical position adjustment

@end


@interface NSAttributedString (MGCAdditions)

- (UIImage*)imageWithCircleMark:(MGCCircleMark*)mark;
- (NSAttributedString*)attributedStringWithProcessedCircleMarksInRange:(NSRange)range;

@end


@interface NSMutableAttributedString (MGCAdditions)

- (void)processCircleMarksInRange:(NSRange)range;

@end
