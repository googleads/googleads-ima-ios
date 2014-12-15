#import <AVFoundation/AVFoundation.h>
#import <UIKit/UIKit.h>

#import "IMAAdsLoader.h"
#import "IMAAVPlayerContentPlayhead.h"
#import "IMACompanionAdSlot.h"
#import "Video.h"

@interface VideoViewController
    : UIViewController<IMAAdsLoaderDelegate, IMAAdsManagerDelegate, UIAlertViewDelegate>

@property(nonatomic, strong) Video *video;

// UI Outlets
@property(nonatomic, weak) IBOutlet UILabel *topLabel;
@property(nonatomic, weak) IBOutlet UIView *videoView;
@property(nonatomic, weak) IBOutlet UIToolbar *videoControls;
@property(nonatomic, weak) IBOutlet UIButton *playHeadButton;
@property(nonatomic, weak) IBOutlet UITextField *playHeadTimeText;
@property(nonatomic, weak) IBOutlet UITextField *durationTimeText;
@property(nonatomic, weak) IBOutlet UISlider *progressBar;
@property(nonatomic, weak) IBOutlet UIView *companionView;
@property(nonatomic, weak) IBOutlet UITextView *consoleView;

@end
