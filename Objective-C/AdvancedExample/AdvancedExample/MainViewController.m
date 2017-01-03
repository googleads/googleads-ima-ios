#import "MainViewController.h"

#import "Constants.h"
#import "Video.h"
#import "VideoViewController.h"
#import "VideoTableViewCell.h"

@interface MainViewController () <UIAlertViewDelegate>

/// Storage point for videos.
@property(nonatomic, copy) NSArray<Video *> *videos;

/// AdsLoader for IMA SDK.
@property(nonatomic, strong) IMAAdsLoader *adsLoader;

/// Language for ad UI.
@property(nonatomic, strong) NSString *language;

@end

@implementation MainViewController

// Set up the app.
- (void)viewDidLoad {
  [super viewDidLoad];
  self.language = @"en";
  [self initVideos];
  [self setUpAdsLoader];

  // For Picture-in-Picture.
  [[AVAudioSession sharedInstance] setActive:YES error:nil];
  [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback error:nil];
}

// Populate the video array.
- (void)initVideos {
  UIImage *dfpThumbnail = [UIImage imageNamed:@"dfp.png"];
  UIImage *androidThumbnail = [UIImage imageNamed:@"android.png"];
  UIImage *bunnyThumbnail = [UIImage imageNamed:@"bunny.png"];
  UIImage *bipThumbnail = [UIImage imageNamed:@"bip.png"];
  self.videos = @[
    [[Video alloc] initWithTitle:@"Pre-roll"
                       thumbnail:dfpThumbnail
                           video:kDFPContentPath
                             tag:kPrerollTag],
    [[Video alloc] initWithTitle:@"Skippable Pre-roll"
                       thumbnail:androidThumbnail
                           video:kAndroidContentPath
                             tag:kSkippableTag],
    [[Video alloc] initWithTitle:@"Post-roll"
                       thumbnail:bunnyThumbnail
                           video:kBigBuckBunnyContentPath
                             tag:kPostrollTag],
    [[Video alloc] initWithTitle:@"AdRules"
                       thumbnail:bipThumbnail
                           video:kBipBopContentPath
                             tag:kAdRulesTag],
    [[Video alloc] initWithTitle:@"AdRules Pods"
                       thumbnail:dfpThumbnail
                           video:kDFPContentPath
                             tag:kAdRulesPodsTag],
    [[Video alloc] initWithTitle:@"VMAP Pods"
                       thumbnail:androidThumbnail
                           video:kAndroidContentPath
                             tag:kVMAPPodsTag],
    [[Video alloc] initWithTitle:@"Wrapper"
                       thumbnail:bunnyThumbnail
                           video:kBigBuckBunnyContentPath
                             tag:kWrapperTag],
    [[Video alloc] initWithTitle:@"AdSense"
                       thumbnail:bipThumbnail
                           video:kBipBopContentPath
                             tag:kAdSenseTag],
    [[Video alloc] initWithTitle:@"Custom"
                       thumbnail:androidThumbnail
                           video:kAndroidContentPath
                             tag:@"custom"]
  ];
}

// Initialize AdsLoader.
- (void)setUpAdsLoader {
  if (self.adsLoader) {
    self.adsLoader = nil;
  }
  IMASettings *settings = [[IMASettings alloc] init];
  settings.language = self.language;
  settings.enableBackgroundPlayback = YES;
  self.adsLoader = [[IMAAdsLoader alloc] initWithSettings:settings];
}

// Show pop-up dialog for language input.
- (IBAction)onLanguageClicked {
  NSString *alertMessage = @"NOTE: This will only change the ad UI language. The language elsewhere"
      @" in the app will remain in English. Language must be formated as a canonicalized IETF BCP"
      @" 47 language identifier such as would be returned by [NSLocale preferredLanguages], e.g."
      @" \"en\", \"es\", etc.";
  UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Language"
                                                  message:alertMessage
                                                 delegate:self
                                        cancelButtonTitle:@"OK"
                                        otherButtonTitles:nil];
  alert.alertViewStyle = UIAlertViewStylePlainTextInput;
  [alert show];
}

// If the language dialog was shown, re-create the AdsLoader with the new language.
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
  self.language = [[alertView textFieldAtIndex:0] text];
  [self setUpAdsLoader];
}

// When an item is selected, set the video item on the VideoViewController.
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
  if ([[segue identifier] isEqualToString:@"showVideo"]) {
    NSIndexPath *indexPath = [self.tableView indexPathForSelectedRow];
    Video *video = self.videos[indexPath.row];
    VideoViewController *destVC = (VideoViewController *)[segue destinationViewController];
    destVC.video = video;
    destVC.adsLoader = self.adsLoader;
  }
}

// Only allow one selection.
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
  return 1;
}

// Returns number of items to be presented in the table.
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
  return self.videos.count;
}

// Sets the display info for each table row.
- (UITableViewCell *)tableView:(UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath {
  VideoTableViewCell *cell =
      [tableView dequeueReusableCellWithIdentifier:@"cell" forIndexPath:indexPath];
  Video *selectedVideo = self.videos[indexPath.row];
  [cell populateWithVideo:selectedVideo];
  return cell;
}

// Standard override.
- (void)didReceiveMemoryWarning {
  [super didReceiveMemoryWarning];
  // Dispose of any resources that can be recreated.
}

@end
