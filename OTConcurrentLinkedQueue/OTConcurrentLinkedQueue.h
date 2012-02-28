//
//  OTConcurrentLinkedQueue.h
//  OTConcurrentLinkedQueue
//
//  Created by Charley Robinson on 2/27/12.
//  Copyright (c) 2012 Tokbox, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
 * So, I'm a java developer and love love love ConcurrentLinkedQueue. 
 * This class does about the same thing, using OSAtomic.h and Objective-C objects.
 * This is version 1 of the Michael & Scott paper; a non-blocking (wait-free) linked queue.
 * I didn't implement the size and iteration features you might
 * expect from a java collection, mostly because they don't run very safely in
 * multi-threaded environments anyway. Even the peek and isEmpty operations can lie to you.
 * 
 * @see http://www.cs.rochester.edu/u/michael/PODC96.html
 */

@interface OTConcurrentLinkedQueue : NSObject

/**
 * Employs a best-guess on the current emptiness of the queue. If you can get this
 * to run synchronized against the whole object, peek SHOULD return a nonnil value thereafter.
 * @return true if the queue is probably emtpy.
 */
- (BOOL)isEmpty;

/**
 * Puts an object on the queue.
 * @return true if the object is successfully placed on the queue. Jokes on you -- this will always return true.
 */
- (BOOL)offer:(id)object;

/**
 * Gives a best guess of the head of the queue. Again, if you can run this method synchronized
 * against the whole structure, it might actually be correct. Then again, the object could be gone
 * by the time you make the call to poll.
 * @return a reference to the object at the head of the queue, or nil if none.
 */
- (id)peek;

/**
 * Removes an object from the head of the queue, or nil if the queue is empty.
 * @return a reference to the object at the head of the queue, or nil if none.
 */
- (id)poll;

@end
