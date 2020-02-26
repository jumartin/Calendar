//
//  MGCDateRange.m
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

#import "MGCDateRange.h"
#import "NSCalendar+MGCAdditions.h"

#define NSUINT_BIT (CHAR_BIT * sizeof(NSUInteger))
#define NSUINTROTATE(val, b) ((((NSUInteger)val) << b) | (((NSUInteger)val) >> (NSUINT_BIT - b)))


static NSDateFormatter *dateFormatter;

@interface MGCDateRange ()

@property (nonatomic, readonly) NSDateFormatter *dateFormatter;  // for debugging only

@end


@implementation MGCDateRange

- (void)checkIfValid
{
	NSAssert([self.start compare:self.end] != NSOrderedDescending, @"End date earlier than start date in DateRange object!");
}

+ (instancetype)dateRangeWithStart:(NSDate*)start end:(NSDate*)end
{
	return [[self alloc] initWithStart:start end:end];
}

- (instancetype)initWithStart:(NSDate*)start end:(NSDate*)end
{
	if (self = [super init]) {
		_start = [start copy];
		_end = [end copy];
	}
	
	[self checkIfValid];
	
	return self;
}

// for debugging
- (NSDateFormatter*)dateFormatter
{
	if (!dateFormatter) {
		dateFormatter = [NSDateFormatter new];
		dateFormatter.dateStyle = NSDateFormatterMediumStyle;
		dateFormatter.timeStyle = NSDateFormatterMediumStyle;
	}
	return dateFormatter;
}

- (NSDateComponents*)components:(NSCalendarUnit)unitFlags forCalendar:(NSCalendar*)calendar
{
	[self checkIfValid];
	
	return [calendar components:unitFlags fromDate:self.start toDate:self.end options:0];
}

- (BOOL)containsDate:(NSDate*)date
{
	[self checkIfValid];
	
	return ([date compare:self.start] != NSOrderedAscending && [date compare:self.end] == NSOrderedAscending);
}

- (void)intersectDateRange:(MGCDateRange*)range
{
	[self checkIfValid];

	// range.end <= start || end <= range.start
    if ([range.end compare:self.start] != NSOrderedDescending || [self.end compare:range.start] != NSOrderedDescending) {
        self.end = self.start;
        return;
    }

	if ([self.start compare:range.start] == NSOrderedAscending) {
		self.start = range.start;
	}
	if ([range.end compare:self.end] == NSOrderedAscending) {
		self.end = range.end;
	}
}

- (BOOL)intersectsDateRange:(MGCDateRange*)range
{
	if ([range.end compare:self.start] != NSOrderedDescending || [self.end compare:range.start] != NSOrderedDescending)
		return NO;
	return YES;
}

- (BOOL)includesDateRange:(MGCDateRange*)range
{
	if ([range.start compare:self.start] == NSOrderedAscending || [self.end compare:range.end] == NSOrderedAscending)
		return NO;
	return YES;
}

- (void)unionDateRange:(MGCDateRange*)range
{
	[self checkIfValid];
	[range checkIfValid];
	
	self.start = [self.start earlierDate:range.start];
	self.end = [self.end laterDate:range.end];
}

- (void)enumerateDaysWithCalendar:(NSCalendar*)calendar usingBlock:(void (^)(NSDate *day, BOOL *stop))block
{
	NSDateComponents *comp = [NSDateComponents new];
	comp.day = 1;

	NSDate *date = self.start;
	BOOL stop = NO;
	
	while (!stop && [date compare:self.end] == NSOrderedAscending) {
		block(date, &stop);
		date = [calendar dateByAddingComponents:comp toDate:self.start options:0];
		comp.day++;
	}
}

- (BOOL)isEqualToDateRange:(MGCDateRange*)range
{
	return range && [range.start isEqualToDate:self.start] && [range.end isEqualToDate:self.end];
}

- (BOOL)isEmpty
{
    return [self.start isEqualToDate:self.end];
}

#pragma mark - NSObject

- (id)copyWithZone:(NSZone*)zone
{
    return [MGCDateRange dateRangeWithStart:self.start end:self.end];
}

- (BOOL)isEqual:(id)object
{
	if (self == object)
		return YES;
	
	if (![object isKindOfClass:[MGCDateRange class]])
		return NO;
	
	return [self isEqualToDateRange:(MGCDateRange*)object];
}

- (NSUInteger)hash
{
	return NSUINTROTATE([self.start hash], NSUINT_BIT / 2) ^ [self.end hash];
}

- (NSString*)description
{
	return [NSString stringWithFormat:@"[%@ - %@[", [self.dateFormatter stringFromDate:self.start], [self.dateFormatter stringFromDate:self.end]];
}

@end
