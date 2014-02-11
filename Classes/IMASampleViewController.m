//
//  IMASampleViewController.m
//  SampleAppV3
//
//  Copyright (c) 2013 Google Inc. All rights reserved.

#import "IMASampleViewController.h"

#import "IMACompanionAdSlot.h"
#import "IMAAdsRequest.h"

const char* AdEventNames[] = {
  "All Ads Complete",
  "Clicked",
  "Complete",
  "First Quartile",
  "Loaded",
  "Midpoint",
  "Pause",
  "Resume",
  "Third Quartile",
  "Started",
};

typedef enum {
  PlayButton,
  PauseButton
} PlayButtonType;

@interface IMASampleViewController () <IMAWebOpenerDelegate> {
  // Tracks in this app has playback control or the SDK's ad player.
  BOOL _isAdPlayback;
}

// Private functions
- (void)setupAdsLoader;
- (void)setupCompanions;
- (void)unloadAdsManager;

@end

@implementation IMASampleViewController

// The content URL to play.
NSString *const kTestAppContentUrl_MP4 =
    @"http://rmcdn.2mdn.net/Demo/html5/output.mp4";

// Three ad examples.
NSString *const kTestAppAdTagUrl_Instream1 =
    @"http://pubads.g.doubleclick.net/gampad/ads?sz=400x300&iu=%2F6062%2Fhanna_"
    @"MA_group%2Fvideo_comp_app&ciu_szs=&impl=s&gdfp_req=1&env=vp&output=xml"
    @"_vast2&unviewed_position_start=1&m_ast=vast&url=[referrer_url]&correla"
    @"tor=[timestamp]";

NSString *const kTestAppAdTagUrl_AdRules =
    @"http://pubads.g.doubleclick.net/gampad/ads?sz=640x480&iu="
    @"%2F15018773%2Feverything2&ciu_szs=300x250%2C468x60%2C728x90&impl=s&"
    @"gdfp_req=1&env=vp&output=xml_vast2&unviewed_position_start=1&url=dummy"
    @"&correlator=[timestamp]&cmsid=133&vid=10XWSh7W4so&ad_rule=1";

NSString *const kTestAppAdTagUrl_Wrapper =
    @"http://pubads.g.doubleclick.net/gampad/ads?sz=400x300&iu=%2F6062%2Fhanna_"
    @"MA_group%2Fwrapper_with_comp&ciu_szs=728x90&impl=s&gdfp_req=1&env=vp&o"
    @"utput=xml_vast2&unviewed_position_start=1&m_ast=vast&url=[referrer_url"
    @"]&correlator=[timestamp]";

NSString *const kTestAppAdTagUrl_AdSense =
    @"http://googleads.g.doubleclick.net/pagead/ads"
    @"?client=ca-video-afvtest"
    @"&ad_type=video";

- (id)initWithNibName:(NSString *)nibNameOrNil
               bundle:(NSBundle *)nibBundleOrNil {
  if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
    return [super
            initWithNibName:[NSString stringWithFormat:@"%@_iPad", nibNameOrNil]
                     bundle:nibBundleOrNil];
  }
  return [super
          initWithNibName:[NSString stringWithFormat:@"%@_iPhone", nibNameOrNil]
                   bundle:nibBundleOrNil];
}

- (void)viewDidLoad {
  [super viewDidLoad];
  // Set the play button image.
  self.playBtnBG = [UIImage imageNamed:@"play.png"];
  // Set the pause button image.
  self.pauseBtnBG = [UIImage imageNamed:@"pause.png"];
  [self.titleLabel setText:@"Sample App: Google SDK"];
  self.adTagUrlTextField.text = kTestAppAdTagUrl_Instream1;
  [self setUpContentPlayer:kTestAppContentUrl_MP4];
  [self setupCompanions];

  // By default, allow in-app web browser.
  self.adsRenderingSettings = [[IMAAdsRenderingSettings alloc] init];
  self.adsRenderingSettings.webOpenerDelegate = self;
  self.adsRenderingSettings.webOpenerPresentingController = self;

  // Set up CGRects for resizing the video on rotate
  CGPoint videoViewOrigin = self.videoView.frame.origin;
  CGRect videoViewBounds = self.videoView.bounds;
  self.portraitViewFrame = CGRectMake(videoViewOrigin.x,
                                      videoViewOrigin.y,
                                      videoViewBounds.size.width,
                                      videoViewBounds.size.height);
  self.portraitVideoFrame = CGRectMake(0,
                                       0,
                                       videoViewBounds.size.width,
                                       videoViewBounds.size.height);
  CGRect screenRect = [[UIScreen mainScreen] bounds];
  self.fullscreenFrame = CGRectMake(0, 0, screenRect.size.height, screenRect.size.width);

  // Set videoView on top of everything else (for fullscreen suport)
  [self.view bringSubviewToFront:self.videoView];

  [self setupAdsLoader];
  _isAdPlayback = NO;
  [self logMessage:@"IMA SDK version: %@", [IMAAdsLoader sdkVersion]];
}

#pragma mark Private helper functions implementations

- (IMASettings *)createIMASettings {
  IMASettings *settings = [[IMASettings alloc] init];
  settings.ppid = @"IMA_PPID_0";
  settings.language = self.language;
  return settings;
}

- (void)setupAdsLoader {
  // Initalize Google IMA ads Loader.
  self.adsLoader =
      [[IMAAdsLoader alloc] initWithSettings:[self createIMASettings]];
  // Implement delegate methods to get callbacks from the adsLoader.
  self.adsLoader.delegate = self;
}

- (void)setUpContentPlayer:(NSString *)contentURL {
  // Create a content player item and set it in the content player.
  AVAsset *contentAsset =
      [AVURLAsset URLAssetWithURL:[NSURL URLWithString:contentURL] options:0];
  AVPlayerItem *contentPlayerItem =
      [AVPlayerItem playerItemWithAsset:contentAsset];
  self.contentPlayer = [AVPlayer playerWithPlayerItem:contentPlayerItem];
  __weak IMASampleViewController *controller = self;
  self.playHeadObserver = [controller.contentPlayer
      addPeriodicTimeObserverForInterval:CMTimeMake(1, 30)
      queue:NULL
      usingBlock:^(CMTime time) {
        CMTime duration =
            [controller getPlayerItemDuration:self.contentPlayer.currentItem];
        [controller updatePlayHeadWithTime:time
                                  duration:duration];
      }];
  [self.contentPlayer addObserver:self
                       forKeyPath:@"rate"
                          options:0
                          context:@"contentPlayerRate"];
  [self.contentPlayer addObserver:self
                       forKeyPath:@"currentItem.duration"
                          options:0
                          context:@"playerDuration"];
  self.contentPlayhead =
      [[IMAAVPlayerContentPlayhead alloc] initWithAVPlayer:self.contentPlayer];

  [[NSNotificationCenter defaultCenter]
      addObserver:self
        selector:@selector(contentDidFinishPlaying)
            name:AVPlayerItemDidPlayToEndTimeNotification
          object:contentPlayerItem];

  // Attach the content player to the Video view.
  self.contentPlayerLayer =
      [AVPlayerLayer playerLayerWithPlayer:self.contentPlayer];
  self.contentPlayerLayer.frame = self.videoView.layer.bounds;
  [self.videoView.layer addSublayer:self.contentPlayerLayer];
}

- (void)contentDidFinishPlaying {
  [self logMessage:@"Content has completed"];
  [self.adsLoader contentComplete];
}

- (void)updatePlayHeadWithTime:(CMTime)time duration:(CMTime)duration{
  if (CMTIME_IS_INVALID(time)) {
    return;
  }
  Float64 currentTime = CMTimeGetSeconds(time);
  if (isnan(currentTime)) {
    return;
  }
  self.progressBar.value = currentTime;
  self.playHeadTimeText.text =
      [NSString stringWithFormat:@"%d:%02d",
      (int)currentTime / 60,
      (int)currentTime % 60];
  [self updatePlayHeadDurationWithTime:duration];
}

// Get the duration value from the player item.
- (CMTime)getPlayerItemDuration:(AVPlayerItem *)item {
  CMTime itemDuration = kCMTimeInvalid;
  if ([item respondsToSelector:@selector(duration)]) {
    itemDuration = item.duration;
  }
  else {
    if (item.asset &&
        [item.asset respondsToSelector:@selector(duration)]) {
      // Sometimes the test app hangs here for ios 4.2.
      itemDuration = item.asset.duration;
    }
  }
  return itemDuration;
}

// Update the current playhead duration
- (void)updatePlayHeadDurationWithTime:(CMTime)duration {
  if (CMTIME_IS_INVALID(duration)) {
    return;
  }
  Float64 durationValue = CMTimeGetSeconds(duration);
  if (isnan(durationValue)) {
    return;
  }
  self.progressBar.maximumValue = durationValue;
  self.durationTimeText.text =
      [NSString stringWithFormat:@"%d:%02d",
      (int)durationValue / 60,
      (int)durationValue % 60];
}

// Handler for keypath listener that is added.
- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context {
  if (context == @"contentPlayerRate" && self.contentPlayer == object) {
    [self updatePlayHeadState:(self.contentPlayer.rate != 0)];
  } else if (context == @"playerDuration" &&
             self.contentPlayer == object) {
    [self updatePlayHeadDurationWithTime:
        [self getPlayerItemDuration:self.contentPlayer.currentItem]];
  }
}

// Update the playHead state based on the content player rate changes.
- (void)updatePlayHeadState:(BOOL)isPlaying {
  [self setPlayButtonType:isPlaying ? PauseButton : PlayButton];
}

- (void)setupCompanions {
  // Setup the companion slots.
  NSMutableDictionary *companions = [NSMutableDictionary dictionary];
  companions[@"300x50"] =
     [[IMACompanionAdSlot alloc] initWithWidth:300 height:50];
  if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
    companions[@"728x90"] =
        [[IMACompanionAdSlot alloc] initWithWidth:728 height:90];
  }
  self.companionSlots = companions;
}

- (void)unloadAdsManager {
  [_adTagUrlTextField resignFirstResponder]; // This gets rid of the keyboard.
  if (self.adsManager != nil) {
    [self.adsManager destroy];
    self.adsManager.delegate = nil;
    self.adsManager = nil;
  }
}

#pragma mark AdsLoader Delegate implementation

- (void)adsLoader:(IMAAdsLoader *)loader
    adsLoadedWithData:(IMAAdsLoadedData *)adsLoadedData {
  [self logMessage:@"Loaded ads."];
  self.adsManager = adsLoadedData.adsManager;
  if (self.adsManager.adCuePoints.count > 0) {
    NSMutableString *cuePoints = [NSMutableString stringWithString:@"("];
    for (NSNumber *cuePoint in self.adsManager.adCuePoints) {
      [cuePoints appendFormat:@"%@, ", cuePoint];
    }
    [cuePoints replaceCharactersInRange:NSMakeRange([cuePoints length]-2, 2)
                             withString:@")"];
    [self logMessage:[NSString stringWithFormat:@"Ad cue points received: %@",
                        cuePoints]];
  }
  self.adsManager.delegate = self;
  self.adsManager.adView.frame = self.videoView.bounds;
  [self.videoView addSubview:self.adsManager.adView];
  [self.smallCompanionSlot addSubview:
       ((IMACompanionAdSlot *)self.companionSlots[@"300x50"]).view];
  [self.largeCompanionSlot addSubview:
       ((IMACompanionAdSlot *)self.companionSlots[@"728x90"]).view];

  // Default values, change these if you want to provide custom bitrate and
  // MIME types. If left to default, the SDK will select media files based
  // on the current network conditions and all MIME types supported on iOS.
  self.adsRenderingSettings.bitrate = kIMAAutodetectBitrate;
  self.adsRenderingSettings.mimeTypes = @[];
  [self.adsManager initializeWithContentPlayhead:self.contentPlayhead
                            adsRenderingSettings:self.adsRenderingSettings];
}

- (void)adsLoader:(IMAAdsLoader *)loader
    failedWithErrorData:(IMAAdLoadingErrorData *)adErrorData {
  [self logMessage:@"Ad loading error: code:%d, message: %@",
                   adErrorData.adError.code,
                   adErrorData.adError.message];
}

#pragma mark IMABrowser Delegate implementation

- (void)browserDidOpen {
  [self logMessage:@"In-app browser did open."];
}

- (void)browserDidClose {
  [self logMessage:@"In-app browser did close."];
}

#pragma mark AdsManager Delegate implementation

- (void)adsManager:(IMAAdsManager *)adsManager
    didReceiveAdEvent:(IMAAdEvent *)event {
  [self logMessage:@"AdsManager event (%s).", AdEventNames[event.type]];

  switch (event.type) {
    case kIMAAdEvent_LOADED:
      [adsManager start];
      break;
    case kIMAAdEvent_ALL_ADS_COMPLETED:
      [self unloadAdsManager];
      break;
    case kIMAAdEvent_STARTED: {
      NSString *adPodInfoString =
          [NSString stringWithFormat:
              @"Showing ad %d/%d, bumper: %@",
              event.ad.adPodInfo.adPosition,
              event.ad.adPodInfo.totalAds,
              event.ad.adPodInfo.isBumper ? @"YES" : @"NO"];

      _adPodInfoLabel.text = adPodInfoString;
      // Log extended data.
      NSString *extendedAdPodInfo =
          [NSString stringWithFormat:@"%@, pod index: %d, time offset: %lf, max duration: %lf",
              adPodInfoString,
              event.ad.adPodInfo.podIndex,
              event.ad.adPodInfo.timeOffset,
              event.ad.adPodInfo.maxDuration];

      [self logMessage:extendedAdPodInfo];
      break;
    }
    case kIMAAdEvent_COMPLETE:
      _adPodInfoLabel.text = @"";
      break;
    default:
      // no-op
      break;
  }
}

- (void)adsManager:(IMAAdsManager *)adsManager
    didReceiveAdError:(IMAAdError *)error {
  [self logMessage:@"AdsManager error with type: %d\ncode: %d\nmessage: %@",
                   error.type,
                   error.code,
                   error.message];
}

- (void)adsManagerDidRequestContentPause:(IMAAdsManager *)adsManager {
  [self logMessage:@"AdsManager requested content pause."];
  [_contentPlayer pause];
  _isAdPlayback = YES;
  [self setPlayButtonType:PauseButton];
}

- (void)adsManagerDidRequestContentResume:(IMAAdsManager *)adsManager {
  [self logMessage:@"AdsManager requested content resume."];
  [_contentPlayer play];
  _isAdPlayback = NO;
  [self setPlayButtonType:PlayButton];
}

- (void)adDidProgressToTime:(NSTimeInterval)mediaTime
                  totalTime:(NSTimeInterval)totalTime {
  CMTime time = CMTimeMakeWithSeconds(mediaTime, 1000);
  CMTime duration = CMTimeMakeWithSeconds(totalTime, 1000);
  [self updatePlayHeadWithTime:time duration:duration];
  self.progressBar.maximumValue = totalTime;
  [self setPlayButtonType:PauseButton];
}

#pragma mark UIOutlet function implementations

// Playhead control method.
- (IBAction)onPlayPauseClicked:(id)sender {
  if (_isAdPlayback == NO) {
    if (_contentPlayer.rate == 0) {
      [_contentPlayer play];
    } else {
      [_contentPlayer pause];
    }
  } else {
    if (self.playHeadButton.tag == PlayButton) {
      [_adsManager resume];
      [self setPlayButtonType:PauseButton];
    } else {
      [_adsManager pause];
      [self setPlayButtonType:PlayButton];
    }
  }
}

// Called when the user seeks.
- (IBAction)playHeadValueChanged:(id)sender {
  if (![sender isKindOfClass:[UISlider class]]) {
    return;
  }
  UISlider *slider = (UISlider *)sender;
  // If the playhead value changed by the user, skip to that point of the
  // content is skippable.
  [self.contentPlayer seekToTime:CMTimeMake(slider.value, 1)];
}

// Called when the Ad tag example value changed.
- (IBAction)adTagValueChanged:(id)sender {
  // This gets rid of the keyboard.
  [self.adTagUrlTextField resignFirstResponder];
  if (![sender isKindOfClass:[UISegmentedControl class]]) {
    return;
  }
  UISegmentedControl *control = (UISegmentedControl *)sender;
  switch(control.selectedSegmentIndex) {
    case 1:
      self.adTagUrlTextField.text = kTestAppAdTagUrl_AdRules;
      return;
    case 2:
      self.adTagUrlTextField.text = kTestAppAdTagUrl_Wrapper;
      return;
    case 3:
      self.adTagUrlTextField.text = kTestAppAdTagUrl_AdSense;
      return;
    default:
      self.adTagUrlTextField.text = kTestAppAdTagUrl_Instream1;
      return;
  }
}

// Request an ad using Google IMA SDK.
- (IBAction)onRequestAds {
  [self logMessage:@"Requesting ads."];
  [self unloadAdsManager];

  // Create an adsRequest object and request ads from the ad server.
  IMAAdsRequest *request =
      [[IMAAdsRequest alloc] initWithAdTagUrl:self.adTagUrlTextField.text
                               companionSlots:[self.companionSlots allValues]
                                  userContext:nil];

  [self.adsLoader requestAdsWithRequest:request];
}

// Forcefully unload the ad and the adsManager.
- (IBAction)onUnloadAds {
  [self logMessage:@"Unloading ads\n"];
  [self unloadAdsManager];
}

// Reset the state of the test app.
- (IBAction)onResetState {
  [self resetAppState];
}

- (IBAction)onChangeInApp {
  if ([_useInAppSwitch isOn]) {
    self.adsRenderingSettings.webOpenerDelegate = self;
    self.adsRenderingSettings.webOpenerPresentingController = self;
  } else {
    // Still want the delegate.
    self.adsRenderingSettings.webOpenerDelegate = self;
    self.adsRenderingSettings.webOpenerPresentingController = nil;
  }
}

- (IBAction)onChangeLanguage {
  UIAlertView *alert =
      [[UIAlertView alloc] initWithTitle:@"Language"
                                 message:nil
                                delegate:self
                       cancelButtonTitle:@"Continue"
                       otherButtonTitles:nil];
  alert.alertViewStyle = UIAlertViewStylePlainTextInput;
  UITextField *alertTextField = [alert textFieldAtIndex:0];
  alertTextField.placeholder = @"Examples: en, jp, zh-cn";
  [alert show];
}

// The following 2 methods are required to support upside down rotation
-(BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
  return YES;
}

-(NSUInteger)supportedInterfaceOrientations {
  return UIInterfaceOrientationMaskAll;
}

-(void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
  switch(interfaceOrientation) {
    case UIInterfaceOrientationLandscapeLeft:
    case UIInterfaceOrientationLandscapeRight:
      [self viewDidEnterPortrait];
      break;
    case UIInterfaceOrientationPortrait:
    case UIInterfaceOrientationPortraitUpsideDown:
      [self viewDidEnterLandscape];
  }
}

-(void) viewDidEnterLandscape {
  [[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:UIStatusBarAnimationNone];
  [self.videoView.layer setFrame:self.fullscreenFrame];
  [self.contentPlayerLayer setFrame:self.fullscreenFrame];
  [self.adsManager.adView setFrame:self.fullscreenFrame];
}

-(void) viewDidEnterPortrait {
  [self.videoView.layer setFrame:self.portraitViewFrame];
  [self.contentPlayerLayer setFrame:self.portraitVideoFrame];
  [self.adsManager.adView setFrame:self.portraitVideoFrame];
  [[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:UIStatusBarAnimationNone];
}

#pragma mark IMABrowser delegate functions

- (void)willOpenExternalBrowser {
  [self logMessage:@"External browser will open."];
}

- (void)willOpenInAppBrowser {
  [self logMessage:@"In-app browser will open"];
}

- (void)didOpenInAppBrowser {
  [self logMessage:@"In-app browser did open"];
}

- (void)willCloseInAppBrowser {
  [self logMessage:@"In-app browser will close"];
}

- (void)didCloseInAppBrowser {
  [self logMessage:@"In-app browser did close"];
}

#pragma mark AlertView delegate functions.

- (void)alertView:(UIAlertView *)alertView
    clickedButtonAtIndex:(NSInteger)buttonIndex {
  self.language = [[[alertView textFieldAtIndex:0] text] copy];
  // Cannot change language on an existing IMAAdsLoader, recreate it.
  [self resetAppState];
  [self logMessage:@"Ad UI language changed to %@, request ads now.",
                   self.language];
}

#pragma mark Utility Functions

- (void)resetAppState {
  self.adsManager.delegate = nil;
  [self unloadAdsManager];
  [self.adsManager destroy];
  [self.contentPlayer pause];
  [self.contentPlayer seekToTime:CMTimeMake(0, 1)];
  [self updatePlayHeadWithTime:CMTimeMake(0, 1)
                      duration:CMTimeMake(0, 1)];
  [self setupAdsLoader];
  self.console.text = @"";
  _isAdPlayback = NO;
  [self.largeCompanionSlot.subviews
       makeObjectsPerformSelector:@selector(removeFromSuperview)];
  [self.smallCompanionSlot.subviews
       makeObjectsPerformSelector:@selector(removeFromSuperview)];
  [self setupCompanions];
}

- (void)setPlayButtonType:(PlayButtonType)buttonType {
  self.playHeadButton.tag = buttonType;
  [self.playHeadButton
      setImage:buttonType == PauseButton ? self.pauseBtnBG : self.playBtnBG
      forState:UIControlStateNormal];
}

- (void)logMessage:(NSString *)log, ... {
  va_list args;
  va_start(args, log);
  NSString *s =
      [[NSString alloc] initWithFormat:[NSString stringWithFormat:@"%@\n", log]
                             arguments:args];
  self.console.text = [self.console.text stringByAppendingString:s];
  NSLog(@"%@", s);
  va_end(args);
}

@end
