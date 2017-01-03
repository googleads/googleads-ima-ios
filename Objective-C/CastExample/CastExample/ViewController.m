#import "ViewController.h"

#import "CastViewController.h"

@import GoogleInteractiveMediaAds;

@interface ViewController () <IMAAdsLoaderDelegate, IMAAdsManagerDelegate>

// SDK
/// Entry point for the SDK. Used to make ad requests.
@property(nonatomic, strong) IMAAdsLoader *adsLoader;
/// Playhead used by the SDK to track content video progress and insert
/// mid-rolls.
@property(nonatomic, strong) IMAAVPlayerContentPlayhead *contentPlayhead;
/// Main point of interaction with the SDK. Created by the SDK as the result of
/// an ad request.
@property(nonatomic, strong) IMAAdsManager *adsManager;
/// If an ad is currently playing.
@property(nonatomic, assign) BOOL adPlaying;
/// Cast controller.
@property(nonatomic, strong) CastViewController *castViewController;
/// If the previous ad tag is VMAP ad.
@property(nonatomic, assign) BOOL isVMAPAd;
/// If an ad has started playing.
@property(nonatomic, assign) BOOL adStartedPlaying;

@end

@implementation ViewController

- (void)viewDidLoad {
  [super viewDidLoad];

  self.playButton.layer.zPosition = MAXFLOAT;
  // The content URL to play.
  self.kContentUrl = @"http://rmcdn.2mdn.net/Demo/html5/output.mp4";

  // Ad tag
  self.kAdTagUrl = @"https://pubads.g.doubleclick.net/gampad/ads?sz=640x480&"
      @"iu=/124319096/external/" @"single_ad_samples&ciu_szs=300x250&impl=s&gdfp_req=1&env=vp&"
      @"output=vast&unviewed_position_start=1&cust_params=deployment%3Ddevsite%"
      @"26sample_ct%3Dlinear&" @"correlator=";
  self.isVMAPAd = false;

  // Position and size of cast button.
  const float kCastButtonXPosition = self.view.frame.size.width * 0.9;
  const float kCastButtonYPosition = self.view.frame.size.height * 0.1;
  const float kCastButtonWidth = 40;
  const float kCastButtonHeight = 40;

  [self setupAdsLoader];
  [self setUpContentPlayer];
  self.castViewController = [[CastViewController alloc] initWithViewController:self];
  self.castViewController.view.frame =
      CGRectMake(kCastButtonXPosition, kCastButtonYPosition, kCastButtonWidth, kCastButtonHeight);
  [self.view addSubview:self.castViewController.view];
  [self.view bringSubviewToFront:self.castViewController.view];
}

- (void)showChooseDevice {
  [self.navigationController pushViewController:self.castViewController animated:YES];
}

- (IBAction)onPlayButtonTouch:(id)sender {
  [self requestAds];
  [self.contentPlayer play];
  self.playButton.hidden = YES;
}

// Plays/resumes the content or ad.
- (void)playVideo {
  if (!self.adPlaying) {
    [self.contentPlayer play];
  } else {
    [self.adsManager resume];
  }
}

// Pauses the content or ad.
- (void)pauseVideo {
  if (!self.adPlaying) {
    [self.contentPlayer pause];
  } else {
    [self.adsManager pause];
  }
}

// Seeks the content.
- (void)seekContent:(CMTime)time {
  if (!self.adPlaying) {
    [self.contentPlayer seekToTime:time];
  }
}

#pragma mark Content Player Setup

- (void)setUpContentPlayer {
  // Load AVPlayer with path to our content.
  NSURL *contentURL = [NSURL URLWithString:self.kContentUrl];
  self.contentPlayer = [AVPlayer playerWithURL:contentURL];

  // Create a player layer for the player.
  AVPlayerLayer *playerLayer = [AVPlayerLayer playerLayerWithPlayer:self.contentPlayer];

  // Size, position, and display the AVPlayer.
  playerLayer.frame = self.videoView.layer.bounds;
  [self.videoView.layer addSublayer:playerLayer];

  // Set up our content playhead and contentComplete callback.
  self.contentPlayhead = [[IMAAVPlayerContentPlayhead alloc] initWithAVPlayer:self.contentPlayer];
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(contentDidFinishPlaying:)
                                               name:AVPlayerItemDidPlayToEndTimeNotification
                                             object:self.contentPlayer.currentItem];
}

#pragma mark SDK Setup

- (void)setupAdsLoader {
  self.adsLoader = [[IMAAdsLoader alloc] initWithSettings:nil];
  self.adsLoader.delegate = self;
}

- (void)requestAds {
  // Create an ad display container for ad rendering.
  IMAAdDisplayContainer *adDisplayContainer =
      [[IMAAdDisplayContainer alloc] initWithAdContainer:self.videoView companionSlots:nil];
  // Create an ad request with our ad tag, display container, and optional user
  // context.
  IMAAdsRequest *request = [[IMAAdsRequest alloc] initWithAdTagUrl:self.kAdTagUrl
                                                adDisplayContainer:adDisplayContainer
                                                   contentPlayhead:self.contentPlayhead
                                                       userContext:nil];
  [self.adsLoader requestAdsWithRequest:request];
}

- (void)contentDidFinishPlaying:(NSNotification *)notification {
  // Make sure we don't call contentComplete as a result of an ad completing.
  if (notification.object == self.contentPlayer.currentItem) {
    [self.adsLoader contentComplete];
  }
}

#pragma mark AdsLoader Delegates

- (void)adsLoader:(IMAAdsLoader *)loader adsLoadedWithData:(IMAAdsLoadedData *)adsLoadedData {
  // Grab the instance of the IMAAdsManager and set ourselves as the delegate.
  self.adsManager = adsLoadedData.adsManager;
  self.adsManager.delegate = self;
  // Create ads rendering settings to tell the SDK to use the in-app browser.
  IMAAdsRenderingSettings *adsRenderingSettings = [[IMAAdsRenderingSettings alloc] init];
  adsRenderingSettings.webOpenerPresentingController = self;
  // Initialize the ads manager.
  [self.adsManager initializeWithAdsRenderingSettings:adsRenderingSettings];
}

- (void)adsLoader:(IMAAdsLoader *)loader failedWithErrorData:(IMAAdLoadingErrorData *)adErrorData {
  // Something went wrong loading ads. Log the error and play the content.
  NSLog(@"Error loading ads: %@", adErrorData.adError.message);
  [self.contentPlayer play];
}

#pragma mark AdsManager Delegates

- (void)adsManager:(IMAAdsManager *)adsManager didReceiveAdEvent:(IMAAdEvent *)event {
  // When the SDK notified us that ads have been loaded, play them.
  if (event.type == kIMAAdEvent_LOADED) {
    [adsManager start];
    self.adStartedPlaying = true;
    if ([adsManager.adCuePoints count] > 0) {
      self.isVMAPAd = true;
    }
  }
}

- (void)adsManager:(IMAAdsManager *)adsManager didReceiveAdError:(IMAAdError *)error {
  // Something went wrong with the ads manager after ads were loaded. Log the
  // error and play the content.
  NSLog(@"AdsManager error: %@", error.message);
  [self.contentPlayer play];
}

- (void)adsManagerDidRequestContentPause:(IMAAdsManager *)adsManager {
  // The SDK is going to play ads, so pause the content.
  [self.contentPlayer pause];
  self.adPlaying = true;
}

- (void)adsManagerDidRequestContentResume:(IMAAdsManager *)adsManager {
  // The SDK is done playing ads (at least for now), so resume the content.
  [self.contentPlayer play];
  self.adPlaying = false;
}

@end
