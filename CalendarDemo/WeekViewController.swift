//
//  WeekViewController.swift
//  CalendarDemo
//
//  Created by Hai Nguyen Thanh on 8/30/20.
//  Copyright © 2020 Julien Martin. All rights reserved.
//

import UIKit
import UniversalCalendar

class WeekViewController: MGCDayPlannerViewController, CalendarViewControllerNavigation {
    override func viewDidLoad() {
        super.viewDidLoad()
        self.dayPlannerView.register(MGCStandardEventView.self, forEventViewWithReuseIdentifier: "EventCellReuseIdentifier")
        self.dayPlannerView.numberOfVisibleDays = 7
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

extension WeekViewController {
    override func dayPlannerView(_ view: MGCDayPlannerView!, numberOfEventsOf type: MGCEventType, at date: Date!) -> Int {
        switch type {
        case .allDayEventType:
            return Int.random(in: 0...19)
        case .timedEventType:
            return 1
        }
    }
    
    override func dayPlannerView(_ view: MGCDayPlannerView!, viewForEventOf type: MGCEventType, at index: UInt, date: Date!) -> MGCEventView! {
        
        let cell = view.dequeueReusableView(withIdentifier: "EventCellReuseIdentifier", forEventOf: type, at: index, date: date) as! MGCStandardEventView
        cell.title = "event \(index)"
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
            return MGCDateRange.init(start: date, end: date.addingTimeInterval(86400))
        case .timedEventType:
            return MGCDateRange.init(start: date.addingTimeInterval(3600), end: date.addingTimeInterval(13600))
        }
         
    }
    
    
}

extension WeekViewController {
    override func dayPlannerView(_ view: MGCDayPlannerView!, viewForNewEventOf type: MGCEventType, at date: Date!) -> MGCEventView! {
        let eventView = EventCreateViewCell.init()
        eventView.configure(date: date, type: type)
        eventView.onCreateEventBySummary = { summary, date, type in
            view.endInteraction()
        }
        return eventView
    }
    
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

extension WeekViewController {

//    open  override func dayPlannerView(_ view: MGCDayPlannerView!, viewForEventOf type: MGCEventType, at index: UInt, date: Date!) -> MGCEventView! {
//        fatalError("dayPlannerView(_:viewForEventOf:at:date:) has not been implemented")
//    }
//
//    open  override func dayPlannerView(_ view: MGCDayPlannerView!, dateRangeForEventOf type: MGCEventType, at index: UInt, date: Date!) -> MGCDateRange! {
//        fatalError("dayPlannerView(_:dateRangeForEventOf:at:date:) has not been implemented")
//    }
}

