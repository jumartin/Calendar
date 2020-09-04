//
//  MGCEventView.h
//  Graphical Calendars Library for iOS
//
//  Distributed under the MIT License
//  Get the latest version from here:
//
//	https://github.com/jumartin/Calendar
//
//  Copyright (c) 2014-2015 Julien Martin
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all
//  copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//  SOFTWARE.
//

#import <UIKit/UIKit.h>
#import "MGCReusableObjectQueue.h"
#import "MGCDayPlannerView.h"


/*! 
 *  MGCEventView is used by MGCDayPlannerView and MGCMonthPlannerView to present the content of single events.
 *	You can subclass this class or use the already existing subclass MGCStandardEventView, which supports the
 *	display of basic event properties such as title and location.
 *	You must register your custom class(es) with the day/month planner view object and when needed
 *  call dequeueReusableViewWithIdentifier:forEvent... methods to retrieve an instance of the appropriate class, 
 *	depending on the event being displayed.
 *
 *	Because event view objects may be copied by the day/month planner view, make sure your subclass conforms 
 *	to the NSCopying protocol and copies custom properties to new instances.
 */
@interface MGCEventView : UIView<MGCReusableObject, NSCopying>

/*! @brief		A string that identifies the purpose of the view.
 *	@discussion This is set by the day/month planner view and should not be set directly.
 */
@property (nonatomic, copy) NSString *reuseIdentifier;

/*! @brief		The selection state of the view.
 *	@discussion This should not be set directly. 
 *				To (de)select an event, use the selection methods of the day/month planner view.
 */
@property (nonatomic) BOOL selected;

/*! @brief		Height of the visible portion of the view.
 *	@discussion	If the view is partially hidden by an other event view, you can use this property
 *				to determine the available height to show the event content.
 *				You should not set this property directly.
 */
@property (nonatomic) CGFloat visibleHeight;

/*! @brief		This is called by the day planner view when an event view is dragged around and the
 *				target event type is changing.
 *	@discussion	By implementing this method in your subclass, you can change the way the view
 *				displays the content of the event.
 */
- (void)didTransitionToEventType:(MGCEventType)toType;

@end
