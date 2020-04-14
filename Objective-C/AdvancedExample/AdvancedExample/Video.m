#import "Video.h"

@implementation Video

- (instancetype)initWithTitle:(NSString *)title
                    thumbnail:(UIImage *)thumbnail
                        video:(NSString *)video
                          tag:(NSString *)tag {
  self = [super init];
  if (self) {
    _title = [title copy];
    _thumbnail = [thumbnail copy];
    _video = [video copy];
    _tag = [tag copy];
  }
  return self;
}

@end
