@import AVFoundation;
@import UIKit;

/// The player state.
typedef NS_ENUM(NSInteger, StreamType) {
  StreamTypeLive,  ///< Live stream.
  StreamTypeVOD    ///< VOD Stream.
};

@interface Video : NSObject

/// The title of the video.
@property(nonatomic, copy) NSString *title;

/// Stream type
@property(nonatomic, assign) StreamType streamType;

/// The asset key for the video. Used only for live streams.
@property(nonatomic, copy) NSString *assetKey;

/// The CMS ID for the stream. Used only for VOD.
@property(nonatomic, copy) NSString *contentSourceID;

/// The video ID for the stream. Used only for VOD.
@property(nonatomic, copy) NSString *videoId;

/// The asset key for the stream. Used only for encrypted streams.
@property(nonatomic, copy) NSString *apiKey;

/// Stores the user's progress through a video to resume it upon return.
@property(nonatomic) NSTimeInterval savedTime;

/// Returns an initialized live stream video.
- (instancetype)initWithTitle:(NSString *)title
                     assetKey:(NSString *)assetKey
                       apiKey:(NSString *)apiKey;

/// Returns an initialized VOD video.
- (instancetype)initWithTitle:(NSString *)title
              contentSourceId:(NSString *)contentSourceId
                      videoId:(NSString *)videoId
                       apiKey:(NSString *)apiKey;

@end
