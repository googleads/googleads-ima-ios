#import "AppDelegate.h"

@import GoogleCast;

#import "MainViewController.h"

static BOOL const IMAEnableCastSDKLogging = YES;

static NSString *const IMAApplicationID = @"8EE292C4";

@interface AppDelegate () <GCKLoggerDelegate>

@end

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application
    didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
  GCKCastOptions *options = [[GCKCastOptions alloc] initWithReceiverApplicationID:IMAApplicationID];
  [GCKCastContext setSharedInstanceWithOptions:options];

  [[GCKLogger sharedInstance] setDelegate:self];

  return YES;
}

#pragma mark - GCKLoggerDelegate

- (void)logMessage:(NSString *)message fromFunction:(NSString *)function {
  if (IMAEnableCastSDKLogging) {
    // Send SDK's log messages directly to the console.
    NSLog(@"%@  %@", function, message);
  }
}

@end
