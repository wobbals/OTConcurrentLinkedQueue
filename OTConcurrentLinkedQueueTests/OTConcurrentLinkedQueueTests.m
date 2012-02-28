//
//  OTConcurrentLinkedQueueTests.m
//  OTConcurrentLinkedQueueTests
//
//  Created by Charley Robinson on 2/27/12.
//  Copyright (c) 2012 Tokbox, Inc. All rights reserved.
//

#import "OTConcurrentLinkedQueueTests.h"
#import "OTConcurrentLinkedQueue.h"
#import <libkern/OSAtomic.h>

@implementation OTConcurrentLinkedQueueTests

- (void)setUp
{
    [super setUp];
    
    // Set-up code here.
}

- (void)tearDown
{
    // Tear-down code here.
    
    [super tearDown];
}

- (void)testExample
{
    int thingsIn = 10000000;
    OTConcurrentLinkedQueue* queue = [[OTConcurrentLinkedQueue alloc] init];
    for (int i = 0; i < thingsIn; i++) {
        dispatch_async(dispatch_get_global_queue(0, 0), ^{
            [queue offer:[NSString stringWithFormat:@"%d", i]];
        });
    }
    
    NSLog(@"so far, so good.");
    
    double delayInSeconds = 2.0;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        __block int thingsOut = 0;
        __block int emptyPollCount = 0;
        while (![queue isEmpty]) {
            dispatch_async(dispatch_get_global_queue(0, 0), ^{
                if ([queue poll] != nil) {
                    OSAtomicIncrement32Barrier((int*)&thingsOut);
                } else {
                    OSAtomicIncrement32Barrier((int*)&emptyPollCount);                
                }
            });
        }
        usleep(1000000); //sleep to drain the global queue
        NSLog(@"done! out=%d, in=%d, overshot=%d", thingsOut, thingsIn, emptyPollCount);
        STAssertEquals(thingsOut, thingsIn, @"Number of things");
    });
}

@end
