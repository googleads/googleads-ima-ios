#import "ViewController.h"

@interface ViewController ()

@end

@implementation ViewController

// The content URL to play.
NSString *const kTestAppContentUrl_MP4 = @"http://rmcdn.2mdn.net/Demo/html5/output.mp4";

// Ad tag
NSString *const kTestAppAdTagUrl =
    @"http://pubads.g.doubleclick.net/gampad/ads?sz=640x360&"
    @"iu=/6062/iab_vast_samples/skippable&ciu_szs=300x250,728x90&impl=s&"
    @"gdfp_req=1&env=vp&output=xml_vast3&unviewed_position_start=1&"
    @"url=[referrer_url]&correlator=[timestamp]";

- (void)viewDidLoad {
  [super viewDidLoad];

  self.playButton.layer.zPosition = MAXFLOAT;

  [self setUpContentPlayer];
}

- (IBAction)onPlayButtonTouch:(id)sender {
  [self requestAds];
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

#pragma mark SDK Setup

- (void)setupAdsLoader {
  self.adsLoader = [[IMAAdsLoader alloc] initWithSettings:nil];
  self.adsLoader.delegate = self;
}

- (void)setUpAdDisplayContainer {
  // Create our AdDisplayContainer. Initialize it with our videoView as the container. This
  // will result in ads being displayed over our content video.
  self.adDisplayContainer =
      [[IMAAdDisplayContainer alloc] initWithAdContainer:self.videoView companionSlots:nil];
}

- (void)requestAds {
  [self setupAdsLoader];
  [self setUpAdDisplayContainer];
  // Create an ad request with our ad tag, display container, and optional user context.
  IMAAdsRequest *request =
      [[IMAAdsRequest alloc] initWithAdTagUrl:kTestAppAdTagUrl
                           adDisplayContainer:self.adDisplayContainer
                                  userContext:nil];
  [self.adsLoader requestAdsWithRequest:request];
}

- (void)createAdsRenderingSettings {
  self.adsRenderingSettings = [[IMAAdsRenderingSettings alloc] init];
  self.adsRenderingSettings.webOpenerPresentingController = self;
}

- (void)createContentPlayhead {
  self.contentPlayhead = [[IMAAVPlayerContentPlayhead alloc] initWithAVPlayer:self.contentPlayer];
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(contentDidFinishPlaying)
                                               name:AVPlayerItemDidPlayToEndTimeNotification
                                             object:[self.contentPlayer currentItem]];
}

- (void)contentDidFinishPlaying {
  [self.adsLoader contentComplete];
}

#pragma mark AdsLoader Delegates

- (void)adsLoader:(IMAAdsLoader *)loader adsLoadedWithData:(IMAAdsLoadedData *)adsLoadedData {
  // Grab the instance of the IMAAdsManager and set ourselves as the delegate.
  self.adsManager = adsLoadedData.adsManager;
  self.adsManager.delegate = self;
  // Create ads rendering settings to tell the SDK to use the in-app browser.
  [self createAdsRenderingSettings];
  // Create a content playhead so the SDK can track our content for VMAP and ad rules.
  [self createContentPlayhead];
  // Initialize the ads manager.
  [self.adsManager initializeWithContentPlayhead:self.contentPlayhead
                            adsRenderingSettings:self.adsRenderingSettings];
}

- (void)adsLoader:(IMAAdsLoader *)loader failedWithErrorData:(IMAAdLoadingErrorData *)adErrorData {
  // Something went wrong loading ads. Log the error and play the content.
  NSLog(@"Error loading ads: %@", adErrorData.adError.message);
  [self.contentPlayer play];
}

#pragma mark AdsManager Delegates

- (void)adsManager:(IMAAdsManager *)adsManager
    didReceiveAdEvent:(IMAAdEvent *)event {
  // When the SDK notified us that ads have been loaded, play them.
  if (event.type == kIMAAdEvent_LOADED) {
    [adsManager start];
  }
}

- (void)adsManager:(IMAAdsManager *)adsManager
    didReceiveAdError:(IMAAdError *)error {
  // Something went wrong with the ads manager after ads were loaded. Log the error and play the
  // content.
  NSLog(@"AdsManager error: %@", error.message);
  [self.contentPlayer play];
}

- (void)adsManagerDidRequestContentPause:(IMAAdsManager *)adsManager {
  // The SDK is going to play ads, so pause the content.
  [_contentPlayer pause];
}

- (void)adsManagerDidRequestContentResume:(IMAAdsManager *)adsManager {
  // The SDK is done playing ads (at least for now), so resume the content.
  [_contentPlayer play];
}


@end
