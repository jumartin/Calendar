//
//  MGCReusableObjectQueue.h
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

#import <Foundation/Foundation.h>


/*!
 * Any object than can be placed in an MGCReusableObjectQueue
 * should implement this protocol.
 */
@protocol MGCReusableObject <NSObject>

/*! Reuse identifier - set by the queue. */
@property (nonatomic, copy) NSString *reuseIdentifier;

@optional

/*! Performs any clean up necessary to prepare the object for use again.
 *	If implemented, it is called when an object is dequeued. 
 */
- (void)prepareForReuse;

@end


/*!
 * Implements a queue allowing expensive objects like UIViews to be reused,
 * in order to reduce memory allocations.
 */
@interface MGCReusableObjectQueue : NSObject

/*! Returns the total number of objects currently stored in the queue. */
@property (readonly) NSUInteger count;

/*! Returns the total number of objects that were allocated by this queue - for debugging purposes */
@property (readonly) NSUInteger totalCreated;

/*! Returns a default shared queue. */
+ (instancetype)defaultQueue;

/*! Enqueues an object, making it available for reuse. */
- (void)enqueueReusableObject:(id<MGCReusableObject>)object;

/*! Returns an object whose class was previously registered with given identifier.
 *	If an object is available in the queue, it is returned. Otherwise, a new object is allocated. 
 */
- (id<MGCReusableObject>)dequeueReusableObjectWithReuseIdentifier:(NSString*)identifier;

/*! Registers an object class in the queue, for a given identifier.
 *	If objectClass is nil, all unused objects in the queue with given identifier are removed.
 */
- (void)registerClass:(Class)objectClass forObjectWithReuseIdentifier:(NSString*)identifier;

/*! Removes all unused objects from the queue. */
- (void)removeAllObjects;

@end
