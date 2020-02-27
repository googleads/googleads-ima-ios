#import "Video.h"

@implementation Video

- (instancetype)initWithTitle:(NSString *)title
                     assetKey:(NSString *)assetKey
                       apiKey:(NSString *)apiKey {
  self = [super init];
  if (self) {
    _title = [title copy];
    _streamType = StreamTypeLive;
    _assetKey = [assetKey copy];
    _apiKey = [apiKey copy];
  }
  return self;
}

- (instancetype)initWithTitle:(NSString *)title
              contentSourceId:(NSString *)contentSourceId
                      videoId:(NSString *)videoId
                       apiKey:(NSString *)apiKey {
  self = [super init];
  if (self) {
    _title = [title copy];
    _streamType = StreamTypeVOD;
    _contentSourceID = [contentSourceId copy];
    _videoId = [videoId copy];
    _apiKey = [apiKey copy];
  }
  return self;
}

@end
