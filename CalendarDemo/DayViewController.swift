//
//  TwoDaysViewController.swift
//  CalendarDemo
//
//  Created by Hai Nguyen Thanh on 8/30/20.
//  Copyright © 2020 Julien Martin. All rights reserved.
//

import UIKit
import UniversalCalendar

class DayViewController: MGCDayPlannerViewController , CalendarViewControllerNavigation {
    override func viewDidLoad() {
        super.viewDidLoad()
        self.dayPlannerView.register(MGCStandardEventView.self, forEventViewWithReuseIdentifier: "EventCellReuseIdentifier")
        self.dayPlannerView.numberOfVisibleDays = 2
        self.dayPlannerView.showsAllDayEvents = true
    }

    private(set) var centerDate: Date! = Date()

    func move(to date: Date!, animated: Bool) {
    }

    func moveToNextPage(animated: Bool) {
    }

    func moveToPreviousPage(animated: Bool) {
    }
}

extension DayViewController {
    override func dayPlannerView(_ view: MGCDayPlannerView!, numberOfEventsOf type: MGCEventType, at date: Date!) -> Int {
        return 1
    }
    
    override func dayPlannerView(_ view: MGCDayPlannerView!, viewForEventOf type: MGCEventType, at index: UInt, date: Date!) -> MGCEventView! {
        
        let cell = view.dequeueReusableView(withIdentifier: "EventCellReuseIdentifier", forEventOf: type, at: index, date: date) as! MGCStandardEventView
        cell.title = "event \(date)"
        switch type {
        case .allDayEventType:
            cell.style = [.dot]
        case .timedEventType:
            cell.style = [.border]
        }
        
        return cell
    }
    
    override func dayPlannerView(_ view: MGCDayPlannerView!, dateRangeForEventOf type: MGCEventType, at index: UInt, date: Date!) -> MGCDateRange! {
        switch type {
        case .allDayEventType:
            let end = date?.addingTimeInterval(86300)
            //let end = [self.calendar mgc_nextStartOfDayForDate:end];
            return MGCDateRange.init(start: date, end: end)
        case .timedEventType:
            return MGCDateRange.init(start: date.addingTimeInterval(3600), end: date.addingTimeInterval(13600))
        }
         
    }
    
    
}

extension DayViewController {
//    open  override func dayPlannerView(_ view: MGCDayPlannerView!, attributedStringFor mark: MGCDayPlannerTimeMark, time ti: TimeInterval) -> NSAttributedString! {
//        fatalError("dayPlannerView(_:attributedStringFor:time:) has not been implemented")
//    }
//
//    open  override func dayPlannerView(_ view: MGCDayPlannerView!, attributedStringForDayHeaderAt date: Date!) -> NSAttributedString! {
//        fatalError("dayPlannerView(_:attributedStringForDayHeaderAt:) has not been implemented")
//    }
//
//    open  override func dayPlannerView(_ view: MGCDayPlannerView!, numberOfDimmedTimeRangesAt date: Date!) -> Int {
//        fatalError("dayPlannerView(_:numberOfDimmedTimeRangesAt:) has not been implemented")
//    }
//
//    open  override func dayPlannerView(_ view: MGCDayPlannerView!, dimmedTimeRangeAt index: UInt, date: Date!) -> MGCDateRange! {
//        fatalError("dayPlannerView(_:dimmedTimeRangeAt:date:) has not been implemented")
//    }

    open  override func dayPlannerView(_ view: MGCDayPlannerView!, didScroll scrollType: MGCDayPlannerScrollType) {
    }

    open  override func dayPlannerView(_ view: MGCDayPlannerView!, didEndScrolling scrollType: MGCDayPlannerScrollType) {
    }

    open  override func dayPlannerView(_ view: MGCDayPlannerView!, willDisplay date: Date!) {
    }

    open  override func dayPlannerView(_ view: MGCDayPlannerView!, didEndDisplaying date: Date!) {
    }

    open  override func dayPlannerViewDidZoom(_ view: MGCDayPlannerView!) {
    }

//    open  override func dayPlannerView(_ view: MGCDayPlannerView!, shouldSelectEventOf type: MGCEventType, at index: UInt, date: Date!) -> Bool {
//        fatalError("dayPlannerView(_:shouldSelectEventOf:at:date:) has not been implemented")
//    }

    open  override func dayPlannerView(_ view: MGCDayPlannerView!, didSelectEventOf type: MGCEventType, at index: UInt, date: Date!) {
    }

    open  override func dayPlannerView(_ view: MGCDayPlannerView!, didDeselectEventOf type: MGCEventType, at index: UInt, date: Date!) {
    }
}
