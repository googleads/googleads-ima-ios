#import "Video.h"

@implementation Video

- (instancetype)initWithTitle:(NSString *)title
                    thumbnail:(UIImage *)thumbnail
                        video:(NSString *)video
                          tag:(NSString *)tag
                     language:(NSString *)language {
  self = [super init];
  if (self) {
    _title = [title copy];
    _thumbnail = [thumbnail copy];
    _video = [video copy];
    _tag = [tag copy];
    _language = [language copy];
  }
  return self;
}

@end