MGC Graphical Calendars Library is a set of views and controllers for displaying and scheduling events on iOS.

![Day Planner View](CalendarDocs/DayPlannerView.jpg?raw=true "Day planner view")

![Month Planner View](CalendarDocs/MonthPlannerView.jpg?raw=true "Month planner view")

![Year Calendar View](CalendarDocs/YearView.jpg?raw=true "Year calendar view")

# Features #

- Create and schedule events with iCal-like views and controllers
- 3 kinds of views are available (a day planner view, a month planner view and a year view)
- Scroll infinitely through days / months, or restrict scrolling to a given date range
- Page through weeks in the day planner view
- Use a standard view for event cells or create your own custom views
- Easily customize appearance and layout (date format, size of headers, number of visible days...)
- Create events by tap-and-hold on the view
- Drag-and-drop events to another date or time
- Scroll through days / months while dragging
- Specialized controllers for EventKit data source but can easily work with any custom event provider 
- Background event loading for the EventKit controllers
- Ability to show an activity indicator for days while events are loading
- Restrict ability to create or move events to certain dates through datasource protocol methods (currently only in day planner view)
- Zoom in/out the day planner view to increase or decrease the height of hour slots

# Compatibility #

iPad with iOS 7 or higher.

The views work on the iPhone but the EventKit controllers still need a bit of work.

# Installation #

Copy the CalendarLib folder content into your project.

# Getting started #

1.	Create a new project
	
2.	Import the **CalendarLib** folder into the project

3.  If you want to use EventKit as a data source, create an instance of `MGCDayPlannerEKViewController` or `MGCMonthPlannerEKViewController`, or subclass them for your own needs.
	
	Don't forget to add the following frameworks to the project:
	
	- **EventKit.framework**
	- **EventKitUI.framework**
	
4.  If you want to use another event provider, subclass one of `MGCDayPlannerViewController` or `MGCMonthPlannerViewController` and implement the data source protocol methods.

5.  If you want to use a custom event cell, subclass `MGCEventView` or `MGCStandardEventView` and register the class with the day / month planner view.
	
See the demo project to get an idea of how to use the library.

Have a look at the CalendarDocs folder for (incomplete) documentation on the day planner view.

# Todo #

- make the EventKit controllers work on the iPhone
- make a demo app for the iPhone

# License #

MGC Graphical Calendars Library is available under the MIT license. See the LICENSE file.

An email telling me in what kind of application you're using it would be welcome!
