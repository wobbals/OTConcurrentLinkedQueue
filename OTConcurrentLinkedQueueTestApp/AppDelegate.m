//
//  AppDelegate.m
//  OTConcurrentLinkedQueueTestApp
//
//  Created by Charley Robinson on 2/28/12.
//  Copyright (c) 2012 Tokbox, Inc. All rights reserved.
//

#import "AppDelegate.h"
#import "OTConcurrentLinkedQueue.h"
#import <libkern/OSAtomic.h>

@implementation AppDelegate

@synthesize window = _window;

- (void)testExample
{
    int numberOfThings = 100000;
    OTConcurrentLinkedQueue* queue = [[OTConcurrentLinkedQueue alloc] init];
    for (int i = 0; i < numberOfThings; i++) {
        dispatch_async(dispatch_get_global_queue(0, 0), ^{
            [queue offer:[NSString stringWithFormat:@"%d", i]];
        });
    }
    
    NSLog(@"so far, so good.");
    self.window.backgroundColor = [UIColor yellowColor];
    
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
        usleep(1000000); //sleep to drain the global dispatch queue
        NSLog(@"done! out=%d, in=%d, overshot=%d", thingsOut, numberOfThings, emptyPollCount);
        self.window.backgroundColor = [UIColor greenColor];
    });
}


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    // Override point for customization after application launch.
    self.window.backgroundColor = [UIColor blueColor];
    [self.window makeKeyAndVisible];
    
    double delayInSeconds = 2.0;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        NSLog(@"Starting test");
        [self testExample];
    });
    
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    /*
     Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
     Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
     */
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    /*
     Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
     If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
     */
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    /*
     Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
     */
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    /*
     Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
     */
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    /*
     Called when the application is about to terminate.
     Save data if appropriate.
     See also applicationDidEnterBackground:.
     */
}

@end
