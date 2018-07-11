#import "AppDelegate.h"

@import GoogleCast;

@interface AppDelegate () <GCKLoggerDelegate>

@end

@implementation AppDelegate

static NSString *const kReceiverAppID = @"93F3197F";

- (BOOL)application:(UIApplication *)application
    didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
  GCKCastOptions *options = [[GCKCastOptions alloc] initWithReceiverApplicationID:kReceiverAppID];
  [GCKCastContext setSharedInstanceWithOptions:options];

  [GCKLogger sharedInstance].delegate = self;
  return YES;
}

#pragma mark - GCKLoggerDelegate

- (void)logMessage:(NSString *)message fromFunction:(NSString *)function {
  NSLog(@"%@  %@", function, message);
}

@end
