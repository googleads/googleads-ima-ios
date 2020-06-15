#import "ViewController.h"

#import "CastMessageChannel.h"

@import GoogleCast;
@import GoogleInteractiveMediaAds;

@interface ViewController () <CastMessageChannelDelegate,
                              GCKSessionManagerListener,
                              IMAAdsLoaderDelegate,
                              IMAAdsManagerDelegate>

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
/// If the previous ad tag is VMAP ad.
@property(nonatomic, assign) BOOL isVMAPAd;
/// If an ad has started playing.
@property(nonatomic, assign) BOOL adStartedPlaying;
/// If cast player is currently playing an ad.
@property(nonatomic, assign) BOOL castAdPlaying;
/// Last known content time on cast player.
@property(nonatomic, assign) CMTime castContentTime;

@end

@implementation ViewController

static NSString *const kCUSTOM_NAMESPACE = @"urn:x-cast:com.google.ads.ima.cast";

- (void)viewDidLoad {
  [super viewDidLoad];

  self.playButton.layer.zPosition = MAXFLOAT;
  // The content URL to play.
  self.kContentUrl = @"https://storage.googleapis.com/gvabox/media/samples/stock.mp4";

  // Ad tag
  self.kAdTagUrl = @"https://pubads.g.doubleclick.net/gampad/ads?sz=640x480&"
      @"iu=/124319096/external/" @"single_ad_samples&ciu_szs=300x250&impl=s&gdfp_req=1&env=vp&"
      @"output=vast&unviewed_position_start=1&cust_params=deployment%3Ddevsite%"
      @"26sample_ct%3Dlinear&" @"correlator=";
  self.isVMAPAd = false;

  [self setupAdsLoader];
  [self setUpContentPlayer];


  const float kCastButtonXPosition = self.view.frame.size.width * 0.85;
  const float kCastButtonYPosition = self.view.frame.size.height * 0.05;
  const float kCastButtonWidth = 24;
  const float kCastButtonHeight = 24;
  CGRect frame =
      CGRectMake(kCastButtonXPosition, kCastButtonYPosition, kCastButtonWidth, kCastButtonHeight);
  GCKUICastButton *castButton = [[GCKUICastButton alloc] initWithFrame:frame];
  castButton.tintColor = [UIColor blackColor];
  [self.view addSubview:castButton];

  [[GCKCastContext sharedInstance].sessionManager addListener:self];
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
      [[IMAAdDisplayContainer alloc] initWithAdContainer:self.videoView
                                          viewController:self
                                          companionSlots:nil];
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

#pragma mark GCKSessionManagerListener

-(void)sessionManager:(GCKSessionManager *)sessionManager
    didStartCastSession:(GCKCastSession *)session {
  self.messageChannel =
      [[CastMessageChannel alloc] initWithNamespace:kCUSTOM_NAMESPACE];
  self.messageChannel.delegate = self;
  [session addChannel:self.messageChannel];
  [self castVideo:self];
}

-(void)sessionManager:(GCKSessionManager *)sessionManager
    willEndCastSession:(nonnull GCKCastSession *)session
            withError:(NSError * _Nullable)error {
  [self playVideo];
  if (self.castAdPlaying) {
    // If ad is playing on cast, seek to last known content location.
    [self seekContent:self.castContentTime];
  } else {
    // If content is playing on cast, seek to content position of
    // cast device. Stream position is returned in microseconds.
    CMTime videoPosition =
        CMTimeMakeWithSeconds(session.remoteMediaClient.approximateStreamPosition, 1000000);
    [self seekContent:videoPosition];
  }
}

- (void)castVideo:(id)sender {
  [self pauseVideo];
  NSString *contentUrl = self.kContentUrl;
  GCKMediaMetadata *metadata = [[GCKMediaMetadata alloc] init];
  GCKMediaInformation *mediaInformation =
      [[GCKMediaInformation alloc] initWithContentID:contentUrl
                                          streamType:GCKMediaStreamTypeBuffered
                                         contentType:@"video/mp4"
                                            metadata:metadata
                                      streamDuration:0
                                         mediaTracks:nil
                                      textTrackStyle:nil
                                          customData:nil];
  GCKCastSession *session =
      [GCKCastContext sharedInstance].sessionManager.currentCastSession;
  if (session) {
    [session.remoteMediaClient loadMedia:mediaInformation autoplay:NO];
  }
  if (self.isVMAPAd || !self.adStartedPlaying) {
    [self sendMessage:[[NSString alloc]
                       initWithFormat:@"requestAd,%@,%f", self.kAdTagUrl,
                       CMTimeGetSeconds(self.contentPlayer.currentTime)]];
  } else {
    [self sendMessage:[[NSString alloc]
                       initWithFormat:@"seek,%f",
                       CMTimeGetSeconds(self.contentPlayer.currentTime)]];
  }
}

- (void)sendMessage:(NSString *)message {
  NSLog(@"Sending message: %@", message);
  [self.messageChannel sendTextMessage:message error:nil];
}

#pragma mark CastMessageChannelDelegate

- (void)castChannel:(CastMessageChannel *)channel didReceiveMessage:(NSString *)message {
  NSLog(@"Received message: %@", message);
  NSArray *splitMessage = [message componentsSeparatedByString:@","];
  NSString *event = splitMessage[0];
  if ([event isEqualToString:@"onContentPauseRequested"]) {
    self.castAdPlaying = true;
    self.castContentTime = CMTimeMakeWithSeconds([splitMessage[1] floatValue], 1);
  } else if ([event isEqualToString:@"onContentResumeRequested"]) {
    self.castAdPlaying = false;
  }
}

@end
