//
//  AppDelegate.m
//  CalendarDemo - Graphical Calendars Library for iOS
//
//  Copyright (c) 2014-2015 Julien Martin. All rights reserved.
//

#import "AppDelegate.h"


//#define MEMORY_WARNING_SIMULATE 1

// http://www.vinnycoyne.com/post/55595095421/ios-simulate-on-device-memory-warnings
#if MEMORY_WARNING_SIMULATE
#import <MediaPlayer/MediaPlayer.h>
#endif

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    //self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    // Override point for customization after application launch.
    self.window.backgroundColor = [UIColor colorWithRed:(247/255.0) green:(247/255.0) blue:(247/255.0) alpha:1];
	self.window.tintColor = [UIColor redColor];
    //[self.window makeKeyAndVisible];
	
#if MEMORY_WARNING_SIMULATE
	
	// Debug code that lets us simulate memory warnings by pressing the device's volume buttons.
	// Don't ever ship this code, as it will be rejected by Apple.
	
	MPVolumeView *volume = [[MPVolumeView alloc] initWithFrame:CGRectZero];
	[self.window addSubview:volume];
	
	// Register to receive the button-press notifications
	
	__block id volumeObserver;
	
	volumeObserver = [[NSNotificationCenter defaultCenter] addObserverForName:@"AVSystemController_SystemVolumeDidChangeNotification" object:nil queue:nil usingBlock:^(NSNotification *note) {
		NSLog(@"Manually simulating a memory warning.");
		[[UIApplication sharedApplication] performSelector:@selector(_performMemoryWarning)];
	}];
	
#endif
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application
{
	// Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
	// Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
	// Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
	// If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
	// Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
	// Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application
{
	// Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

@end
