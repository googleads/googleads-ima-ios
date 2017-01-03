#import "ViewController.h"

@import AVFoundation;

@interface ViewController ()

/// Content video player.
@property(nonatomic, strong) AVPlayer *contentPlayer;

/// Play button.
@property(nonatomic, weak) IBOutlet UIButton *playButton;

/// UIView in which we will render our AVPlayer for content.
@property(nonatomic, weak) IBOutlet UIView *videoView;

@end

@implementation ViewController

// The content URL to play.
NSString *const kTestAppContentUrl_MP4 = @"http://rmcdn.2mdn.net/Demo/html5/output.mp4";

- (void)viewDidLoad {
  [super viewDidLoad];

  self.playButton.layer.zPosition = MAXFLOAT;

  [self setUpContentPlayer];
}

- (IBAction)onPlayButtonTouch:(id)sender {
  [self.contentPlayer play];
  self.playButton.hidden = YES;
}

#pragma mark Content Player Setup

- (void)setUpContentPlayer {
  // Load AVPlayer with path to our content.
  NSURL *contentURL = [NSURL URLWithString:kTestAppContentUrl_MP4];
  self.contentPlayer = [AVPlayer playerWithURL:contentURL];

  // Create a player layer for the player.
  AVPlayerLayer *playerLayer = [AVPlayerLayer playerLayerWithPlayer:self.contentPlayer];

  // Size, position, and display the AVPlayer.
  playerLayer.frame = self.videoView.layer.bounds;
  [self.videoView.layer addSublayer:playerLayer];
}

@end
