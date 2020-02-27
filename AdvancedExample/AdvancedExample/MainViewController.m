#import "MainViewController.h"

@import GoogleCast;

#import "CastManager.h"
#import "Video.h"
#import "VideoViewController.h"

@interface MainViewController () <UIAlertViewDelegate, VideoViewControllerDelegate>

/// Storage point for videos.
@property(nonatomic, copy) NSArray<Video *> *videos;

/// Manages cast relationship.
@property(nonatomic, strong) CastManager *castManager;

// AdsLoader
@property(nonatomic, strong) IMAAdsLoader *adsLoader;

@end

@implementation MainViewController

// Set up the app.
- (void)viewDidLoad {
  [super viewDidLoad];
  [self initVideos];

  // Cast manager.
  self.castManager = [[CastManager alloc] init];

  // GoogleCast button
  GCKUICastButton *castButton = [[GCKUICastButton alloc] initWithFrame:CGRectMake(0, 0, 24, 24)];
  castButton.tintColor = [UIColor blackColor];
  self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:castButton];

  // AdsLoader
  // Re-use this IMAAdsLoader instance for the entire lifecycle of your app.
  self.adsLoader = [[IMAAdsLoader alloc] initWithSettings:nil];
}

// Populate the video array.
- (void)initVideos {
  self.videos = @[
    [[Video alloc] initWithTitle:@"Live stream" assetKey:@"sN_IYUG8STe1ZzhIIE_ksA" apiKey:@""],
    [[Video alloc] initWithTitle:@"VOD stream"
                 contentSourceId:@"19463"
                         videoId:@"googleio-highlights"
                          apiKey:@""],
    [[Video alloc] initWithTitle:@"VOD Stream w/ Subtitles"
                 contentSourceId:@"19463"
                         videoId:@"tears-of-steel"
                          apiKey:@""]
  ];
}

// When an item is selected, set the video item on the VideoViewController.
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
  if ([[segue identifier] isEqualToString:@"showVideo"]) {
    NSIndexPath *indexPath = [self.tableView indexPathForSelectedRow];
    Video *video = self.videos[indexPath.row];
    VideoViewController *destVC = (VideoViewController *)segue.destinationViewController;
    destVC.delegate = self;
    destVC.video = video;
    destVC.castManager = self.castManager;
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
  UITableViewCell *cell =
      [tableView dequeueReusableCellWithIdentifier:@"Cell" forIndexPath:indexPath];
  Video *selectedVideo = self.videos[indexPath.row];
  cell.textLabel.text = selectedVideo.title;
  return cell;
}

// Standard override.
- (void)didReceiveMemoryWarning {
  [super didReceiveMemoryWarning];
  // Dispose of any resources that can be recreated.
}

#pragma mark VideoViewControllerDelegate

- (void)videoViewController:(VideoViewController *)viewController
         didReportSavedTime:(NSTimeInterval)savedTime
                   forVideo:(Video *)video {
  video.savedTime = savedTime;
}

@end
