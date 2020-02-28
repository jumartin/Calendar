# CalendarLib inspired from [Calendar](https://github.com/jumartin/Calendar) (Julien Martin)

[![Version](https://img.shields.io/cocoapods/v/CalendarLib.svg?style=flat)](http://cocoapods.org/pods/CalendarLib)
[![Carthage compatible](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat)](https://github.com/Carthage/Carthage)
[![License](https://img.shields.io/cocoapods/l/CalendarLib.svg?style=flat)](http://cocoapods.org/pods/CalendarLib)
[![Platform](https://img.shields.io/cocoapods/p/CalendarLib.svg?style=flat)](http://cocoapods.org/pods/CalendarLib)

CalendarLib is a set of views and controllers for displaying and scheduling events on iOS.

**Warning:**

**As some people may have noticed, this project has not got any update recently, and a lot of issues / pull requests remain unanswered.
I’m very sorry for that, but I don’t have any time at the moment to take care of this repo, being very busy with other projects.
I may come back to it in the future, but meanwhile, please don’t expect any update soon.**

**Thanks anyway to all the contributors!**



![Day Planner View](https://raw.githubusercontent.com/jumartin/Calendar/master/CalendarDocs/DayPlannerView.png "Day planner view")
![Day Planner View](https://raw.githubusercontent.com/jumartin/Calendar/master/CalendarDocs/DayPlannerView2.png)
![Month Planner View](https://raw.githubusercontent.com/jumartin/Calendar/master/CalendarDocs/MonthPlannerView.png "Month planner view")
![Month Planner View](https://raw.githubusercontent.com/jumartin/Calendar/master/CalendarDocs/MonthPlannerView2.png)
![Year Calendar View](https://raw.githubusercontent.com/jumartin/Calendar/master/CalendarDocs/YearView.png "Year calendar view")

## Features

- Create and schedule events with iCal-like views and controllers
- 3 kinds of views are available (a day planner view, a month planner view and a year view)
- Scroll infinitely through days / months, or restrict scrolling to a given date range
- Restrict range of displayed hours in the day planner view
- Page through weeks in the day planner view or months in the month planner view 
- Use a standard view for event cells or create your own custom views
- Easily customize appearance and layout (date format, colors, fonts, size of headers, number of visible days...)
- Create events by tap-and-hold on the view
- Drag-and-drop events to another date or time
- Scroll through days / months while dragging
- Specialized controllers for EventKit data source but can easily work with any custom event provider 
- Background event loading for the EventKit controllers
- Ability to show an activity indicator for days while events are loading
- Restrict ability to create or move events to certain dates through datasource protocol methods
- Zoom in/out the day planner view to increase or decrease the height of hour slots
- Dim certain time ranges in the day planner view

## Compatibility

iPad / iPhone with iOS 8 or higher.

## Installation

### CocoaPods
    
The best way is to use [CocoaPods](https://cocoapods.org/pods/CalendarLib). Add the following line to your Podfile : 

```ruby
pod "CalendarLib"
```

### Carthage
Add this to Cartfile

```ruby
github "haithngn/Calendar" "2.0.1"
```
```ruby
$ carthage update
```

### The old way

If you don't want to use CocoaPods, you need to copy the content of the CalendarLib folder into your project, as well as the source of the two dependencies : [OSCache](https://github.com/nicklockwood/OSCache) and [OrderedDictionary](https://github.com/nicklockwood/OrderedDictionary).

## Getting started

1.  If you want to use EventKit as a data source, create an instance of `MGCDayPlannerEKViewController` or `MGCMonthPlannerEKViewController`, or subclass them for your own needs.
	
	Don't forget to add the following frameworks to the project:
	
	- **EventKit.framework**
	- **EventKitUI.framework**
	
2.  If you want to use another event provider, subclass one of `MGCDayPlannerViewController` or `MGCMonthPlannerViewController` and implement the data source protocol methods.

3.  If you want to use a custom event cell, subclass `MGCEventView` or `MGCStandardEventView` and register the class with the day / month planner view.
	
See the demo project to get an idea of how to use the library and check the [documentation](http://cocoadocs.org/docsets/CalendarLib/)

## License

CalendarLib is available under the MIT license. See the LICENSE file.

## Contribution
+ Author: [TriTranDev](https://github.com/TriTranDev)
+ Author: [Vỹ Nguyễn](https://github.com/VyNguyen0102)

## Change-log

A summary of each CalendarLib release can be found in the [CHANGELOG](CHANGELOG.md). 
