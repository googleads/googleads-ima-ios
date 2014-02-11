//
//  IMASampleAppDelegate.m
//  SampleAppV3
//
//  Copyright (c) 2013 Google Inc. All rights reserved.

#import "IMASampleAppDelegate.h"
#import "IMASampleViewController.h"

@implementation IMASampleAppDelegate

- (BOOL)application:(UIApplication *)application
    didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
  self.viewController = [[IMASampleViewController alloc]
                            initWithNibName:@"ViewLayout"
                                     bundle:[NSBundle mainBundle]];
  self.window = [[UIWindow alloc]
                    initWithFrame:[[UIScreen mainScreen] bounds]];

  self.window.rootViewController = self.viewController;
  [self.window makeKeyAndVisible];
  return YES;
}

@end
