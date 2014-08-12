//
//  IMASampleViewController.h
//  SampleAppV3
//
//  Copyright (c) 2013 Google Inc. All rights reserved.

#import <AVFoundation/AVFoundation.h>
#import <UIKit/UIKit.h>

// IMA SDK
#import "IMAAVPlayerContentPlayhead.h"
#import "IMAAd.h"
#import "IMAAdDisplayContainer.h"
#import "IMAAdsLoader.h"
#import "IMAAdsManager.h"

@interface IMASampleViewController : UIViewController<IMAAdsLoaderDelegate,
                                                      IMAAdsManagerDelegate,
                                                      IMAWebOpenerDelegate>

// Outlets for the xib
@property(nonatomic, strong) IBOutlet UIView *videoView;
@property(nonatomic, strong) IBOutlet UIView *largeCompanionSlot;
@property(nonatomic, strong) IBOutlet UIView *smallCompanionSlot;
@property(nonatomic, strong) IBOutlet UIButton *playHeadButton;
@property(nonatomic, strong) IBOutlet UITextField *playHeadTimeText;
@property(nonatomic, strong) IBOutlet UITextField *durationTimeText;
@property(nonatomic, strong) IBOutlet UISlider *progressBar;
@property(nonatomic, strong) IBOutlet UITextView *console;
@property(nonatomic, strong) IBOutlet UITextField *adTagUrlTextField;
@property(nonatomic, strong) IBOutlet UISwitch *browserSwitch;
@property(nonatomic, strong) IBOutlet UILabel *titleLabel;
@property(nonatomic, strong) IBOutlet UILabel *adPodInfoLabel;
@property(nonatomic, strong) IBOutlet UISwitch *useInAppSwitch;

// Storage point for the video view bounds
@property(nonatomic) CGRect fullscreenFrame;
@property(nonatomic) CGRect portraitViewFrame;
@property(nonatomic) CGRect portraitVideoFrame;

// Play button image.
@property(nonatomic, strong) UIImage *playBtnBG;
// Pause button image.
@property(nonatomic, strong) UIImage  *pauseBtnBG;
// The player that plays the content.
@property(nonatomic, strong) AVPlayer *contentPlayer;
// The player item used for content video playback.
@property(nonatomic, strong) AVPlayerItem *contentPlayerItem;
// The layer for the player
@property(nonatomic, strong) AVPlayerLayer *contentPlayerLayer;
// Player observer for playback UI.
@property(nonatomic, strong) id playHeadObserver;
// The content playhead used for content tracking.
@property(nonatomic, strong) IMAAVPlayerContentPlayhead *contentPlayhead;
// Map of companion ad slots.
@property(nonatomic, strong) NSDictionary *companionSlots;
// The language sent to the ad server.
@property(nonatomic, strong) NSString *language;

// Google IMA classes.
// The ads Loader class that requests and loads an ad.
@property(nonatomic, strong) IMAAdsLoader *adsLoader;
// The ads manager that plays a video ad.
@property(nonatomic, strong) IMAAdsManager *adsManager;
// The ad display container.
@property(nonatomic, strong) IMAAdDisplayContainer *adDisplayContainer;
// The ads rendering settings.
@property(nonatomic, strong) IMAAdsRenderingSettings *adsRenderingSettings;

#pragma mark UIOutlet functions

// Playhead control method.
- (IBAction)onPlayPauseClicked:(id)sender;

// Called when the playhead controller's value changed.
- (IBAction)playHeadValueChanged:(id)sender;

// Called when the Ad tag example value changed.
- (IBAction)adTagValueChanged:(id)sender;

// Request an ad using Google IMA SDK.
- (IBAction)onRequestAds;

// Forcefully unload the ad and the adsManager.
- (IBAction)onUnloadAds;

// Reset the state of the test app.
- (IBAction)onResetState;

// Toggle using the in app webview.
- (IBAction)onChangeInApp;

// When language button is pressed.
- (IBAction)onChangeLanguage;

# pragma mark Utility functions.

- (void)resetAppState;
- (IMASettings *)createIMASettings;

// Logs a message to the app's log text field.
- (void)logMessage:(NSString *)log, ...;

@end
