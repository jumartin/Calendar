//
//  NSCalendar+MGCAdditions.m
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

#import "NSCalendar+MGCAdditions.h"


@implementation NSCalendar (MGCAdditions)

+ (NSCalendar*)mgc_calendarFromPreferenceString:(NSString*)string
{
	if ([string isEqualToString:@"gregorian"])
		return [[NSCalendar alloc]initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
	else if ([string isEqualToString:@"buddhist"])
		return [[NSCalendar alloc]initWithCalendarIdentifier:NSCalendarIdentifierBuddhist];
	else if ([string isEqualToString:@"chinese"])
		return [[NSCalendar alloc]initWithCalendarIdentifier:NSCalendarIdentifierChinese];
	else if ([string isEqualToString:@"hebrew"])
		return [[NSCalendar alloc]initWithCalendarIdentifier:NSCalendarIdentifierHebrew];
	else if ([string isEqualToString:@"islamic"])
		return [[NSCalendar alloc]initWithCalendarIdentifier:NSCalendarIdentifierIslamic];
	else if ([string isEqualToString:@"islamicCivil"])
		return [[NSCalendar alloc]initWithCalendarIdentifier:NSCalendarIdentifierIslamicCivil];
	else if ([string isEqualToString:@"japanese"])
		return [[NSCalendar alloc]initWithCalendarIdentifier:NSCalendarIdentifierJapanese];
	else if ([string isEqualToString:@"republicOfChina"])
		return [[NSCalendar alloc]initWithCalendarIdentifier:NSCalendarIdentifierRepublicOfChina];
	else if ([string isEqualToString:@"persian"])
		return [[NSCalendar alloc]initWithCalendarIdentifier:NSCalendarIdentifierPersian];
	else if ([string isEqualToString:@"indian"])
		return [[NSCalendar alloc]initWithCalendarIdentifier:NSCalendarIdentifierIndian];
	else if ([string isEqualToString:@"iso8601"])
		return [[NSCalendar alloc]initWithCalendarIdentifier:NSCalendarIdentifierISO8601];
	return [NSCalendar currentCalendar];
}

- (NSDate*)mgc_startOfDayForDate:(NSDate*)date
{
	if (![self respondsToSelector:@selector(startOfDayForDate:)]) {
		// keep only day, month and year components
		NSDateComponents* comps = [self components:NSCalendarUnitYear|NSCalendarUnitMonth|NSCalendarUnitDay fromDate:date];
		return [self dateFromComponents:comps];
	}
	// startOfDayForDate: is only available in iOS 8 and later
	return [self startOfDayForDate:date];
}

- (NSDate*)mgc_nextStartOfDayForDate:(NSDate*)date
{
	NSDateComponents* comps = [NSDateComponents new];
	comps.day = 1;
	NSDate *next = [self dateByAddingComponents:comps toDate:date options:0];
	return [self mgc_startOfDayForDate:next];
}

- (NSDate*)mgc_startOfWeekForDate:(NSDate*)date
{
	NSDate *firstDay = nil;
	[self rangeOfUnit:NSCalendarUnitWeekOfMonth startDate:&firstDay interval:NULL forDate:date];
	return firstDay;
}

- (NSDate*)mgc_nextStartOfWeekForDate:(NSDate*)date
{
	NSDateComponents* comps = [NSDateComponents new];
	comps.day = 7;
	NSDate *next = [self dateByAddingComponents:comps toDate:date options:0];
	return [self mgc_startOfWeekForDate:next];
}

- (NSDate*)mgc_startOfMonthForDate:(NSDate*)date
{
	NSDate *firstDay = nil;
	[self rangeOfUnit:NSCalendarUnitMonth startDate:&firstDay interval:NULL forDate:date];
	return firstDay;
}

- (NSDate*)mgc_nextStartOfMonthForDate:(NSDate*)date
{
	NSDate *firstDay = [self mgc_startOfMonthForDate:date];
	NSDateComponents *comp = [NSDateComponents new];
	comp.month = 1;
	return [self dateByAddingComponents:comp toDate:firstDay options:0];
}

- (NSDate*)mgc_startOfYearForDate:(NSDate*)date
{
	NSDate *firstDay = nil;
	[self rangeOfUnit:NSCalendarUnitYear startDate:&firstDay interval:NULL forDate:date];
	return firstDay;
}

// one-based index of the week in month for given date
- (NSUInteger)mgc_indexOfWeekInMonthForDate:(NSDate*)date
{
    // [NSCalendar ordinalityOfUnit:NSCalendarUnitWeekOfMonth inUnit:NSCalendarUnitMonth forDate:] is one-based
    // but the first week is considered only if its number of days is at least equal to the minimumDaysInFirstWeek value.

    NSUInteger index = [self ordinalityOfUnit:NSCalendarUnitWeekOfMonth inUnit:NSCalendarUnitMonth forDate:date];
    
    NSDate *startOfMonth = [self mgc_startOfMonthForDate:date];
    NSRange firstWeekRange = [self rangeOfUnit:NSCalendarUnitDay inUnit:NSCalendarUnitWeekOfMonth forDate:startOfMonth];
    
    if (firstWeekRange.length < self.minimumDaysInFirstWeek) {
        index++;
    }
    
    return index;
}

- (BOOL)mgc_isDate:(NSDate*)date1 sameDayAsDate:(NSDate*)date2
{
	if (!date1 || !date2)
		return NO;
	
	return ([[self mgc_startOfDayForDate:date1] compare:[self mgc_startOfDayForDate:date2]] == NSOrderedSame);
}

- (BOOL)mgc_isDate:(NSDate*)date1 sameMonthAsDate:(NSDate*)date2
{
	if (!date1 || !date2)
		return NO;
	
	NSDate* start1, *start2;
	[self rangeOfUnit:NSCalendarUnitMonth startDate:&start1 interval:nil forDate:date1];
	[self rangeOfUnit:NSCalendarUnitMonth startDate:&start2 interval:nil forDate:date2];
	
	return ([start1 compare:start2] == NSOrderedSame);
}

@end
