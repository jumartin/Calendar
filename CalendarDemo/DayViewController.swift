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

        self.dayPlannerView.numberOfVisibleDays = 2
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

extension DayViewController {
    open  override func dayPlannerView(_ view: MGCDayPlannerView!, numberOfEventsOf type: MGCEventType, at date: Date!) -> Int {
        return 0
    }

//    open  override func dayPlannerView(_ view: MGCDayPlannerView!, viewForEventOf type: MGCEventType, at index: UInt, date: Date!) -> MGCEventView! {
//        fatalError("dayPlannerView(_:viewForEventOf:at:date:) has not been implemented")
//    }
//
//    open  override func dayPlannerView(_ view: MGCDayPlannerView!, dateRangeForEventOf type: MGCEventType, at index: UInt, date: Date!) -> MGCDateRange! {
//        fatalError("dayPlannerView(_:dateRangeForEventOf:at:date:) has not been implemented")
//    }
}
