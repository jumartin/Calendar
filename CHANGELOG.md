# CHANGELOG

## v. 2.0

- Deployment target is now iOS 8.0
- The library is now fully compatible with both iPad and iPhone
- Many new APIs for both the day planner and the month planner
- Few optimizations and bug fixes

### Day Planner

- `MGCDayPlannerView` :
	- new property `daySeparatorsColor`
	- new property `timeSeparatorsColor`
	- new property `currentTimeColor`
	- new property `eventIndicatorDotColor`
	- new property `hourRange`
	
- `MGCDayPlannerViewDelegate` :
	- new method `dayPlannerView:attributedStringForTimeMark:time:`
	- new method `dayPlannerView:attributedStringForDayHeaderAtDate:`
	
	
### Month planner

- `MGCMonthPlannerView` :
	- new property `dayCellHeaderHeight`
	- new property `dateFormat`
	- new property `gridStyle`
	- new property `monthHeaderStyle`
	- new property `monthInsets`
	- new property `style`
	- new property `eventsDotColor`
	- new method `reloadEventsAtDate:`
	- new property `allowsSelection`
	- new property `selectedEventDate`
	- new property `selectedEventIndex`
	- new property `selectedEventView`
	- new property `calendarBackgroundColor`
	- new property `weekDayBackgroundColor`
	- new property `weekendDayBackgroundColor`
	- new property `weekdaysLabelTextColor`
	- new property `monthLabelTextColor`
	- new property `monthLabelFont`
	- new property `weekdaysLabelFont`
	- new property `weekDaysStringArray`
	- new property `pagingMode`
	- new method `scrollToDate:alignment:animated:`
	- new property `canCreateEvents`
	- new property `canMoveEvents`
	
- `MGCMonthPlannerViewDelegate`:
	- new method `monthPlannerView:attributedStringForDayHeaderAtDate:`
	
### Event Kit

- EventKit specialized controllers (`MGCDayPlannerEKViewController` and `MGCMonthPlannerEKViewController`) : 
	- added iPhone compatibility with the use of `UIPopoverPresentationController` for adaptive presentation of EventKit controllers
- new protocol `MGCDayPlannerEKViewControllerDelegate`
	
### Contributors 

[@xEsk](https://github.com/xEsk) : [#5](https://github.com/jumartin/Calendar/pull/5)
[@varun-naharia](https://github.com/varun-naharia) : [#14](https://github.com/jumartin/Calendar/pull/14)
[@dk53](https://github.com/dk53) : [#17](https://github.com/jumartin/Calendar/pull/17) [#18](https://github.com/jumartin/Calendar/pull/18) 
[@arnaudWasappli](https://github.com/arnaudWasappli) : [#21](https://github.com/jumartin/Calendar/pull/21)

Thanks!

