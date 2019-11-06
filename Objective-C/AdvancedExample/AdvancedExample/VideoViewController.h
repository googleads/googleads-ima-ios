@import UIKit;

@import GoogleInteractiveMediaAds;

#import "Video.h"

@interface VideoViewController : UIViewController

// UI Outlets
@property(nonatomic, weak) IBOutlet UILabel *topLabel;
@property(nonatomic, weak) IBOutlet UIView *videoView;
@property(nonatomic, weak) IBOutlet UIToolbar *videoControls;
@property(nonatomic, weak) IBOutlet UIButton *playHeadButton;
@property(nonatomic, weak) IBOutlet UITextField *playHeadTimeText;
@property(nonatomic, weak) IBOutlet UITextField *durationTimeText;
@property(nonatomic, weak) IBOutlet UISlider *progressBar;
@property(nonatomic, weak) IBOutlet UIButton *pictureInPictureButton;

// MOE:strip_line [START companion_view_header]
@property(nonatomic, weak) IBOutlet UIView *companionView;
// [END companion_view_header] MOE:strip_line

@property(nonatomic, weak) IBOutlet UITextView *consoleView;

@property(nonatomic, strong) Video *video;

@property(nonatomic, strong) IMAAdsLoader *adsLoader;

@end
