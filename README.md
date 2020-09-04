# Universal Calendar inspired from [Calendar](https://github.com/jumartin/Calendar) (Julien Martin)

[![Version](https://img.shields.io/cocoapods/v/CalendarLib.svg?style=flat)](http://cocoapods.org/pods/CalendarLib)
[![Carthage compatible](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat)](https://github.com/Carthage/Carthage)
[![License](https://img.shields.io/cocoapods/l/CalendarLib.svg?style=flat)](http://cocoapods.org/pods/CalendarLib)
[![Platform](https://img.shields.io/cocoapods/p/CalendarLib.svg?style=flat)](http://cocoapods.org/pods/CalendarLib)

Universal Calendar is a set of views and controllers for displaying and scheduling events on iOS and OSX.

#### OSX
![OS X 2Days](./CalendarDocs/osx_2days.png "2Days planner view")
![OS X Week](./CalendarDocs/osx_week.png "Weak planner view")
![OS X Month](./CalendarDocs/osx_month.png "Month planner view")
![OS X Year](./CalendarDocs/osx_year.png "Year planner view")

#### iOS
![Day Planner View](./CalendarDocs/DayPlannerView.png "Day planner view")
![Month Planner View](./CalendarDocs/MonthPlannerView.png "Month planner view")
![Month Planner View](./CalendarDocs/MonthPlannerView2.png)
![Day Planner View](./CalendarDocs/DayPlannerView2.png)
![Year Calendar View](./CalendarDocs/YearView.png "Year calendar view")

## Features

- Create and schedule events with iCal-like views and controllers.
- 3 kinds of views are available (a day planner view, a month planner view and a year view).
- Scroll infinitely through days / months, or restrict scrolling to a given date range.
- Restrict range of displayed hours in the day planner view.
- Page through weeks in the day planner view or months in the month planner view .
- Use a standard view for event cells or create your own custom views.
- Easily customize appearance and layout (date format, colors, fonts, size of headers, number of visible days...).
- Create events by tap-and-hold on the view.
- Drag-and-drop events to another date or time.
- Scroll through days / months while dragging.
- Ability to show an activity indicator for days while events are loading.
- Restrict ability to create or move events to certain dates through datasource protocol methods.
- Zoom in/out the day planner view to increase or decrease the height of hour slots.
- Dim certain time ranges in the day planner view.

## Compatibility

iPad / iPhone with iOS 11 or higher.
OS X 10.15 (Catalyst Support)

## Installation

### Carthage
Add this to Cartfile

```ruby
github "haithngn/Calendar" "master"
```
```ruby
$ carthage update
```

## Getting started

1.  Implement subclass one of `MGCDayPlannerViewController` or `MGCMonthPlannerViewController` and implement the data source protocol methods.

2.  If you want to use a custom event cell, subclass `MGCEventView` or `MGCStandardEventView` and register the class with the day / month planner view.
	
## License

Universal Calendar is available under the MIT license. See the LICENSE file.

## Contribution
+ Author: [TriTranDev](https://github.com/TriTranDev)
+ Author: [Vỹ Nguyễn](https://github.com/VyNguyen0102)

## Change-log

A summary of each Universal Calendar release can be found in the [CHANGELOG](CHANGELOG.md). 
