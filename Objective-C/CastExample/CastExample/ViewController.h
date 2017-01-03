@import AVFoundation;
@import UIKit;

@interface ViewController : UIViewController

/// Content video player.
@property(nonatomic, strong) AVPlayer *contentPlayer;
/// Play button.
@property(nonatomic, weak) IBOutlet UIButton *playButton;
/// UIView in which we will render our AVPlayer for content.
@property(nonatomic, weak) IBOutlet UIView *videoView;
/// The content URL to play.
@property(nonatomic, weak) NSString *const kContentUrl;
/// Ad tag.
@property(nonatomic, weak) NSString *const kAdTagUrl;
/// If the previous ad tag is VMAP ad.
@property(nonatomic, assign, readonly) BOOL isVMAPAd;
/// If an ad has started playing.
@property(nonatomic, assign, readonly) BOOL adStartedPlaying;

- (void)playVideo;

- (void)pauseVideo;

- (void)seekContent:(CMTime)time;

@end
