//
//  LGAppDelegate.m
//  RetailerBeacons
//
//  Created by Matt Richardson on 21/08/2014.
//  Copyright (c) 2014 Legendary Games. All rights reserved.
//

#import "LGAppDelegate.h"
#import "LGViewController.h"
#import "LGDetectedBeaconViewController.h"
#import "LGAllBeaconsTableViewController.h"
#import "LGLoginViewController.h"

@implementation LGAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    self.window.backgroundColor = [UIColor whiteColor];
    
    // Quick check if we know this user already
    if ([self isLoggedIn] == NO)
    {
        LGLoginViewController *loginVC = [[LGLoginViewController alloc] initWithNibName:@"Login" bundle:nil];
        self.window.rootViewController = loginVC;
    }
    else
    {
        LGAllBeaconsTableViewController *allBeacons = [[LGAllBeaconsTableViewController alloc] initWithStyle:UITableViewStylePlain];
        UINavigationController *navigation = [[UINavigationController alloc] initWithRootViewController:allBeacons];
        navigation.navigationBar.backgroundColor = [UIColor yellowColor];
        self.window.rootViewController = navigation;
    }
    
    [self.window makeKeyAndVisible];
    
    return YES;
}

- (BOOL)isLoggedIn
{
    NSString *guid = nil;
    NSUserDefaults *standardUserDefaults = [NSUserDefaults standardUserDefaults];
    
    if (standardUserDefaults)
    {
        guid = [standardUserDefaults objectForKey:@"guid"];
        
        if (guid)
        {
            return YES;
        }
    }
    
    return NO;
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
