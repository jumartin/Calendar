Pod::Spec.new do |s|
	s.name         = "CalendarLib"
	s.version      = "2.0"
	s.summary      = "A set of views and controllers for displaying and scheduling events on iOS"
	s.homepage     = "https://github.com/jumartin/Calendar"
	s.license      = "MIT"
	s.author       = { "Julien Martin" => "julienmartin@hotmail.com" }
	s.platform     = :ios, "8.0"
	s.source       = { :git => "https://github.com/jumartin/Calendar.git", :tag => s.version.to_s }
	s.screenshots 	= [ "https://raw.githubusercontent.com/jumartin/Calendar/master/CalendarDocs/DayPlannerView.jpg", "https://raw.githubusercontent.com/jumartin/Calendar/master/CalendarDocs/MonthPlannerView.jpg", "https://raw.githubusercontent.com/jumartin/Calendar/master/CalendarDocs/YearView.jpg"]
    s.source_files  = "CalendarLib/**/*.{h,m}"
    s.public_header_files = "CalendarLib/{MGCDateRange.h,NSCalendar+MGCAdditions.h,NSAttributedString+MGCAdditions.h,MGCDayPlannerEKViewController.h,MGCMonthPlannerEKViewController.h,MGCEventView.h,MGCStandardEventView.h,MGCDayPlannerView.h,MGCDayPlannerViewController.h,MGCMonthPlannerView.h,MGCMonthPlannerViewController.h,MGCMonthMiniCalendarView.h,MGCYearCalendarView.h,MGCReusableObjectQueue.h}"
	s.resource_bundle = { 'CalendarLib' => ['CalendarLib/*.lproj'] }                    
	s.frameworks = "EventKit", "EventKitUI", "UIKit", "Foundation", "CoreGraphics"
	s.dependency "OSCache", "~> 1.2"
	s.dependency "OrderedDictionary", "~> 1.2" 
end
