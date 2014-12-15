#import <UIKit/UIKit.h>

#import "Constants.h"
#import "MainViewController.h"
#import "Video.h"
#import "VideoViewController.h"
#import "VideoTableViewCell.h"

@interface MainViewController ()

// Storage point for videos.
@property(nonatomic, copy) NSArray *videos;

@end

@implementation MainViewController

// Set up the app.
- (void)viewDidLoad {
  [super viewDidLoad];
  [self initVideos];
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
                             tag:kPrerollTag
                        language:@"en"],
    [[Video alloc] initWithTitle:@"Skippable Pre-roll"
                       thumbnail:androidThumbnail
                           video:kAndroidContentPath
                             tag:kSkippableTag
                        language:@"en"],
    [[Video alloc] initWithTitle:@"Post-roll"
                       thumbnail:bunnyThumbnail
                           video:kBigBuckBunnyContentPath
                             tag:kPostrollTag
                        language:@"en"],
    [[Video alloc] initWithTitle:@"AdRules"
                       thumbnail:bipThumbnail
                           video:kBipBopContentPath
                             tag:kAdRulesTag
                        language:@"en"],
    [[Video alloc] initWithTitle:@"AdRules Pods"
                       thumbnail:dfpThumbnail
                           video:kDFPContentPath
                             tag:kAdRulesPodsTag
                        language:@"en"],
    [[Video alloc] initWithTitle:@"VMAP Pods"
                       thumbnail:androidThumbnail
                           video:kAndroidContentPath
                             tag:kVMAPPodsTag
                        language:@"en"],
    [[Video alloc] initWithTitle:@"Wrapper"
                       thumbnail:bunnyThumbnail
                           video:kBigBuckBunnyContentPath
                             tag:kWrapperTag
                        language:@"en"],
    [[Video alloc] initWithTitle:@"AdSense"
                       thumbnail:bipThumbnail
                           video:kBipBopContentPath
                             tag:kAdSenseTag
                        language:@"en"],
    [[Video alloc] initWithTitle:@"Spanish"
                       thumbnail:dfpThumbnail
                           video:kDFPContentPath
                             tag:kSkippableTag
                        language:@"es"],
    [[Video alloc] initWithTitle:@"Custom"
                       thumbnail:androidThumbnail
                           video:kAndroidContentPath
                             tag:@"custom"
                        language:@"en"]
  ];
}

// When an item is selected, set the video item on the VideoViewController.
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
  if ([[segue identifier] isEqualToString:@"showVideo"]) {
    NSIndexPath *indexPath = [self.tableView indexPathForSelectedRow];
    Video *video = self.videos[indexPath.row];
    VideoViewController *headedTo = (VideoViewController *)[segue destinationViewController];
    headedTo.video = video;
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
  cell.videoLabel.text = selectedVideo.title;
  [cell setImageForThumbnail:selectedVideo.thumbnail];
  return cell;
}

// Standard override.
- (void)didReceiveMemoryWarning {
  [super didReceiveMemoryWarning];
  // Dispose of any resources that can be recreated.
}

@end
