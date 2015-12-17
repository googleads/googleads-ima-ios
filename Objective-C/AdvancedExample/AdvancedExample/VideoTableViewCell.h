#import <UIKit/UIKit.h>

#import "Video.h"

@interface VideoTableViewCell : UITableViewCell

@property(nonatomic, weak, readwrite) IBOutlet UIImageView *thumbnail;
@property(nonatomic, weak, readwrite) IBOutlet UILabel *videoLabel;

- (void)populateWithVideo:(Video *)Video;

@end
