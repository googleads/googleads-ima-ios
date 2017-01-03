@import AVFoundation;
@import Foundation;
@import UIKit;

#import "CastMessageChannel.h"
#import "ViewController.h"

@class CastViewController;

@interface CastViewController : UIViewController

- (instancetype)initWithViewController:(ViewController *)viewController;

- (void)castChannel:(CastMessageChannel *)channel didReceiveMessage:(NSString *)message;

@end
