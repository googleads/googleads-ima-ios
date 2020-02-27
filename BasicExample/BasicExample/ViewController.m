#import "ViewController.h"

@import AVFoundation;
@import GoogleInteractiveMediaAds;

/// Fallback URL in case something goes wrong in loading the stream. If all goes well, this will not
/// be used.
static NSString *const kTestAppContentUrl_M3U8 =
    @"http://devimages.apple.com/iphone/samples/bipbop/bipbopall.m3u8";

/// Live stream asset key.
static NSString *const kAssetKey = @"sN_IYUG8STe1ZzhIIE_ksA";
/// VOD content source ID.
static NSString *const kContentSourceID = @"19463";
/// VOD video ID.
static NSString *const kVideoID = @"googleio-highlights";

@interface ViewController () <IMAAdsLoaderDelegate, IMAStreamManagerDelegate>

/// Content video player.
@property(nonatomic, strong) AVPlayer *contentPlayer;

// UI
/// Play button.
@property(nonatomic, weak) IBOutlet UIButton *playButton;
/// UIView in which we will render our AVPlayer for content.
@property(nonatomic, weak) IBOutlet UIView *videoView;

// SDK
/// Entry point for the SDK. Used to make ad requests.
@property(nonatomic, strong) IMAAdsLoader *adsLoader;
/// Main point of interaction with the SDK. Created by the SDK as the result of an ad request.
@property(nonatomic, strong) IMAStreamManager *streamManager;

@end

@implementation ViewController

- (void)viewDidLoad {
  [super viewDidLoad];

  self.playButton.layer.zPosition = MAXFLOAT;

  [self setupAdsLoader];
  [self setUpContentPlayer];
}

- (IBAction)onPlayButtonTouch:(id)sender {
  [self requestStream];
  self.playButton.hidden = YES;
}

#pragma mark Content Player Setup

- (void)setUpContentPlayer {
  // Load AVPlayer with path to our content.
  NSURL *contentURL = [NSURL URLWithString:kTestAppContentUrl_M3U8];
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

- (void)requestStream {
  // Create an ad display container for ad rendering.
  IMAAdDisplayContainer *adDisplayContainer =
      [[IMAAdDisplayContainer alloc] initWithAdContainer:self.videoView companionSlots:nil];
  // Create an IMAAVPlayerVideoDisplay to give the SDK access to your video player.
  IMAAVPlayerVideoDisplay *imaVideoDisplay =
      [[IMAAVPlayerVideoDisplay alloc] initWithAVPlayer:self.contentPlayer];
  // Create a stream request. Use one of "Live stream request" or "VOD request".
  // Live stream request.
  IMALiveStreamRequest *request = [[IMALiveStreamRequest alloc] initWithAssetKey:kAssetKey
                                                              adDisplayContainer:adDisplayContainer
                                                                    videoDisplay:imaVideoDisplay];
  // VOD request. Comment out the IMALiveStreamRequest above and uncomment this IMAVODStreamRequest
  // to switch from a livestream to a VOD stream.
  /*IMAVODStreamRequest *request =
      [[IMAVODStreamRequest alloc] initWithContentSourceId:kContentSourceID
                                                videoId:kVideoID
                                     adDisplayContainer:adDisplayContainer
                                           videoDisplay:imaVideoDisplay];*/
  [self.adsLoader requestStreamWithRequest:request];
}

#pragma mark AdsLoader Delegates

- (void)adsLoader:(IMAAdsLoader *)loader adsLoadedWithData:(IMAAdsLoadedData *)adsLoadedData {
  NSLog(@"Stream created with: %@.", adsLoadedData.streamManager.streamId);
  // adsLoadedData.streamManager is set because we made an IMAStreamRequest.
  self.streamManager = adsLoadedData.streamManager;
  self.streamManager.delegate = self;
  [self.streamManager initializeWithAdsRenderingSettings:nil];
}

- (void)adsLoader:(IMAAdsLoader *)loader failedWithErrorData:(IMAAdLoadingErrorData *)adErrorData {
  // Something went wrong loading ads. Log the error and play the content.
  NSLog(@"AdsLoader error, code:%ld, message: %@", adErrorData.adError.code,
        adErrorData.adError.message);
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

      NSLog(@"%@", extendedAdPodInfo);
      break;
    }
    case kIMAAdEvent_AD_BREAK_STARTED: {
      NSLog(@"Ad break started");
      break;
    }
    case kIMAAdEvent_AD_BREAK_ENDED: {
      NSLog(@"Ad break ended");
      break;
    }
    case kIMAAdEvent_AD_PERIOD_STARTED: {
      NSLog(@"Ad period started");
      break;
    }
    case kIMAAdEvent_AD_PERIOD_ENDED: {
      NSLog(@"Ad period ended");
      break;
    }
    default:
      break;
  }
}

- (void)streamManager:(IMAStreamManager *)streamManager didReceiveAdError:(IMAAdError *)error {
  NSLog(@"StreamManager error with type: %ld\ncode: %ld\nmessage: %@", error.type, error.code,
        error.message);
  [self.contentPlayer play];
}

@end
