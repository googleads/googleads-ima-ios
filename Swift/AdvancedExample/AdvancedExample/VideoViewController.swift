//
//  VideoViewController.swift
//  AdvancedExample
//
//  Created by Shawn Busolits on 5/6/15.
//

import Foundation
import UIKit

import GoogleInteractiveMediaAds

extension CMTime {
  var isValid:Bool { return (flags & .Valid) != nil }
}

class VideoViewController: UIViewController, IMAAdsLoaderDelegate, IMAAdsManagerDelegate {

  // UI outlets.
  @IBOutlet weak var topLabel: UILabel!
  @IBOutlet weak var videoView: UIView!
  @IBOutlet weak var videoControls: UIToolbar!
  @IBOutlet weak var playheadButton: UIButton!
  @IBOutlet weak var playheadTimeText: UITextField!
  @IBOutlet weak var durationTimeText: UITextField!
  @IBOutlet weak var progressBar: UISlider!
  @IBOutlet weak var companionView: UIView!
  @IBOutlet weak var consoleView: UITextView!

  // Input field for ad tag pop-up.
  @IBOutlet weak var tagInput: UITextField?

  // Tracking for play/pause.
  var isAdPlayback = false

  // Play/Pause buttons.
  var playBtnBG = UIImage(named: "play.png")
  var pauseBtnBG = UIImage(named: "pause.png")

  // Storage points for resizing between fullscreen and non-fullscreen.
  var fullscreenVideoFrame: CGRect?
  var portraitVideoViewFrame: CGRect?
  var portraitVideoFrame: CGRect?
  var fullscreenControlsFrame: CGRect?
  var portraitControlsViewFrame: CGRect?
  var portraitControlsFrame: CGRect?
  var isFullscreen = false

  // Gesture recognizer for tap on video.
  var videoTapRecognizer: UITapGestureRecognizer?

  // IMA SDK handles.
  var contentPlayhead: IMAAVPlayerContentPlayhead?
  var adsLoader: IMAAdsLoader!
  var adsManager: IMAAdsManager?
  var companionSlot: IMACompanionAdSlot?

  // Content player handles.
  var video: Video!
  var contentPlayer: AVPlayer?
  var contentPlayerLayer: AVPlayerLayer?

  var contentRateContext: UInt8 = 1
  var contentDurationContext: UInt8 = 2

  let AdEventNames: [IMAAdEventType: String] = [
    IMAAdEventType.AD_BREAK_READY: "Ad Break Ready",
    IMAAdEventType.ALL_ADS_COMPLETED: "All Ads Completed",
    IMAAdEventType.CLICKED: "Clicked",
    IMAAdEventType.COMPLETE: "Complete",
    IMAAdEventType.FIRST_QUARTILE: "First Quartile",
    IMAAdEventType.LOADED: "Loaded",
    IMAAdEventType.MIDPOINT: "Midpoint",
    IMAAdEventType.PAUSE: "Pause",
    IMAAdEventType.RESUME: "Resume",
    IMAAdEventType.SKIPPED: "Skipped",
    IMAAdEventType.STARTED: "Started",
    IMAAdEventType.TAPPED: "Tapped",
    IMAAdEventType.THIRD_QUARTILE: "Third Quartile"
  ]

  enum PlayButtonType: Int {
    case PlayButton = 0
    case PauseButton = 1
  }

  // MARK: Set-up methods

  // Set up the new view controller.
  override func viewDidLoad() {
    super.viewDidLoad()
    topLabel.text = video.title as String

    // Fix iPhone issue of log text starting in the middle of the UITextView
    automaticallyAdjustsScrollViewInsets = false

    // Set up CGRects for resizing the video and controls on rotate.
    var videoViewOrigin = videoView.frame.origin
    var videoViewBounds = videoView.bounds
    portraitVideoViewFrame = CGRectMake(
        videoViewOrigin.x,
        videoViewOrigin.y,
        videoViewBounds.size.width,
        videoViewBounds.size.height)
    portraitVideoFrame = CGRectMake(0, 0, videoViewBounds.size.width, videoViewBounds.size.height)

    var videoControlsOrigin = videoControls.frame.origin
    var videoControlsBounds = videoControls.bounds
    portraitControlsViewFrame = CGRectMake(
        videoControlsOrigin.x,
        videoControlsOrigin.y,
        videoControlsBounds.size.width,
        videoControlsBounds.size.height)
    portraitControlsFrame =
        CGRectMake(0, 0, videoControlsBounds.size.width, videoControlsBounds.size.height)

    // Set videoView on top of everything else (for fullscreen support).
    view.bringSubviewToFront(videoView)
    view.bringSubviewToFront(videoControls)

    // Check orientation, set to fullscreen if we're in landscape
    if (UIDeviceOrientationIsLandscape(UIDevice.currentDevice().orientation)) {
      viewDidEnterLandscape()
    }

    // Set up content player and IMA classes, then request ads. If the user selected "Custom",
    // get the ad tag from the pop-up dialog.
    setUpContentPlayer()
    setUpIMA()
    if (video.tag == "custom") {
      let tagPrompt = UIAlertController(
        title: "Ad Tag",
        message: nil,
        preferredStyle: UIAlertControllerStyle.Alert)
      tagPrompt.addTextFieldWithConfigurationHandler(addTextField)
      tagPrompt.addAction(
        UIAlertAction(title: "Cancel", style: UIAlertActionStyle.Default, handler: nil))
      tagPrompt.addAction(
        UIAlertAction(title: "OK", style: UIAlertActionStyle.Default, handler: tagEntered))
      presentViewController(tagPrompt, animated: true, completion: nil)
    } else {
      requestAdsWithTag(video.tag)
    }
  }

  // Handler when user clicks "OK" on the ad tag pop-up
  func tagEntered(alert: UIAlertAction!) {
    requestAdsWithTag(tagInput!.text)
  }

  // Used to create the text field in the language pop-up.
  func addTextField(textField: UITextField!) {
    textField.placeholder = ""
    tagInput = textField
  }

  override func viewWillDisappear(animated: Bool) {
    contentPlayer!.pause()
    // Don't reset if we're presenting a modal view (e.g. in-app clickthrough).
    if ((navigationController!.viewControllers as NSArray).indexOfObject(self) == NSNotFound) {
      if (adsManager != nil) {
        adsManager!.destroy()
        adsManager = nil
      }
      contentPlayer = nil
    }
    super.viewWillDisappear(animated)
  }

  // Initialize the content player and load content.
  func setUpContentPlayer() {
    // Load AVPlayer with path to our content.
    var contentUrl = NSURL(string: video.video)
    contentPlayer = AVPlayer(URL: contentUrl)

    // Playhead observers for progress bar.
    var controller: VideoViewController = self
    controller.contentPlayer?.addPeriodicTimeObserverForInterval(
        CMTimeMake(1, 30),
        queue: nil,
      usingBlock: {(time: CMTime) -> Void in
          if (self.contentPlayer != nil) {
            var duration = controller.getPlayerItemDuration(self.contentPlayer!.currentItem)
            controller.updatePlayheadWithTime(time, duration: duration)
          }
    })
    contentPlayer!.addObserver(
        self,
        forKeyPath: "rate",
        options: NSKeyValueObservingOptions.New,
        context: &contentRateContext)
    contentPlayer!.addObserver(
        self,
        forKeyPath: "currentItem.duration",
        options: NSKeyValueObservingOptions.New,
        context: &contentDurationContext)
    NSNotificationCenter.defaultCenter().addObserver(
        self,
        selector: "contentDidFinishPlaying:",
        name: AVPlayerItemDidPlayToEndTimeNotification,
        object: contentPlayer!.currentItem)

    // Set up fullscreen tap listener to show controls
    videoTapRecognizer = UITapGestureRecognizer(target: self, action: "showFullscreenControls:")
    videoView.addGestureRecognizer(videoTapRecognizer!)

    // Create a player layer for the player.
    contentPlayerLayer = AVPlayerLayer(player: contentPlayer)

    // Size, position, and display the AVPlayer.
    contentPlayerLayer!.frame = videoView.layer.bounds
    videoView.layer.addSublayer(contentPlayerLayer)
  }

  // Handler for keypath listener that is added for content playhead observer.
  override func observeValueForKeyPath(
      keyPath: String,
      ofObject object: AnyObject,
      change: [NSObject : AnyObject],
      context: UnsafeMutablePointer<Void>) {
    if (context == &contentRateContext && contentPlayer == object as? AVPlayer) {
      updatePlayheadState(contentPlayer!.rate != 0)
    } else if (context == &contentDurationContext && contentPlayer == object as? AVPlayer) {
      updatePlayheadDurationWithTime(getPlayerItemDuration(contentPlayer!.currentItem))
    }
  }

  // MARK: UI handlers

  // Handle clicks on play/pause button.
  @IBAction func onPlayPauseClicked(sender: AnyObject) {
    if (!isAdPlayback) {
      if (contentPlayer!.rate == 0) {
        contentPlayer!.play()
      } else {
        contentPlayer!.pause()
      }
    } else {
      if (playheadButton.tag == PlayButtonType.PlayButton.rawValue) {
        adsManager!.resume()
        setPlayButtonType(PlayButtonType.PauseButton)
      } else {
        adsManager!.pause()
        setPlayButtonType(PlayButtonType.PlayButton)
      }
    }
  }

  // Updates play button for provided playback state.
  func updatePlayheadState(isPlaying: Bool) {
    setPlayButtonType(isPlaying ? PlayButtonType.PauseButton : PlayButtonType.PlayButton)
  }

  // Sets play button type.
  func setPlayButtonType(buttonType: PlayButtonType) {
    playheadButton.tag = buttonType.rawValue
    playheadButton.setImage(
        buttonType == PlayButtonType.PauseButton ? pauseBtnBG : playBtnBG,
        forState: UIControlState.Normal)
  }

  // Called when the user seeks.
  @IBAction func playheadValueChanged(sender: AnyObject) {
    if (!sender.isKindOfClass(UISlider)) {
      return
    }
    if (!isAdPlayback) {
      var slider = sender as! UISlider
      contentPlayer!.seekToTime(CMTimeMake(Int64(slider.value), 1))
    }
  }

  // Used to track progress of ads for progress bar.
  func adDidProgressToTime(mediaTime: NSTimeInterval, totalTime: NSTimeInterval) {
    var time = CMTimeMakeWithSeconds(mediaTime, 1000)
    var duration = CMTimeMakeWithSeconds(totalTime, 1000)
    updatePlayheadWithTime(time, duration: duration)
    progressBar.maximumValue = Float(CMTimeGetSeconds(duration))
  }

  // Get the duration value from the player item.
  func getPlayerItemDuration(item: AVPlayerItem) -> CMTime {
    var itemDuration = kCMTimeInvalid
    if (item.respondsToSelector("duration")) {
      itemDuration = item.duration
    } else {
      if (item.asset != nil && item.asset.respondsToSelector("duration")) {
        itemDuration = item.asset.duration
      }
    }
    return itemDuration
  }

  // Updates progress bar for provided time and duration.
  func updatePlayheadWithTime(time: CMTime, duration: CMTime) {
    if (!time.isValid) {
      return
    }
    var currentTime = CMTimeGetSeconds(time)
    if (isnan(currentTime)) {
      return
    }
    progressBar.value = Float(currentTime)
    playheadTimeText.text =
        NSString(format: "%d:%02d", Int(currentTime / 60), Int(currentTime % 60)) as String
    updatePlayheadDurationWithTime(duration)
  }

  func updatePlayheadDurationWithTime(time: CMTime!) {
    if (!time.isValid) {
      return
    }
    var durationValue = CMTimeGetSeconds(time)
    if (isnan(durationValue)) {
      return
    }
    progressBar.maximumValue = Float(durationValue)
    durationTimeText.text =
        NSString(format: "%d:%02d", Int(durationValue / 60), Int(durationValue % 60)) as String
  }

  override func didRotateFromInterfaceOrientation(
      interfaceOrientation: UIInterfaceOrientation) {
    switch (interfaceOrientation) {
      case UIInterfaceOrientation.LandscapeLeft: fallthrough
      case UIInterfaceOrientation.LandscapeRight:
        viewDidEnterPortrait()
        break
      case UIInterfaceOrientation.Portrait: fallthrough
      case UIInterfaceOrientation.PortraitUpsideDown:
        viewDidEnterLandscape()
        break
      case UIInterfaceOrientation.Unknown:
        break
    }
  }

  func viewDidEnterLandscape() {
    isFullscreen = true
    var screenRect = UIScreen.mainScreen().bounds
    if ((UIDevice.currentDevice().systemVersion as NSString).floatValue < 8.0) {
      fullscreenVideoFrame = CGRectMake(0, 0, screenRect.size.height, screenRect.size.width)
      fullscreenControlsFrame = CGRectMake(
          0,
          screenRect.size.width - videoControls.frame.size.height,
          screenRect.size.height,
          self.videoControls.frame.size.height)
    } else {
      fullscreenVideoFrame = CGRectMake(0, 0, screenRect.size.width, screenRect.size.height)
      fullscreenControlsFrame = CGRectMake(
          0,
          screenRect.size.height - self.videoControls.frame.size.height,
          screenRect.size.width,
          self.videoControls.frame.size.height)
    }
    UIApplication.sharedApplication().setStatusBarHidden(
        true,
        withAnimation: UIStatusBarAnimation.None)
    navigationController!.setNavigationBarHidden(true, animated: false)
    videoView.frame = fullscreenVideoFrame!
    contentPlayerLayer!.frame = fullscreenVideoFrame!
    videoControls.frame = fullscreenControlsFrame!
    videoControls.hidden = true
  }

  func viewDidEnterPortrait() {
    isFullscreen = false
    UIApplication.sharedApplication().setStatusBarHidden(
      false,
      withAnimation: UIStatusBarAnimation.None)
    navigationController!.setNavigationBarHidden(false, animated: false)
    videoView.frame = portraitVideoViewFrame!
    contentPlayerLayer!.frame = portraitVideoFrame!
    videoControls.frame = portraitControlsFrame!
  }

  @IBAction func videoControlsTouchStarted(sender: AnyObject) {
    NSObject.cancelPreviousPerformRequestsWithTarget(
        self,
        selector: "hideFullscreenControls",
        object: self)
  }

  @IBAction func videoControlsTouchEnded(sender: AnyObject) {
    startHideControlsTimer()
  }

  func showFullscreenControls(recognizer: UITapGestureRecognizer?) {
    if (isFullscreen == true) {
      videoControls.hidden = false
      videoControls.alpha = 0.9
      startHideControlsTimer()
    }
  }

  func startHideControlsTimer() {
    NSTimer.scheduledTimerWithTimeInterval(
        3,
        target: self,
        selector: "hideFullscreenControls",
        userInfo: nil,
        repeats: false)
  }

  func hideFullscreenControls() {
    UIView.animateWithDuration(0.5, animations: {() -> Void in self.videoControls.alpha = 0.0})
  }

  // MARK: IMA SDK methods

  // Initialize ad display container.
  func createAdDisplayContainer() -> IMAAdDisplayContainer {
    // Create our AdDisplayContainer. Initialize it with our videoView as the container. This
    // will result in ads being displayed over our content video.
    if (companionView != nil) {
      return IMAAdDisplayContainer(adContainer: videoView, companionSlots: [companionSlot!])
    } else {
      return IMAAdDisplayContainer(adContainer: videoView, companionSlots: nil)
    }
  }

  // Register companion slots.
  func setUpCompanions() {
    companionSlot = IMACompanionAdSlot(
        view: companionView,
        width: Int32(companionView.frame.size.width),
        height: Int32(companionView.frame.size.height))
  }

  // Create playhead for content tracking.
  func createContentPlayhead() {
    contentPlayhead = IMAAVPlayerContentPlayhead(AVPlayer: contentPlayer)
  }

  // Initialize AdsLoader.
  func setUpIMA() {
    if (adsManager != nil) {
      adsManager!.destroy()
    }
    adsLoader.contentComplete()
    adsLoader.delegate = self
    if (companionView != nil) {
      setUpCompanions()
    }
  }

  // Request ads for provided tag.
  func requestAdsWithTag(adTagUrl: String!) {
    logMessage("Requesting ads")
    // Create an ad request with our ad tag, display container, and optional user context.
    var request = IMAAdsRequest(
        adTagUrl: adTagUrl,
        adDisplayContainer: createAdDisplayContainer(),
        userContext: nil)
    adsLoader.requestAdsWithRequest(request)
  }

  // Notify IMA SDK when content is done for post-rolls.
  func contentDidFinishPlaying(notification: NSNotification) {
    // Make sure we don't call contentComplete as a result of an ad completing.
    if ((notification.object as? AVPlayerItem) == contentPlayer!.currentItem) {
      adsLoader.contentComplete()
    }
  }

  // MARK: AdsLoader Delegates

  func adsLoader(loader: IMAAdsLoader!, adsLoadedWithData adsLoadedData: IMAAdsLoadedData!) {
    // Grab the instance of the IMAAdsManager and set ourselves as the delegate.
    adsManager = adsLoadedData.adsManager
    adsManager!.delegate = self
    // Create ads rendering settings to tell the SDK to use the in-app browser.
    var adsRenderingSettings = IMAAdsRenderingSettings()
    adsRenderingSettings.webOpenerPresentingController = self
    // Create a content playhead so the SDK can track our content for VMAP and ad rules.
    createContentPlayhead()
    // Initialize the ads manager.
    adsManager!.initializeWithContentPlayhead(
        contentPlayhead,
        adsRenderingSettings: adsRenderingSettings)
  }

  func adsLoader(loader: IMAAdsLoader!, failedWithErrorData adErrorData: IMAAdLoadingErrorData!) {
    // Something went wrong loading ads. Log the error and play the content.
    logMessage("Error loading ads: \(adErrorData.adError.message)")
    isAdPlayback = false
    setPlayButtonType(PlayButtonType.PauseButton)
    contentPlayer!.play()
  }

  // MARK: AdsManager Delegates

  func adsManager(adsManager: IMAAdsManager!, didReceiveAdEvent event: IMAAdEvent!) {
    var eventType = AdEventNames[event.type]
    logMessage("AdsManager event \(eventType!)")
    switch (event.type) {
      case IMAAdEventType.LOADED:
        adsManager.start()
        break
      case IMAAdEventType.PAUSE:
        setPlayButtonType(PlayButtonType.PlayButton)
        break
      case IMAAdEventType.RESUME:
        setPlayButtonType(PlayButtonType.PauseButton)
        break
      case IMAAdEventType.TAPPED:
        showFullscreenControls(nil)
        break
      default:
        break
    }
  }

  func adsManager(adsManager: IMAAdsManager!, didReceiveAdError error: IMAAdError!) {
    // Something went wrong with the ads manager after ads were loaded. Log the error and play the
    // content.
    logMessage("AdsManager error: \(error.message)")
    isAdPlayback = false
    setPlayButtonType(PlayButtonType.PauseButton)
    contentPlayer!.play()
  }

  func adsManagerDidRequestContentPause(adsManager: IMAAdsManager!) {
    // The SDK is going to play ads, so pause the content.
    isAdPlayback = true
    setPlayButtonType(PlayButtonType.PauseButton)
    contentPlayer!.pause()
  }

  func adsManagerDidRequestContentResume(adsManager: IMAAdsManager!) {
    // The SDK is done playing ads (at least for now), so resume the content.
    isAdPlayback = false
    setPlayButtonType(PlayButtonType.PlayButton)
    contentPlayer!.play()
  }

  // MARK: Utility methods
  func logMessage(log: String!) {
    consoleView.text = consoleView.text.stringByAppendingString("\n" + log)
    NSLog(log)
    if (count(consoleView.text) > 0) {
      var bottom = NSMakeRange(count(consoleView.text) - 1, 1)
      consoleView.scrollRangeToVisible(bottom)
    }
  }

}
