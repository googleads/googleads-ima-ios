@import AVFoundation;

@class VideoViewController;

/// The player state.
typedef NS_ENUM(NSInteger, PlaybackMode) {
  PlaybackModeNone,   ///< Default before playback has been initialized.
  PlaybackModeLocal,  ///< Playback is happening on the device's AVPlayer.
  PlaybackModeRemote  ///< Playback is happening on a cast device.
};

@interface CastManager : NSObject

/// Tracks whether or not we are currently connected to a cast device.
@property(nonatomic, readonly, getter=isCasting) BOOL casting;

/// Content time to which we've progressed on a cast device (time in stream if the stream had no
/// ads.)
@property(nonatomic, assign) NSTimeInterval castContentTime;

/// Stream time to which we've progressed on a cast device.
@property(nonatomic, assign) NSTimeInterval castStreamTime;

@property(nonatomic, strong) VideoViewController *videoVC;

/// Tracks current playback mode - either locally or on a cast device.
@property(nonatomic, assign) PlaybackMode playbackMode;

/// Handles clicks on the play/pause button in the video UI.
- (void)playOrPauseVideo;

/// Plays a stream on the connected cast device.
- (void)playStreamRemotely;

/// Seeks to the provided time interval on the connected cast device.
- (void)seekToTimeInterval:(NSTimeInterval)seekTime;

@end
