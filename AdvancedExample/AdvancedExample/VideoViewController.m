#import "VideoViewController.h"

@import AVFoundation;
@import GoogleCast;

#import "CastManager.h"
#import "Video.h"

/// Fallback URL in case something goes wrong in loading the stream. If all goes well, this will not
/// be used.
static NSString *const IMATestAppContentUrl_M3U8 =
    @"http://devimages.apple.com/iphone/samples/bipbop/bipbopall.m3u8";

/// Play button type for UI.
typedef NS_ENUM(NSInteger, PlayButtonType) {
  PlayButton,  ///< Play button is shown.
  PauseButton  ///< Pause button is shown.
};

@interface VideoViewController () <IMAAdsLoaderDelegate, IMAStreamManagerDelegate>

/// Tracking for play/pause.
@property(nonatomic, assign) BOOL adPlaying;
@property(nonatomic, assign) BOOL streamPlaying;

/// Play/Pause buttons.
@property(nonatomic, strong) UIImage *playBtnBG;
@property(nonatomic, strong) UIImage *pauseBtnBG;

/// Storage points for resizing between fullscreen and non-fullscreen
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

// Content player handles.
@property(nonatomic, strong) AVPlayer *contentPlayer;
@property(nonatomic, strong) AVPlayerLayer *contentPlayerLayer;
@property(nonatomic, strong) id<NSObject> playHeadObserver;

// IMA objects
@property(nonatomic, strong) IMAAVPlayerVideoDisplay *IMAVideoDisplay;
@property(nonatomic, strong) IMAStreamManager *streamManager;

// Maintains seeking status for snapback.
@property(nonatomic, assign) CMTime seekStartTime;
@property(nonatomic, assign) CMTime seekEndTime;
@property(nonatomic, assign) BOOL snapbackMode;
@property(nonatomic, assign) BOOL currentlySeeking;

/// Bool to maintain state of content trackers. These need to be removed when the view deallocates.
@property(nonatomic, assign) BOOL trackingContent;

@end

@implementation VideoViewController
// Set up the new view controller.
- (void)viewDidLoad {
  [super viewDidLoad];

  self.castManager.videoVC = self;

  self.topLabel.text = self.video.title;
  // Set the play button image.
  self.playBtnBG = [UIImage imageNamed:@"play.png"];
  // Set the pause button image.
  self.pauseBtnBG = [UIImage imageNamed:@"pause.png"];

  if (self.video.streamType == StreamTypeLive) {
    self.videoControls.hidden = YES;
  }

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

  self.adsLoader.delegate = self;
  [self setUpContentPlayer];

  // GoogleCast button.
  GCKUICastButton *castButton = [[GCKUICastButton alloc] initWithFrame:CGRectMake(0, 0, 24, 24)];
  castButton.tintColor = [UIColor blackColor];
  self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:castButton];

  if (self.castManager.isCasting) {
    self.castManager.playbackMode = PlaybackModeRemote;
    [self.castManager playStreamRemotely];
  } else {
    self.castManager.playbackMode = PlaybackModeLocal;
    [self requestStream];
  }
}

- (void)viewWillDisappear:(BOOL)animated {
  [super viewWillDisappear:animated];
  [self.contentPlayer pause];
  // Ignore this if we're presenting a modal view (e.g. in-app clickthrough).
  if ([self.navigationController.viewControllers indexOfObject:self] == NSNotFound) {
    // Don't save bookmark if we're playing remotely via cast or playing a live stream.
    if (self.castManager.playbackMode == PlaybackModeLocal ||
        self.video.streamType == StreamTypeLive) {
      NSTimeInterval contentTime = [self.streamManager
          contentTimeForStreamTime:CMTimeGetSeconds(self.contentPlayer.currentTime)];
      [self.delegate videoViewController:self didReportSavedTime:contentTime forVideo:self.video];
    }
    // Only remove AVPlayer tracking if we added it already.
    if (self.trackingContent) {
      [self removeContentPlayerObservers];
    }

    self.castManager.videoVC = nil;

    [self.streamManager destroy];
    [self.adsLoader contentComplete];
  }
}

- (void)setUpContentPlayer {
  self.contentPlayer = [[AVPlayer alloc] init];

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
}

- (void)addContentPlayerObservers {
  self.trackingContent = YES;
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
}

- (void)removeContentPlayerObservers {
  self.trackingContent = NO;
  [self.contentPlayer removeTimeObserver:self.playHeadObserver];
  [self.contentPlayer removeObserver:self forKeyPath:@"rate"];
  [self.contentPlayer removeObserver:self forKeyPath:@"currentItem.duration"];
}

// Handler for keypath listener that is added for content playhead observer.
- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context {
  if (context == @"contentPlayerRate" && self.contentPlayer == object) {
    self.streamPlaying = self.contentPlayer.rate != 0;
    [self updatePlayHeadState:self.streamPlaying];
  } else if (context == @"playerDuration" && self.contentPlayer == object) {
    [self
        updatePlayHeadDurationWithTime:[self getPlayerItemDuration:self.contentPlayer.currentItem]];
  }
}

#pragma mark UI handlers

// Handle clicks on play/pause button.
- (IBAction)onPlayPauseClicked:(id)sender {
  if (self.castManager.playbackMode == PlaybackModeRemote) {
    [self.castManager playOrPauseVideo];
  } else {
    if (self.streamPlaying) {
      [self.contentPlayer pause];
    } else {
      [self.contentPlayer play];
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

- (IBAction)playHeadValueChanged:(id)sender {
  if (![sender isKindOfClass:[UISlider class]]) {
    return;
  }
  if (self.castManager.playbackMode == PlaybackModeLocal && !self.adPlaying) {
    UISlider *slider = (UISlider *)sender;
    // If the playhead value changed by the user, skip to that point of the
    // content is skippable.
    [self.contentPlayer seekToTime:CMTimeMake(slider.value, 1)];
  }
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
  if (!self.currentlySeeking) {
    // Don't move the progress bar back to current time while we're seeking, it's confusing
    self.progressBar.value = currentTime;
  }
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
  if (self.castManager.playbackMode != PlaybackModeLocal) {
    return;
  }
  switch (interfaceOrientation) {
    case UIInterfaceOrientationLandscapeLeft:
    // Falls through.
    case UIInterfaceOrientationLandscapeRight:
      [self viewDidEnterPortrait];
      break;
    case UIInterfaceOrientationPortrait:
    // Falls through.
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
  self.videoControls.hidden = NO;
  self.videoControls.alpha = 1;
}

- (IBAction)videoControlsTouchStarted:(id)sender {
  if (self.castManager.playbackMode == PlaybackModeLocal) {
    [NSObject cancelPreviousPerformRequestsWithTarget:self
                                             selector:@selector(hideFullscreenControls)
                                               object:self];

    self.currentlySeeking = YES;
    self.seekStartTime = self.contentPlayer.currentTime;
  }
}

- (IBAction)videoControlsTouchEnded:(id)sender {
  if (self.castManager.playbackMode == PlaybackModeLocal) {
    if (self.fullscreen) {
      [self startHideControlsTimer];
    }
    self.currentlySeeking = NO;
    if (!self.adPlaying) {
      self.seekEndTime = CMTimeMake(self.progressBar.value, 1);
      IMACuepoint *lastCuepoint =
          [self.streamManager previousCuepointForStreamTime:CMTimeGetSeconds(self.seekEndTime)];
      if (!lastCuepoint.played && (lastCuepoint.startTime > CMTimeGetSeconds(self.seekStartTime))) {
        self.snapbackMode = YES;
        // Add 1 to the seek time to get the keyframe at the start of the ad to be our landing
        // place.
        [self.contentPlayer
            seekToTime:CMTimeMakeWithSeconds(lastCuepoint.startTime + 1, NSEC_PER_SEC)];
      }
    }
  } else if (self.castManager.playbackMode == PlaybackModeRemote) {
    [self.castManager seekToTimeInterval:self.progressBar.value];
  }
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
  if (self.fullscreen) {
    [UIView animateWithDuration:0.5
                     animations:^{
                       self.videoControls.alpha = 0.0;
                     }];
  }
}

- (void)showSubtitles {
  AVAsset *asset = self.contentPlayer.currentItem.asset;
  AVMediaSelectionGroup *legibleGroup =
      [asset mediaSelectionGroupForMediaCharacteristic:AVMediaCharacteristicLegible];
  NSArray *characteristics =
      [NSArray arrayWithObject:AVMediaCharacteristicContainsOnlyForcedSubtitles];
  NSArray *filteredOptions =
      [AVMediaSelectionGroup mediaSelectionOptionsFromArray:legibleGroup.options
                                withoutMediaCharacteristics:characteristics];
  if (filteredOptions && filteredOptions.count) {
    // Select the first subtitle track.
    [self.contentPlayer.currentItem selectMediaOption:[filteredOptions objectAtIndex:0]
                                inMediaSelectionGroup:legibleGroup];
  }
}

#pragma mark IMA methods

- (void)requestStream {
  self.localStreamRequested = YES;
  // Create an ad display container for ad rendering.
  IMAAdDisplayContainer *adDisplayContainer =
      [[IMAAdDisplayContainer alloc] initWithAdContainer:self.videoView companionSlots:nil];
  // Create an IMAAVPlayerVideoDisplay to give the SDK access to your video player.
  self.IMAVideoDisplay = [[IMAAVPlayerVideoDisplay alloc] initWithAVPlayer:self.contentPlayer];
  // Create a stream request.
  IMAStreamRequest *request;
  if (self.video.streamType == StreamTypeLive) {
    request = [[IMALiveStreamRequest alloc] initWithAssetKey:self.video.assetKey
                                          adDisplayContainer:adDisplayContainer
                                                videoDisplay:self.IMAVideoDisplay];
    request.apiKey = self.video.apiKey;
  } else {
    request = [[IMAVODStreamRequest alloc] initWithContentSourceID:self.video.contentSourceID
                                                           videoID:self.video.videoId
                                                adDisplayContainer:adDisplayContainer
                                                      videoDisplay:self.IMAVideoDisplay];
    request.apiKey = self.video.apiKey;
  }
  [self.adsLoader requestStreamWithRequest:request];
}

#pragma mark AdsLoader Delegates

- (void)adsLoader:(IMAAdsLoader *)loader adsLoadedWithData:(IMAAdsLoadedData *)adsLoadedData {
  // adsLoadedData.streamManager is set because we made an IMAStreamRequest.
  NSLog(@"Stream created with: %@.", adsLoadedData.streamManager.streamId);
  self.streamManager = adsLoadedData.streamManager;
  self.streamManager.delegate = self;

  IMAAdsRenderingSettings *adsRenderingSettings = [[IMAAdsRenderingSettings alloc] init];
  adsRenderingSettings.uiElements =
      @[ @(kIMAUiElements_COUNTDOWN), @(kIMAUiElements_AD_ATTRIBUTION) ];

  [self.streamManager initializeWithAdsRenderingSettings:adsRenderingSettings];
}

- (void)adsLoader:(IMAAdsLoader *)loader failedWithErrorData:(IMAAdLoadingErrorData *)adErrorData {
  // Something went wrong loading ads. Log the error and play the content.
  NSLog(@"AdsLoader error, code:%ld, message: %@", adErrorData.adError.code,
        adErrorData.adError.message);
  // Load AVPlayer with path to our backup content and play it.
  NSURL *contentURL = [NSURL URLWithString:IMATestAppContentUrl_M3U8];
  self.contentPlayer = [AVPlayer playerWithURL:contentURL];
  [self addContentPlayerObservers];
  [self.contentPlayer play];
}

#pragma mark StreamManager Delegates

- (void)streamManager:(IMAStreamManager *)streamManager didReceiveAdEvent:(IMAAdEvent *)event {
  NSLog(@"StreamManager event (%@).", event.typeString);
  switch (event.type) {
    case kIMAAdEvent_STARTED: {
      // Log extended data.
      NSString *extendedAdPodInfo = [[NSString alloc]
          initWithFormat:@"Showing ad %d/%d, bumper: %@, title: %@, description: %@, contentType:"
                         @"%@, pod index: %d, time offset: %lf, max duration: %lf.",
                         event.ad.adPodInfo.adPosition, event.ad.adPodInfo.totalAds,
                         event.ad.adPodInfo.isBumper ? @"YES" : @"NO", event.ad.adTitle,
                         event.ad.adDescription, event.ad.contentType, event.ad.adPodInfo.podIndex,
                         event.ad.adPodInfo.timeOffset, event.ad.adPodInfo.maxDuration];

      [self logMessage:extendedAdPodInfo];
      [self updatePlayHeadState:YES];
      break;
    }
    case kIMAAdEvent_AD_BREAK_STARTED: {
      [self logMessage:@"Ad break started"];
      self.adPlaying = YES;
      break;
    }
    case kIMAAdEvent_AD_BREAK_ENDED: {
      [self logMessage:@"Ad break ended"];
      self.adPlaying = NO;
      if (self.snapbackMode) {
        self.snapbackMode = NO;
        if (CMTimeCompare(self.seekEndTime, self.contentPlayer.currentTime)) {
          [self.contentPlayer seekToTime:self.seekEndTime];
        }
      }
      break;
    }
    case kIMAAdEvent_AD_PERIOD_STARTED: {
      [self logMessage:@"Ad period started"];
      break;
    }
    case kIMAAdEvent_AD_PERIOD_ENDED: {
      [self logMessage:@"Ad period ended"];
      break;
    }
    case kIMAAdEvent_STREAM_LOADED: {
      if (self.video.streamType == StreamTypeVOD) {
        [self addContentPlayerObservers];
        if (self.video.savedTime > 0) {
          NSTimeInterval streamTime =
              [self.streamManager streamTimeForContentTime:self.video.savedTime];
          [self.IMAVideoDisplay.playerItem
              seekToTime:CMTimeMakeWithSeconds(streamTime, NSEC_PER_SEC)];
          self.video.savedTime = 0;
        }
      }
      self.streamPlaying = YES;
      [self showSubtitles];
      break;
    }
    case kIMAAdEvent_TAPPED: {
      [self showFullscreenControls:nil];
    }
    default:
      break;
  }
}

- (void)streamManager:(IMAStreamManager *)streamManager didReceiveAdError:(IMAAdError *)error {
  NSLog(@"StreamManager error with type: %ld\ncode: %ld\nmessage: %@", error.type, error.code,
        error.message);
  // Load AVPlayer with path to our backup content and play it.
  NSURL *contentURL = [NSURL URLWithString:IMATestAppContentUrl_M3U8];
  [self removeContentPlayerObservers];
  self.contentPlayer = [AVPlayer playerWithURL:contentURL];
  [self addContentPlayerObservers];
  [self.contentPlayer play];
}

- (void)streamManager:(IMAStreamManager *)streamManager
    adDidProgressToTime:(NSTimeInterval)time
             adDuration:(NSTimeInterval)adDuration
             adPosition:(NSInteger)adPosition
               totalAds:(NSInteger)totalAds
        adBreakDuration:(NSTimeInterval)adBreakDuration {
  // No-op here, but would used to update custom countdown timer.
}

- (NSTimeInterval)getContentTime {
  if (self.streamManager) {
    return [self.streamManager
        contentTimeForStreamTime:CMTimeGetSeconds(self.contentPlayer.currentTime)];
  } else {
    return 0;
  }
}

- (void)pauseContent {
  [self.contentPlayer pause];
}

- (void)switchToLocalPlayback {
  NSLog(@"switchToLocalPlayback");

  if (self.castManager.playbackMode == PlaybackModeLocal) {
    return;
  }

  if (self.video.streamType == StreamTypeLive) {
    if (self.localStreamRequested) {
      [self.contentPlayer seekToTime:CMTimeMakeWithSeconds(MAXFLOAT, NSEC_PER_SEC)];
      [self.contentPlayer play];
    } else {
      [self requestStream];
    }
  } else if (self.adPlaying) {
    NSTimeInterval timeToSeek =
        [self.streamManager streamTimeForContentTime:self.castManager.castContentTime];
    self.seekEndTime = CMTimeMakeWithSeconds(timeToSeek, NSEC_PER_SEC);
    self.snapbackMode = YES;
    [self.contentPlayer play];
  } else if (self.localStreamRequested) {
    NSTimeInterval timeToSeek =
        [self.streamManager streamTimeForContentTime:self.castManager.castContentTime];
    [self.contentPlayer seekToTime:CMTimeMakeWithSeconds(timeToSeek, NSEC_PER_SEC)];
    [self.contentPlayer play];
  } else {
    self.video.savedTime = self.castManager.castContentTime;
    [self requestStream];
  }

  self.castManager.playbackMode = PlaybackModeLocal;
}

#pragma mark Utility methods

- (void)logMessage:(NSString *)log, ... {
  va_list args;
  va_start(args, log);
  NSString *s =
      [[NSString alloc] initWithFormat:[NSString stringWithFormat:@"%@\n", log] arguments:args];
  self.consoleView.text = [self.consoleView.text stringByAppendingString:s];
  NSLog(@"%@", s);
  va_end(args);
  if (self.consoleView.text.length > 0) {
    NSRange bottom = NSMakeRange(self.consoleView.text.length - 1, 1);
    [self.consoleView scrollRangeToVisible:bottom];
  }
}

@end
