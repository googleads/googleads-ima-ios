#import <UIKit/UIKit.h>

@interface ViewController : UIViewController

// Play button.
@property(nonatomic, weak) IBOutlet UIButton *playButton;
/// UIView in which we will render our AVPlayer for content.
@property(nonatomic, weak) IBOutlet UIView *videoView;

@end

