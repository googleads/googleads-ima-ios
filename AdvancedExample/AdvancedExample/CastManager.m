#import "CastManager.h"

@import GoogleCast;

#import "VideoViewController.h"

/// Namespace for the cast communication channel.
static NSString *const IMACastNamespace = @"urn:x-cast:com.google.ads.interactivemedia.dai.cast";

/// Command to get the content time from the IMA cast receiver.
static NSString *const IMAGetContentTime = @"getContentTime,";

/// Prefix for the receiver's response to getContentTime.
static NSString *const IMAContentTime = @"contentTime,";

@interface CastManager () <GCKGenericChannelDelegate, GCKRemoteMediaClientListener,
                           GCKSessionManagerListener>

/// Tracks whether or not we are currently connected to a cast device.
@property(nonatomic, assign, readwrite) BOOL casting;

/// Tracks play/pause state of remote stream.
@property(nonatomic, assign) BOOL castStreamPlaying;

/// Manages a cast session
@property(nonatomic, strong) GCKSessionManager *sessionManager;

/// Cast session.
@property(nonatomic, strong) GCKCastSession *castSession;

/// Duration of the stream playing on a cast device.
@property(nonatomic, assign) NSTimeInterval castMediaDuration;

/// Timer used to poll the receiver for progress info.
@property(nonatomic, strong) NSTimer *receiverPollingTimer;

/// Channel used to communicate with the cast device.
@property(nonatomic, strong) GCKGenericChannel *castChannel;

@end

@implementation CastManager

- (instancetype)init {
  self = [super init];
  if (self) {
    [[GCKCastContext sharedInstance].sessionManager addListener:self];
    _castChannel = [[GCKGenericChannel alloc] initWithNamespace:IMACastNamespace];
    _castChannel.delegate = self;
  }
  return self;
}

#pragma mark - GCKSessionManagerListener

- (void)sessionManager:(GCKSessionManager *)sessionManager didStartSession:(GCKSession *)session {
  NSLog(@"MediaViewController: sessionManager didStartSession %@", session);
  self.casting = YES;
  self.castSession = [GCKCastContext sharedInstance].sessionManager.currentCastSession;
  [self.castSession addChannel:self.castChannel];
  if (self.videoVC) {
    [self switchToRemotePlayback];
  }
}

- (void)sessionManager:(GCKSessionManager *)sessionManager didResumeSession:(GCKSession *)session {
  NSLog(@"MediaViewController: sessionManager didResumeSession %@", session);
  self.casting = YES;
  self.castSession = [GCKCastContext sharedInstance].sessionManager.currentCastSession;
  [self.castSession addChannel:self.castChannel];
  if (self.videoVC) {
    [self switchToRemotePlayback];
  }
}

- (void)sessionManager:(GCKSessionManager *)sessionManager
         didEndSession:(GCKSession *)session
             withError:(NSError *)error {
  NSLog(@"Session ended with error: %@", error.localizedDescription);
  self.casting = NO;

  if (self.receiverPollingTimer) {
    [self.receiverPollingTimer invalidate];
    self.receiverPollingTimer = nil;
  }

  if (self.videoVC) {
    [self.videoVC switchToLocalPlayback];
  }
}

- (void)sessionManager:(GCKSessionManager *)sessionManager
    didFailToStartSessionWithError:(NSError *)error {
  NSLog(@"Failed to start a session: %@", error.localizedDescription);
}

#pragma mark - GCKRemoteMediaClientListener

- (void)remoteMediaClient:(GCKRemoteMediaClient *)client
     didUpdateMediaStatus:(GCKMediaStatus *)mediaStatus {
  if (mediaStatus.playerState == GCKMediaPlayerStatePlaying) {
    [self.videoVC updatePlayHeadState:YES];
    if (self.videoVC.video.streamType == StreamTypeVOD) {
      self.castMediaDuration = mediaStatus.mediaInformation.streamDuration;
      [self.videoVC updatePlayHeadDurationWithTime:CMTimeMakeWithSeconds(self.castMediaDuration,
                                                                         NSEC_PER_SEC)];
    }
    self.castStreamPlaying = YES;
  } else {
    [self.videoVC updatePlayHeadState:NO];
    self.castStreamPlaying = NO;
  }
}

#pragma mark - Cast utility

- (void)playStreamRemotely {
  if (self.videoVC.video.streamType == StreamTypeVOD) {
    self.receiverPollingTimer = [NSTimer scheduledTimerWithTimeInterval:1.0
                                                                 target:self
                                                               selector:@selector(pollReceiver)
                                                               userInfo:nil
                                                                repeats:YES];
  }

  if (self.castSession) {
    [self.castSession.remoteMediaClient addListener:self];
    [self.castSession.remoteMediaClient loadMedia:[self buildMediaInformation] autoplay:YES];
  }
}

- (GCKMediaInformation *)buildMediaInformation {
  GCKMediaMetadata *metadata =
      [[GCKMediaMetadata alloc] initWithMetadataType:GCKMediaMetadataTypeMovie];

  NSTimeInterval startTime = 0;
  if (self.videoVC.localStreamRequested && self.videoVC.video.streamType == StreamTypeVOD) {
    startTime = [self.videoVC getContentTime];
  }

  NSMutableDictionary *customData = [NSMutableDictionary dictionary];
  customData[@"startTime"] = [NSNumber numberWithDouble:startTime];
  customData[@"apiKey"] = self.videoVC.video.apiKey;

  if (self.videoVC.video.streamType == StreamTypeLive) {
    customData[@"assetKey"] = self.videoVC.video.assetKey;
  } else {
    customData[@"contentSourceId"] = self.videoVC.video.contentSourceID;
    customData[@"videoId"] = self.videoVC.video.videoId;
  }

  GCKMediaInformation *mediaInfo =
      [[GCKMediaInformation alloc] initWithContentID:self.videoVC.video.title
                                          streamType:GCKMediaStreamTypeBuffered
                                         contentType:@"application/x-mpegurl"
                                            metadata:metadata
                                      streamDuration:0
                                         mediaTracks:nil
                                      textTrackStyle:nil
                                          customData:customData];
  return mediaInfo;
}

- (void)switchToRemotePlayback {
  NSLog(@"switchToRemotePlayback");

  if (self.playbackMode == PlaybackModeRemote) {
    return;
  }

  [self.videoVC pauseContent];
  [self playStreamRemotely];

  self.playbackMode = PlaybackModeRemote;
}

- (void)pollReceiver {
  self.castStreamTime = [self.castSession.remoteMediaClient approximateStreamPosition];
  [self.videoVC updatePlayHeadWithTime:CMTimeMakeWithSeconds(self.castStreamTime, NSEC_PER_SEC)
                              duration:CMTimeMakeWithSeconds(self.castMediaDuration, NSEC_PER_SEC)];
  [self.castChannel sendTextMessage:IMAGetContentTime];
}

- (void)playOrPauseVideo {
  if (self.castStreamPlaying) {
    [self.castSession.remoteMediaClient pause];
  } else {
    [self.castSession.remoteMediaClient play];
  }
}

- (void)seekToTimeInterval:(NSTimeInterval)seekTime {
  [self.castSession.remoteMediaClient seekToTimeInterval:seekTime];
}

#pragma mark - GCKGenericChannelDelegate

- (void)castChannel:(GCKGenericChannel *)channel
    didReceiveTextMessage:(NSString *)message
            withNamespace:(NSString *)protocolNamespace {
  if ([message hasPrefix:IMAContentTime]) {
    NSString *timeString = [message substringFromIndex:IMAContentTime.length];
    self.castContentTime = timeString.doubleValue;
  }
}

@end
