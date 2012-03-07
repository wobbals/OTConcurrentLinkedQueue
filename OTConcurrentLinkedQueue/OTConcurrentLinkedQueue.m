//
//  OTConcurrentLinkedQueue.m
//  OTConcurrentLinkedQueue
//
//  Created by Charley Robinson on 2/27/12.
//  Copyright (c) 2012 Tokbox, Inc. All rights reserved.
//

#import "OTConcurrentLinkedQueue.h"
#import <libkern/OSAtomic.h>

@class Node;

union nodeptr {
struct {
    Node* ptr;
    int32_t count;
} stuff;
volatile int64_t val;
};

typedef union nodeptr pointer_t;

@interface Node : NSObject {
@public
    id value;
    pointer_t next;
}
@end

@implementation Node
@end

bool cas(pointer_t* value, pointer_t old, Node* new);

bool cas(pointer_t* value, pointer_t old, Node* new) {
    pointer_t nodePtr;
    nodePtr.stuff.ptr = new;
    nodePtr.stuff.count = old.stuff.count+1;
    return OSAtomicCompareAndSwap64Barrier(old.val, nodePtr.val, (volatile int64_t*)value);
}


@implementation OTConcurrentLinkedQueue {
    pointer_t _head;
    pointer_t _tail;
    int32_t nodeCounter;
}

+ (Node*)new_node {
    Node* myNode = [[Node alloc] init];
    //myNode->next = malloc(sizeof(pointer_t));
    myNode->value = nil;
    return myNode;
}

- (id)init
{
    self = [super init];
    if (self) {
        nodeCounter = 0;
        pointer_t dummy;
        dummy.stuff.ptr = [OTConcurrentLinkedQueue new_node];
        dummy.stuff.count = nodeCounter++;
        _head = dummy;
        _tail = dummy;
    }
    
    return self;
}

- (void)dealloc {
    while (![self isEmpty]) {
        [[self poll] release];
    }
    [_head.stuff.ptr release];
    _head.val = 0;
    _tail.val = 0;
    [super dealloc];
}

- (BOOL)isEmpty {
    return [self peek] == nil;
}

- (BOOL)offer:(id)object {
    Node* node = [OTConcurrentLinkedQueue new_node];
    node->value = [object retain];
    pointer_t nextPtr;
    nextPtr.stuff.ptr = 0;
    OSAtomicIncrement32Barrier(&nodeCounter);
    nextPtr.stuff.count = nodeCounter;
    node->next = nextPtr;
    pointer_t tail;
    int iterations = 0;
    while (true) {
        iterations++;
        tail = self->_tail;
        pointer_t next = tail.stuff.ptr->next;
        if (tail.val == _tail.val) {
            if (next.stuff.ptr == 0) {
                if (cas(&tail.stuff.ptr->next, next, node)) {
                    break;
                }
            } else {
                cas(&_tail, tail, next.stuff.ptr);
            }
        }
    }
    cas(&_tail, tail, node);
    return YES;
}

- (id)peek {
    pointer_t head;
    int iterations = 0;
    while (true) {
        iterations++;
        head = _head;
        pointer_t tail = _tail;
        pointer_t next = head.stuff.ptr->next;
        if (head.val == _head.val) {
            if (head.stuff.ptr == tail.stuff.ptr) {
                if (next.stuff.ptr == 0) {
                    return nil;
                }
                cas(&_tail, tail, next.stuff.ptr);
            } else {
                return next.stuff.ptr->value;
            }
        }
    }
}

- (id)poll {
    id object = nil;
    pointer_t head;
    int iterations = 0;
    while (true) {
        iterations++;
        head = _head;
        pointer_t tail = _tail;
        pointer_t next = head.stuff.ptr->next;
        if (head.val == _head.val) {
            if (head.stuff.ptr == tail.stuff.ptr) {
                if (next.stuff.ptr == 0) {
                    return nil;
                }
                cas(&_tail, tail, next.stuff.ptr);
            } else {
                object = next.stuff.ptr->value;
                if (cas(&_head, head, next.stuff.ptr)) {
                    break;
                }
            }
        }
    }
    [head.stuff.ptr release];
    [object autorelease];
    return object;
}

@end
