#import "VideoTableViewCell.h"

@implementation VideoTableViewCell

- (void)populateWithVideo:(Video *)video {
  self.videoLabel.text = video.title;
  [self.thumbnail setImage:video.thumbnail];
}

@end
