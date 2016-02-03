//
//  NSAttributedString+MGCAdditions.h
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
