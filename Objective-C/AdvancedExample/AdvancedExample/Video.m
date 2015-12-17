#import "Video.h"

@implementation Video

- (instancetype)initWithTitle:(NSString *)title
                    thumbnail:(UIImage *)thumbnail
                        video:(NSString *)video
                          tag:(NSString *)tag {
  self = [super init];
  if (self) {
    self.title = [title copy];
    self.thumbnail = [thumbnail copy];
    self.video = [video copy];
    self.tag = [tag copy];
  }
  return self;
}

@end