//
//  MGCAlignedGeometry.m
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
#import "MGCAlignedGeometry.h"


CGRect MGCAlignedRect(CGRect rect)
{
    CGFloat scale = [UIScreen mainScreen].scale;
    return CGRectMake(floorf(rect.origin.x * scale) / scale, floorf(rect.origin.y * scale) / scale, ceilf(rect.size.width * scale) / scale, ceilf(rect.size.height * scale) / scale);
}

CGRect MGCAlignedRectMake(CGFloat x, CGFloat y, CGFloat width, CGFloat height)
{
    return MGCAlignedRect(CGRectMake(x, y, width, height));
}

CGSize MGCAlignedSize(CGSize size)
{
    CGFloat scale = [UIScreen mainScreen].scale;
    return CGSizeMake(ceilf(size.width * scale) / scale, ceilf(size.height * scale) / scale);
}

CGSize MGCAlignedSizeMake(CGFloat width, CGFloat height)
{
    return MGCAlignedSize(CGSizeMake(width, height));
}

CGPoint MGCAlignedPoint(CGPoint point)
{
    CGFloat scale = [UIScreen mainScreen].scale;
    return CGPointMake(floorf(point.x * scale) / scale, floorf(point.y * scale) / scale);
}

CGPoint MGCAlignedPointMake(CGFloat x, CGFloat y)
{
    return MGCAlignedPoint(CGPointMake(x, y));
}

CGFloat MGCAlignedFloat(CGFloat f)
{
    CGFloat scale = [UIScreen mainScreen].scale;
    return roundf(f * scale) / scale;
}

