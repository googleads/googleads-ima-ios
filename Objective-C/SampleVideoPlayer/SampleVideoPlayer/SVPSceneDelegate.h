@import UIKit;

NS_ASSUME_NONNULL_BEGIN

/**
 * Scene delegate for SampleVideoPlayer.
 *
 * Manages the application's UIWindow and root view controller lifecycle.
 */
@interface SVPSceneDelegate : UIResponder <UIWindowSceneDelegate>

@property(nonatomic, strong, nullable) UIWindow *window;

@end

NS_ASSUME_NONNULL_END