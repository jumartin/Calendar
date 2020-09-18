//
//  EventCreateNew.swift
//  CalendarDemo
//
//  Created by LCL on 9/15/20.
//  Copyright © 2020 Julien Martin. All rights reserved.
//

import Foundation

public class EventCreateViewCell: MGCEventView {
    
    public var onCreateEventBySummary: ((String, Date) -> ())? = nil
    private let timeLabelHeight: CGFloat = 18
    private let labelMargin: CGFloat = 4
    public let timeLabel: UILabel = {
        let timeLabel = UILabel.init()
        timeLabel.textColor = UIColor.white
        timeLabel.font = UIFont.systemFont(ofSize: 12)
        return timeLabel
    }()
    
    public let summaryTextView: UITextView = {
        let summaryTextView = UITextView.init()
        summaryTextView.backgroundColor = UIColor.clear
        summaryTextView.textColor = UIColor.white
        summaryTextView.font = UIFont.systemFont(ofSize: 15)
        summaryTextView.tintColor = UIColor.white
        summaryTextView.returnKeyType = .done
        summaryTextView.enablesReturnKeyAutomatically = true
        return summaryTextView
    }()
    public var eventDate: Date = Date()
    
    public var container: UIView {
        if let superview = self.superview, !superview.isKind(of: UICollectionView.self) {
            return superview
        } else {
            return self
        }
    }
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        self.addSubview(timeLabel)
        summaryTextView.delegate = self
        self.addSubview(summaryTextView)
        self.backgroundColor = UIColor(red: 0.58, green: 0.81, blue: 0.00, alpha: 1.00)
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    private func setShadow() {
        container.layer.shadowColor = UIColor.black.withAlphaComponent(0.3).cgColor
        container.layer.shadowOpacity = 1
        container.layer.shadowOffset = .zero
        container.layer.shadowRadius = 10
        container.clipsToBounds = false
    }
    
    public func configure(date: Date) {
        eventDate = date
        let format = DateFormatter.init()
        format.dateFormat = "h:mm a  EE,dd/MM/yy"
        timeLabel.text = format.string(from: date)
    }
    public override func didMoveToSuperview() {
        super.didMoveToSuperview()
        self.setShadow()
        self.summaryTextView.becomeFirstResponder()
    }
    public override var frame: CGRect {
        didSet {
            print(frame)
            timeLabel.frame = CGRect.init(origin: CGPoint.init(x: labelMargin, y: labelMargin), size: CGSize.init(width: frame.width - 10, height: timeLabelHeight))
            summaryTextView.frame = CGRect.init(origin: CGPoint.init(x: 0, y: timeLabelHeight + labelMargin), size: CGSize.init(width: frame.width - 0, height: frame.height - timeLabelHeight - labelMargin))
        }
    }
}

extension EventCreateViewCell: UITextViewDelegate {
    public func textViewDidChange(_ textView: UITextView) {
        summaryTextView.frame.size = textView.contentSize
        // For month
        let newHeight = textView.contentSize.height + timeLabelHeight + labelMargin
        if newHeight != container.frame.size.height {
            container.frame.size = CGSize.init(width: container.frame.size.width, height: textView.contentSize.height + timeLabelHeight + labelMargin)
            summaryTextView.setContentOffset(CGPoint.zero, animated: false)
        }
    }
    public func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        if text == "\n" {
            textView.resignFirstResponder()
            onCreateEventBySummary?(textView.text, eventDate)
            return false
        }
        return true
    }
}
