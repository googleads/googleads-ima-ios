#import "CastViewController.h"

@import GoogleCast;

#import "CastMessageChannel.h"
#import "ViewController.h"

@interface CastViewController () <GCKDeviceScannerListener, CastMessageChannelDelegate>

@property(nonatomic, strong) GCKMediaControlChannel *mediaControlChannel;
@property(nonatomic, strong) GCKApplicationMetadata *applicationMetadata;
@property(nonatomic, strong) GCKDevice *selectedDevice;
@property(nonatomic, strong) GCKDeviceScanner *deviceScanner;
@property(nonatomic, strong) GCKDeviceManager *deviceManager;
@property(nonatomic, strong) GCKMediaInformation *mediaInformation;
@property(nonatomic, strong) UIButton *castButton;
@property(nonatomic, strong) ViewController *viewController;
@property(nonatomic, strong) CastMessageChannel *messageChannel;
/// If cast player is currently playing an ad.
@property(nonatomic, assign) BOOL castAdPlaying;
/// Last known content time on cast player.
@property(nonatomic, assign) CMTime castContentTime;

@end

@implementation CastViewController

const NSString *kReceiverAppID = @"YOUR_RECEIVER_APP_ID";
const float kCastButtonXPosition = 0;
const float kCastButtonYPosition = 0;
const float kCastButtonWidth = 40;
const float kCastButtonHeight = 40;

- (instancetype)initWithViewController:(ViewController *)viewController {
  self = [super init];
  if (self) {
    self.viewController = viewController;
    self.castButton = [UIButton buttonWithType:UIButtonTypeSystem];
    self.castButton.frame =
        CGRectMake(kCastButtonXPosition, kCastButtonYPosition, kCastButtonWidth, kCastButtonHeight);
    self.view.autoresizingMask =
        UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleBottomMargin;
    [self.view addSubview:self.castButton];
    [self.castButton addTarget:self
                        action:@selector(chooseDevice:)
              forControlEvents:UIControlEventTouchUpInside];

    GCKFilterCriteria *filterCriteria =
        [GCKFilterCriteria criteriaForAvailableApplicationWithID:kReceiverAppID];
    self.deviceScanner = [[GCKDeviceScanner alloc] initWithFilterCriteria:filterCriteria];
    [self.deviceScanner addListener:self];
    [self.deviceScanner startScan];
    [self.castButton setImage:[UIImage imageNamed:@"cast_off.png"] forState:UIControlStateNormal];
    [self.deviceScanner setPassiveScan:YES];
    [self updateButtonStates];
  }
  return self;
}

- (IBAction)chooseDevice:(id)sender {
  if (self.selectedDevice == nil) {
    [self.deviceScanner setPassiveScan:NO];
    UIActionSheet *sheet =
        [[UIActionSheet alloc] initWithTitle:NSLocalizedString(@"Connect to device", nil)
                                    delegate:self
                           cancelButtonTitle:nil
                      destructiveButtonTitle:nil
                           otherButtonTitles:nil];

    for (GCKDevice *device in self.deviceScanner.devices) {
      [sheet addButtonWithTitle:device.friendlyName];
    }

    [sheet addButtonWithTitle:NSLocalizedString(@"Cancel", nil)];
    sheet.cancelButtonIndex = sheet.numberOfButtons - 1;

    [sheet showInView:self.view];
  } else {
    [self updateStatsFromDevice];

    NSString *mediaTitle = [self.mediaInformation.metadata stringForKey:kGCKMetadataKeyTitle];

    UIActionSheet *sheet = [[UIActionSheet alloc] init];
    sheet.title = self.selectedDevice.friendlyName;
    sheet.delegate = self;
    if (mediaTitle != nil) {
      [sheet addButtonWithTitle:mediaTitle];
    }

    [sheet addButtonWithTitle:@"Disconnect"];
    [sheet addButtonWithTitle:@"Cancel"];
    sheet.destructiveButtonIndex = (mediaTitle != nil ? 1 : 0);
    sheet.cancelButtonIndex = (mediaTitle != nil ? 2 : 1);

    [sheet showInView:self.view.superview];
  }
}

- (void)updateStatsFromDevice {
  if (self.mediaControlChannel &&
      self.deviceManager.connectionState == GCKConnectionStateConnected) {
    self.mediaInformation = self.mediaControlChannel.mediaStatus.mediaInformation;
  }
}

- (void)connectToDevice {
  if (self.selectedDevice == nil) {
    return;
  }

  self.deviceManager =
      [[GCKDeviceManager alloc] initWithDevice:self.selectedDevice
                             clientPackageName:[NSBundle mainBundle].bundleIdentifier];
  self.deviceManager.delegate = self;
  [self.deviceManager connect];
}

- (void)deviceDisconnected {
  self.mediaControlChannel = nil;
  self.deviceManager = nil;
  self.selectedDevice = nil;
}

- (void)updateButtonStates {
  if (self.deviceScanner && self.deviceScanner.devices.count > 0) {
    // Show the Cast button.
    self.castButton.hidden = NO;
    if (self.deviceManager && self.deviceManager.connectionState == GCKConnectionStateConnected) {
      // Show the Cast button in the enabled state.
      [self.castButton setTintColor:[UIColor blueColor]];
    } else {
      // Show the Cast button in the disabled state.
      [self.castButton setTintColor:[UIColor grayColor]];
    }
  } else {
    // Don't show the Cast button.
    self.castButton.hidden = YES;
  }
}

- (IBAction)castVideo:(id)sender {
  // Show alert if not connected.
  if (!self.deviceManager || self.deviceManager.connectionState != GCKConnectionStateConnected) {
    UIAlertController *alert =
        [UIAlertController alertControllerWithTitle:@"Not Connected"
                                            message:@"Please connect to Cast device"
                                     preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *action =
        [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil];
    [alert addAction:action];
    [self presentViewController:alert animated:YES completion:nil];
    return;
  }

  [self.viewController pauseVideo];
  NSString *contentUrl = self.viewController.kContentUrl;
  GCKMediaMetadata *metadata = [[GCKMediaMetadata alloc] init];
  GCKMediaInformation *mediaInformation =
      [[GCKMediaInformation alloc] initWithContentID:contentUrl
                                          streamType:GCKMediaStreamTypeBuffered
                                         contentType:@"video/mp4"
                                            metadata:metadata
                                      streamDuration:0
                                          customData:nil];
  [self.mediaControlChannel loadMedia:mediaInformation autoplay:NO playPosition:0];
  if (self.viewController.isVMAPAd || !self.viewController.adStartedPlaying) {
    [self sendMessage:[[NSString alloc]
                          initWithFormat:@"requestAd,%@,%f", self.viewController.kAdTagUrl,
                                         CMTimeGetSeconds(
                                             self.viewController.contentPlayer.currentTime)]];
  } else {
    [self sendMessage:[[NSString alloc]
                          initWithFormat:@"seek,%f",
                                         CMTimeGetSeconds(
                                             self.viewController.contentPlayer.currentTime)]];
  }
}

#pragma mark - GCKDeviceScannerListener
- (void)deviceDidComeOnline:(GCKDevice *)device {
  NSLog(@"device found!! %@", device.friendlyName);
  [self updateButtonStates];
}

- (void)deviceDidGoOffline:(GCKDevice *)device {
  [self updateButtonStates];
}

#pragma mark UIActionSheetDelegate
- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
  [self.deviceScanner setPassiveScan:YES];
  if (self.selectedDevice == nil) {
    if (buttonIndex < self.deviceScanner.devices.count) {
      self.selectedDevice = self.deviceScanner.devices[buttonIndex];
      NSLog(@"Selecting device:%@", self.selectedDevice.friendlyName);
      [self connectToDevice];
    }
  } else {
    NSString *title = [actionSheet buttonTitleAtIndex:buttonIndex];
    if ([title isEqualToString:@"Disconnect"]) {
      NSLog(@"Disconnecting device:%@", self.selectedDevice.friendlyName);
      [self.viewController playVideo];
      if (self.castAdPlaying) {
        // If ad is playing on cast, seek to last known content location.
        [self.viewController seekContent:self.castContentTime];
      } else {
        // If content is playing on cast, seek to content position of
        // cast device.
        CMTime videoPosition =
            CMTimeMakeWithSeconds(self.mediaControlChannel.approximateStreamPosition, 1000000);
        [self.viewController seekContent:videoPosition];
      }

      [self.deviceManager leaveApplication];
      [self.deviceManager disconnect];

      [self deviceDisconnected];
      [self updateButtonStates];
    }
  }
}

#pragma mark - GCKDeviceManagerDelegate
- (void)deviceManagerDidConnect:(GCKDeviceManager *)deviceManager {
  NSLog(@"connected to %@!", self.selectedDevice.friendlyName);

  [self updateButtonStates];
  [self.deviceManager launchApplication:kReceiverAppID];
}

- (void)sendMessage:(NSString *)message {
  NSLog(@"Sending message: %@", message);
  [self.messageChannel sendTextMessage:message];
}

- (void)onCastMessageReceived:(CastMessageChannel *)channel withMessage:(NSString *)message {
  // handle the delegate being called here
  NSLog(@"Receiving message: %@", message);
  NSArray *splitMessage = [message componentsSeparatedByString:@","];
  NSString *event = splitMessage[0];
  if ([event isEqualToString:@"onContentPauseRequested"]) {
    self.castAdPlaying = true;
    self.castContentTime = CMTimeMakeWithSeconds([splitMessage[1] floatValue], 1);
  } else if ([event isEqualToString:@"onContentResumeRequested"]) {
    self.castAdPlaying = false;
  }
}

// [START media-control-channel]
- (void)deviceManager:(GCKDeviceManager *)deviceManager
    didConnectToCastApplication:(GCKApplicationMetadata *)applicationMetadata
                      sessionID:(NSString *)sessionID
            launchedApplication:(BOOL)launchedApplication {
  NSLog(@"application has launched");
  self.mediaControlChannel = [[GCKMediaControlChannel alloc] init];
  self.mediaControlChannel.delegate = self;
  self.messageChannel =
      [[CastMessageChannel alloc] initWithNamespace:@"urn:x-cast:com.google.ads.ima.cast"];
  self.messageChannel.delegate = self;
  [self.deviceManager addChannel:self.mediaControlChannel];
  [self.deviceManager addChannel:self.messageChannel];
  // [START_EXCLUDE silent]
  [self.mediaControlChannel requestStatus];
  // [END_EXCLUDE silent]
  [self castVideo:self];
}
// [END media-control-channel]

- (void)deviceManager:(GCKDeviceManager *)deviceManager
    didFailToConnectWithError:(GCKError *)error {
  [self showError:error];
  [self deviceDisconnected];
  [self updateButtonStates];
}

- (void)deviceManager:(GCKDeviceManager *)deviceManager didDisconnectWithError:(NSError *)error {
  NSLog(@"Received notification that device disconnected");
  if (error != nil) {
    [self showError:error];
  }

  [self deviceDisconnected];
  [self updateButtonStates];
}

- (void)deviceManager:(GCKDeviceManager *)deviceManager
    didReceiveStatusForApplication:(GCKApplicationMetadata *)applicationMetadata {
  self.applicationMetadata = applicationMetadata;
}

#pragma mark - misc
- (void)showError:(NSError *)error {
  UIAlertController *alert =
      [UIAlertController alertControllerWithTitle:@"error"
                                          message:error.description
                                   preferredStyle:UIAlertControllerStyleAlert];
  UIAlertAction *action =
      [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil];
  [alert addAction:action];
  [self presentViewController:alert animated:YES completion:nil];
}

@end
