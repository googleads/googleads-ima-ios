#import "VideoViewController.h"

@import AVFoundation;

#import "Constants.h"

typedef enum { PlayButton, PauseButton } PlayButtonType;

@interface VideoViewController () <AVPictureInPictureControllerDelegate, IMAAdsLoaderDelegate,
                                   IMAAdsManagerDelegate, UIAlertViewDelegate>

// Tracking for play/pause.
@property(nonatomic) BOOL isAdPlayback;

// Play/Pause buttons.
@property(nonatomic, strong) UIImage *playBtnBG;
@property(nonatomic, strong) UIImage *pauseBtnBG;

// PiP objects.
@property(nonatomic, strong) AVPictureInPictureController *pictureInPictureController;
@property(nonatomic, strong) IMAPictureInPictureProxy *pictureInPictureProxy;

// Storage points for resizing between fullscreen and non-fullscreen
/// Frame for video player in fullscreen mode.
@property(nonatomic, assign) CGRect fullscreenVideoFrame;

/// Frame for video view in portrait mode.
@property(nonatomic, assign) CGRect portraitVideoViewFrame;

/// Frame for video player in portrait mode.
@property(nonatomic, assign) CGRect portraitVideoFrame;

/// Frame for controls in fullscreen mode.
@property(nonatomic, assign) CGRect fullscreenControlsFrame;

/// Frame for controls view in portrait mode.
@property(nonatomic, assign) CGRect portraitControlsViewFrame;

/// Frame for controls in portrait mode.
@property(nonatomic, assign) CGRect portraitControlsFrame;

/// Flag for tracking fullscreen.
@property(nonatomic, assign) BOOL fullscreen;

/// Gesture recognizer for tap on video.
@property(nonatomic, strong) UITapGestureRecognizer *videoTapRecognizer;

// IMA objects.
@property(nonatomic, strong) IMAAVPlayerContentPlayhead *contentPlayhead;
@property(nonatomic, strong) IMAAdsManager *adsManager;
@property(nonatomic, strong) IMACompanionAdSlot *companionSlot;

// Content player objects.
@property(nonatomic, strong) AVPlayer *contentPlayer;
@property(nonatomic, strong) AVPlayerLayer *contentPlayerLayer;
@property(nonatomic, strong) id playHeadObserver;

@end

@implementation VideoViewController

#pragma mark Set-up methods

// Set up the new view controller.
- (void)viewDidLoad {
  [super viewDidLoad];
  [self.topLabel setText:self.video.title];
  // Set the play button image.
  self.playBtnBG = [UIImage imageNamed:@"play.png"];
  // Set the pause button image.
  self.pauseBtnBG = [UIImage imageNamed:@"pause.png"];
  self.isAdPlayback = NO;
  self.fullscreen = NO;

  // Fix iPhone issue of log text starting in the middle of the UITextView
  self.automaticallyAdjustsScrollViewInsets = NO;

  // Set up CGRects for resizing the video and controls on rotate.
  CGRect videoViewBounds = self.videoView.bounds;
  self.portraitVideoViewFrame = self.videoView.frame;
  self.portraitVideoFrame =
      CGRectMake(0, 0, videoViewBounds.size.width, videoViewBounds.size.height);

  CGRect videoControlsBounds = self.videoControls.bounds;
  self.portraitControlsViewFrame = self.videoControls.frame;
  self.portraitControlsFrame =
      CGRectMake(0, 0, videoControlsBounds.size.width, videoControlsBounds.size.height);

  // Set videoView on top of everything else (for fullscreen support).
  [self.view bringSubviewToFront:self.videoView];
  [self.view bringSubviewToFront:self.videoControls];

  // Check orientation, set to fullscreen if we're in landscape
  if ([[UIDevice currentDevice] orientation] == UIDeviceOrientationLandscapeLeft ||
      [[UIDevice currentDevice] orientation] == UIDeviceOrientationLandscapeRight) {
    [self viewDidEnterLandscape];
  }

  // Set up content player and IMA classes, then request ads. If the user selected "Custom",
  // get the ad tag from the pop-up dialog.
  [self setUpContentPlayer];
  [self setUpIMA];
  if ([self.video.tag isEqual:@"custom"]) {
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Tag"
                                                    message:@"Enter your test tag below"
                                                   delegate:self
                                          cancelButtonTitle:@"OK"
                                          otherButtonTitles:nil];
    alert.alertViewStyle = UIAlertViewStylePlainTextInput;
    [alert show];
  } else {
    [self requestAdsWithTag:self.video.tag];
  }
}

- (void)viewWillDisappear:(BOOL)animated {
  [self.contentPlayer pause];
  // Don't reset if we're presenting a modal view (e.g. in-app clickthrough).
  if ([self.navigationController.viewControllers indexOfObject:self] == NSNotFound) {
    if (self.adsManager) {
      [self.adsManager destroy];
      self.adsManager = nil;
    }
    self.contentPlayer = nil;
  }
  [super viewWillDisappear:animated];
}

// If pop-up dialog was shown, request ads with provided tag on dialog close.
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
  [self requestAdsWithTag:[[alertView textFieldAtIndex:0] text]];
}

// Initialize the content player and load content.
- (void)setUpContentPlayer {
  // Load AVPlayer with path to our content.
  NSURL *contentURL = [NSURL URLWithString:self.video.video];
  self.contentPlayer = [AVPlayer playerWithURL:contentURL];

  // Playhead observers for progress bar.
  __weak VideoViewController *controller = self;
  self.playHeadObserver = [controller.contentPlayer
      addPeriodicTimeObserverForInterval:CMTimeMake(1, 30)
                                   queue:NULL
                              usingBlock:^(CMTime time) {
                                CMTime duration = [controller
                                    getPlayerItemDuration:controller.contentPlayer.currentItem];
                                [controller updatePlayHeadWithTime:time duration:duration];
                              }];
  [self.contentPlayer addObserver:self forKeyPath:@"rate" options:0 context:@"contentPlayerRate"];
  [self.contentPlayer addObserver:self
                       forKeyPath:@"currentItem.duration"
                          options:0
                          context:@"playerDuration"];
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(contentDidFinishPlaying:)
                                               name:AVPlayerItemDidPlayToEndTimeNotification
                                             object:self.contentPlayer.currentItem];
  // Create content playhead.
  self.contentPlayhead = [[IMAAVPlayerContentPlayhead alloc] initWithAVPlayer:self.contentPlayer];

  // Set up fullscreen tap listener to show controls.
  self.videoTapRecognizer =
      [[UITapGestureRecognizer alloc] initWithTarget:self
                                              action:@selector(showFullscreenControls:)];
  [self.videoView addGestureRecognizer:self.videoTapRecognizer];

  // Create a player layer for the player.
  self.contentPlayerLayer = [AVPlayerLayer playerLayerWithPlayer:self.contentPlayer];

  // Size, position, and display the AVPlayer.
  self.contentPlayerLayer.frame = self.videoView.layer.bounds;
  [self.videoView.layer addSublayer:self.contentPlayerLayer];

  // Set ourselves up for PiP.
  self.pictureInPictureProxy =
      [[IMAPictureInPictureProxy alloc] initWithAVPictureInPictureControllerDelegate:self];
  self.pictureInPictureController =
      [[AVPictureInPictureController alloc] initWithPlayerLayer:self.contentPlayerLayer];
  self.pictureInPictureController.delegate = self.pictureInPictureProxy;
  if (![AVPictureInPictureController isPictureInPictureSupported] && self.pictureInPictureButton) {
    self.pictureInPictureButton.hidden = YES;
  }
}

// Handler for keypath listener that is added for content playhead observer.
- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context {
  if (context == @"contentPlayerRate" && self.contentPlayer == object) {
    [self updatePlayHeadState:(self.contentPlayer.rate != 0)];
  } else if (context == @"playerDuration" && self.contentPlayer == object) {
    [self
        updatePlayHeadDurationWithTime:[self getPlayerItemDuration:self.contentPlayer.currentItem]];
  }
}

#pragma mark UI handlers

// Handle clicks on play/pause button.
- (IBAction)onPlayPauseClicked:(id)sender {
  if (!self.isAdPlayback) {
    if (self.contentPlayer.rate == 0) {
      [self.contentPlayer play];
    } else {
      [self.contentPlayer pause];
    }
  } else {
    if (self.playHeadButton.tag == PlayButton) {
      [self.adsManager resume];
      [self setPlayButtonType:PauseButton];
    } else {
      [self.adsManager pause];
      [self setPlayButtonType:PlayButton];
    }
  }
}

// Updates play button for provided playback state.
- (void)updatePlayHeadState:(BOOL)isPlaying {
  [self setPlayButtonType:isPlaying ? PauseButton : PlayButton];
}

// Sets play button type.
- (void)setPlayButtonType:(PlayButtonType)buttonType {
  self.playHeadButton.tag = buttonType;
  [self.playHeadButton setImage:buttonType == PauseButton ? self.pauseBtnBG : self.playBtnBG
                       forState:UIControlStateNormal];
}

// Called when the user seeks.
- (IBAction)playHeadValueChanged:(id)sender {
  if (![sender isKindOfClass:[UISlider class]]) {
    return;
  }
  if (self.isAdPlayback == NO) {
    UISlider *slider = (UISlider *)sender;
    // If the playhead value changed by the user, skip to that point of the
    // content is skippable.
    [self.contentPlayer seekToTime:CMTimeMake(slider.value, 1)];
  }
}

// Used to track progress of ads for progress bar.
- (void)adDidProgressToTime:(NSTimeInterval)mediaTime totalTime:(NSTimeInterval)totalTime {
  CMTime time = CMTimeMakeWithSeconds(mediaTime, 1000);
  CMTime duration = CMTimeMakeWithSeconds(totalTime, 1000);
  [self updatePlayHeadWithTime:time duration:duration];
  self.progressBar.maximumValue = totalTime;
}

// Get the duration value from the player item.
- (CMTime)getPlayerItemDuration:(AVPlayerItem *)item {
  CMTime itemDuration = kCMTimeInvalid;
  if ([item respondsToSelector:@selector(duration)]) {
    itemDuration = item.duration;
  } else {
    if (item.asset && [item.asset respondsToSelector:@selector(duration)]) {
      // Sometimes the test app hangs here for ios 4.2.
      itemDuration = item.asset.duration;
    }
  }
  return itemDuration;
}

// Updates progress bar for provided time and duration.
- (void)updatePlayHeadWithTime:(CMTime)time duration:(CMTime)duration {
  if (CMTIME_IS_INVALID(time)) {
    return;
  }
  Float64 currentTime = CMTimeGetSeconds(time);
  if (isnan(currentTime)) {
    return;
  }
  self.progressBar.value = currentTime;
  self.playHeadTimeText.text =
      [[NSString alloc] initWithFormat:@"%d:%02d", (int)currentTime / 60, (int)currentTime % 60];
  [self updatePlayHeadDurationWithTime:duration];
}

// Update the current playhead duration.
- (void)updatePlayHeadDurationWithTime:(CMTime)duration {
  if (CMTIME_IS_INVALID(duration)) {
    return;
  }
  Float64 durationValue = CMTimeGetSeconds(duration);
  if (isnan(durationValue)) {
    return;
  }
  self.progressBar.maximumValue = durationValue;
  self.durationTimeText.text = [[NSString alloc]
      initWithFormat:@"%d:%02d", (int)durationValue / 60, (int)durationValue % 60];
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
  switch (interfaceOrientation) {
    case UIInterfaceOrientationLandscapeLeft:
    case UIInterfaceOrientationLandscapeRight:
      [self viewDidEnterPortrait];
      break;
    case UIInterfaceOrientationPortrait:
    case UIInterfaceOrientationPortraitUpsideDown:
      [self viewDidEnterLandscape];
      break;
    case UIInterfaceOrientationUnknown:
      break;
  }
}

- (void)viewDidEnterLandscape {
  self.fullscreen = YES;
  CGRect screenRect = [[UIScreen mainScreen] bounds];
  if ([[[UIDevice currentDevice] systemVersion] floatValue] < 8.0) {
    self.fullscreenVideoFrame = CGRectMake(0, 0, screenRect.size.height, screenRect.size.width);
    self.fullscreenControlsFrame =
        CGRectMake(0, (screenRect.size.width - self.videoControls.frame.size.height),
                   screenRect.size.height, self.videoControls.frame.size.height);
  } else {
    self.fullscreenVideoFrame = CGRectMake(0, 0, screenRect.size.width, screenRect.size.height);
    self.fullscreenControlsFrame =
        CGRectMake(0, (screenRect.size.height - self.videoControls.frame.size.height),
                   screenRect.size.width, self.videoControls.frame.size.height);
  }
  [[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:UIStatusBarAnimationNone];
  [[self navigationController] setNavigationBarHidden:YES];
  self.videoView.frame = self.fullscreenVideoFrame;
  self.contentPlayerLayer.frame = self.fullscreenVideoFrame;
  self.videoControls.frame = self.fullscreenControlsFrame;
  self.videoControls.hidden = YES;
}

- (void)viewDidEnterPortrait {
  self.fullscreen = NO;
  [[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:UIStatusBarAnimationNone];
  [[self navigationController] setNavigationBarHidden:NO];
  self.videoView.frame = self.portraitVideoViewFrame;
  self.contentPlayerLayer.frame = self.portraitVideoFrame;
  self.videoControls.frame = self.portraitControlsViewFrame;
}

- (IBAction)videoControlsTouchStarted:(id)sender {
  [NSObject cancelPreviousPerformRequestsWithTarget:self
                                           selector:@selector(hideFullscreenControls)
                                             object:self];
}

- (IBAction)videoControlsTouchEnded:(id)sender {
  [self startHideControlsTimer];
}

- (void)showFullscreenControls:(UITapGestureRecognizer *)recognizer {
  if (self.fullscreen) {
    self.videoControls.hidden = NO;
    self.videoControls.alpha = 0.9;
    [self startHideControlsTimer];
  }
}

- (void)startHideControlsTimer {
  [self performSelector:@selector(hideFullscreenControls) withObject:self afterDelay:3];
}

- (void)hideFullscreenControls {
  [UIView animateWithDuration:0.5
                   animations:^{
                     self.videoControls.alpha = 0.0;
                   }];
}

- (IBAction)onPipButtonClicked:(id)sender {
  if ([self.pictureInPictureController isPictureInPictureActive]) {
    [self.pictureInPictureController stopPictureInPicture];
  } else {
    [self.pictureInPictureController startPictureInPicture];
  }
}

#pragma mark IMA SDK methods

// Initialize ad display container.
- (IMAAdDisplayContainer *)createAdDisplayContainer {
  // Create our AdDisplayContainer. Initialize it with our videoView as the container. This
  // will result in ads being displayed over our content video.
  if (self.companionView != nil) {
    return [[IMAAdDisplayContainer alloc] initWithAdContainer:self.videoView
                                               companionSlots:@[ self.companionSlot ]];
  } else {
    return [[IMAAdDisplayContainer alloc] initWithAdContainer:self.videoView companionSlots:nil];
  }
}

// Register companion slots.
- (void)setUpCompanions {
  self.companionSlot =
      [[IMACompanionAdSlot alloc] initWithView:self.companionView
                                         width:self.companionView.frame.size.width
                                        height:self.companionView.frame.size.height];
}

// Initialize AdsLoader.
- (void)setUpIMA {
  if (self.adsManager) {
    [self.adsManager destroy];
  }
  [self.adsLoader contentComplete];
  self.adsLoader.delegate = self;
  if (self.companionView != nil) {
    [self setUpCompanions];
  }
}

// Request ads for provided tag.
- (void)requestAdsWithTag:(NSString *)adTagUrl {
  [self logMessage:@"Requesting ads"];
  // Create an ad request with our ad tag, display container, and optional user context.
  IMAAdsRequest *request = [[IMAAdsRequest alloc]
           initWithAdTagUrl:adTagUrl
         adDisplayContainer:[self createAdDisplayContainer]
       avPlayerVideoDisplay:[[IMAAVPlayerVideoDisplay alloc] initWithAVPlayer:self.contentPlayer]
      pictureInPictureProxy:self.pictureInPictureProxy
                userContext:nil];
  [self.adsLoader requestAdsWithRequest:request];
}

// Notify IMA SDK when content is done for post-rolls.
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
  [self logMessage:@"Error loading ads: %@", adErrorData.adError.message];
  self.isAdPlayback = NO;
  [self setPlayButtonType:PauseButton];
  [self.contentPlayer play];
}

#pragma mark AdsManager Delegates

- (void)adsManager:(IMAAdsManager *)adsManager didReceiveAdEvent:(IMAAdEvent *)event {
  [self logMessage:@"AdsManager event (%@).", event.typeString];
  // When the SDK notified us that ads have been loaded, play them.
  switch (event.type) {
    case kIMAAdEvent_LOADED:
      if (![self.pictureInPictureController isPictureInPictureActive]) {
        [adsManager start];
      }
      break;
    case kIMAAdEvent_PAUSE:
      [self setPlayButtonType:PlayButton];
      break;
    case kIMAAdEvent_RESUME:
      [self setPlayButtonType:PauseButton];
      break;
    case kIMAAdEvent_TAPPED:
      [self showFullscreenControls:nil];
      break;
    default:
      break;
  }
}

- (void)adsManager:(IMAAdsManager *)adsManager didReceiveAdError:(IMAAdError *)error {
  // Something went wrong with the ads manager after ads were loaded. Log the error and play the
  // content.
  [self logMessage:@"AdsManager error: %@", error.message];
  self.isAdPlayback = NO;
  [self setPlayButtonType:PauseButton];
  [self.contentPlayer play];
}

- (void)adsManagerDidRequestContentPause:(IMAAdsManager *)adsManager {
  // The SDK is going to play ads, so pause the content.
  self.isAdPlayback = YES;
  [self setPlayButtonType:PauseButton];
  [self.contentPlayer pause];
}

- (void)adsManagerDidRequestContentResume:(IMAAdsManager *)adsManager {
  // The SDK is done playing ads (at least for now), so resume the content.
  self.isAdPlayback = NO;
  [self setPlayButtonType:PauseButton];
  [self.contentPlayer play];
}

#pragma mark Utility methods

- (void)logMessage:(NSString *)log, ... {
  va_list args;
  va_start(args, log);
  NSString *s = [[NSString alloc] initWithFormat:[[NSString alloc] initWithFormat:@"%@\n", log]
                                       arguments:args];
  self.consoleView.text = [self.consoleView.text stringByAppendingString:s];
  NSLog(@"%@", s);
  va_end(args);
  if (self.consoleView.text.length > 0) {
    NSRange bottom = NSMakeRange(self.consoleView.text.length - 1, 1);
    [self.consoleView scrollRangeToVisible:bottom];
  }
}

- (void)didReceiveMemoryWarning {
  [super didReceiveMemoryWarning];
  // Dispose of any resources that can be recreated.
}

@end
