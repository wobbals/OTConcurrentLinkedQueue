//
//  OTConcurrentLinkedQueue.m
//  OTConcurrentLinkedQueue
//
//  Created by Charley Robinson on 2/27/12.
//  Copyright (c) 2012 Tokbox, Inc. All rights reserved.
//

#import "OTConcurrentLinkedQueue.h"
#import <libkern/OSAtomic.h>

@interface Node : NSObject {
@public
    id value;
    Node* next;
}
@end

@implementation Node
@end

@implementation OTConcurrentLinkedQueue {
    Node* _head;
    Node* _tail;
}

+ (Node*)new_node {
    Node* myNode = [[Node alloc] init];
    return myNode;
}

- (id)init
{
    self = [super init];
    if (self) {
        Node* node = [OTConcurrentLinkedQueue new_node];
        node->next = nil;
        node->value = nil;
        _tail = node;
        _head = node;
    }
    
    return self;
}

- (void)dealloc {
    while (![self isEmpty]) {
        [[self poll] release];
    }
    [_head release];
    _head = nil;
    _tail = nil;
}

- (BOOL)isEmpty {
    return (_head == _tail) && (_head->next == nil);
}

- (BOOL)offer:(id)object {
    Node* node = [OTConcurrentLinkedQueue new_node];
    node->value = [object retain];
    node->next = nil;
    Node* tail = nil;
    while (true) {
        tail = self->_tail;
        Node* next = tail->next;
        if (tail == _tail) {
            if (next == nil) {
                if (OSAtomicCompareAndSwapPtr(next, node, (void*)&(tail->next))) {
                    break;
                }
            } else {
                OSAtomicCompareAndSwapPtr(tail, next, (void*)&(self->_tail));
            }
        }
    }
    OSAtomicCompareAndSwapPtr(tail, node, (void*)&(self->_tail));
    return YES;
}

- (id)peek {
    return _head->next->value;
}

- (id)poll {
    id object = nil;
    Node* head;
    while (true) {
        head = self->_head;
        Node* tail = self->_tail;
        Node* next = head->next;
        if (head == _head) {
            if (head == tail) {
                if (next == nil) {
                    return nil;
                }
                OSAtomicCompareAndSwapPtr(tail, next, (void*)&(self->_tail));
            } else if (next != nil) {
                if (OSAtomicCompareAndSwapPtr(head, next, (void*)&(self->_head))) {
                    object = next->value;
                    break;
                }
            }
        }
    }
    [head release];
    [object autorelease];
    return object;
}

@end
