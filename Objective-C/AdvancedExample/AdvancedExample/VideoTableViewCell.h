@import UIKit;

#import "Video.h"

@interface VideoTableViewCell : UITableViewCell

@property(nonatomic, weak) IBOutlet UIImageView *thumbnail;
@property(nonatomic, weak) IBOutlet UILabel *videoLabel;

- (void)populateWithVideo:(Video *)Video;

@end
