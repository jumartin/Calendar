//
//  MGCCalendarHeaderCell.h
//  Calendar
//
//  Copyright © 2016 Julien Martin. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface MGCCalendarHeaderCell : UICollectionViewCell

@property (nonatomic, strong)  UILabel *dayNumberLabel;
@property (nonatomic, strong)  UILabel *dayNameLabel;
@property (nonatomic, strong) NSDate *date;

@end
