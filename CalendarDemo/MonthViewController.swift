//
// Created by Hai Nguyen Thanh on 8/30/20.
// Copyright (c) 2020 Julien Martin. All rights reserved.
//

import UniversalCalendar

class MonthViewController: MGCMonthPlannerViewController, CalendarViewControllerNavigation {
    var centerDate: Date!
    
    func move(to date: Date!, animated: Bool) {
        monthPlannerView.scroll(to: date, alignment: .headerTop, animated: animated)
    }
    
    func moveToNextPage(animated: Bool) {
        
    }
    
    func moveToPreviousPage(animated: Bool) {
        
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.monthPlannerView.register(MGCStandardEventView.self, forEventCellReuseIdentifier: "EventCellReuseIdentifier")
        self.monthPlannerView.dataSource = self
        
    }
}

extension MonthViewController {
    override func monthPlannerView(_ view: MGCMonthPlannerView!, cellForNewEventAt date: Date!) -> MGCEventView! {
        let eventView = EventCreateViewCell.init()
        eventView.configure(date: date)
        eventView.onCreateEventBySummary = { summary, date in
            view.endInteraction()
        }
        return eventView
    }
}

extension MonthViewController {
    override func monthPlannerView(_ view: MGCMonthPlannerView!, numberOfEventsAt date: Date!) -> Int {
        
        //if NSCalendar.current.isDateInToday(date) {
        return 1
        //} else {
        //  return 0
        //}
    }
    
    override func monthPlannerView(_ view: MGCMonthPlannerView!, dateRangeForEventAt index: UInt, date: Date!) -> MGCDateRange! {
        
        
        return MGCDateRange.init(start: date, end: date.addingTimeInterval(3600))
    }
    
    override func monthPlannerView(_ view: MGCMonthPlannerView!, cellForEventAt index: UInt, date: Date!) -> MGCEventView! {
        let cell = view.dequeueReusableCell(withIdentifier: "EventCellReuseIdentifier", forEventAt: index, date: date) as! MGCStandardEventView
        
        if true {
            cell.style = [MGCStandardEventViewStyle.plain , MGCStandardEventViewStyle.dot ]
        } else {
            cell.style = [MGCStandardEventViewStyle.plain ]
        }
        cell.title = "eventItemModel.name \(date)"
        cell.color = UIColor.red
        return cell
    }
}
