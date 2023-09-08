import Foundation
import GoogleInteractiveMediaAds
import UIKit

class VideoViewController: UIViewController, AVPictureInPictureControllerDelegate,
  IMAAdsLoaderDelegate, IMAAdsManagerDelegate
{

  // UI outlets.
  @IBOutlet weak var topLabel: UILabel!
  @IBOutlet weak var videoView: UIView!
  @IBOutlet weak var videoControls: UIToolbar!
  @IBOutlet weak var playheadButton: UIButton!
  @IBOutlet weak var playheadTimeText: UITextField!
  @IBOutlet weak var durationTimeText: UITextField!
  @IBOutlet weak var progressBar: UISlider!
  @IBOutlet weak var pictureInPictureButton: UIButton!
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
  var didRequestAds = false

  // Gesture recognizer for tap on video.
  var videoTapRecognizer: UITapGestureRecognizer?

  // PiP objects.
  var pictureInPictureController: AVPictureInPictureController?
  var pictureInPictureProxy: IMAPictureInPictureProxy?

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

  enum PlayButtonType: Int {
    case playButton = 0
    case pauseButton = 1
  }

  /// MARK: Set-up methods

  /// Set up the new view controller.
  override func viewDidLoad() {
    super.viewDidLoad()
    topLabel.text = video.title as String

    // Set up CGRects for resizing the video and controls on rotate.
    let videoViewBounds = videoView.bounds
    portraitVideoViewFrame = videoView.frame
    portraitVideoFrame = CGRect(
      x: 0, y: 0, width: videoViewBounds.size.width, height: videoViewBounds.size.height)

    let videoControlsBounds = videoControls.bounds
    portraitControlsViewFrame = videoControls.frame
    portraitControlsFrame =
      CGRect(
        x: 0, y: 0, width: videoControlsBounds.size.width, height: videoControlsBounds.size.height)

    // Set videoView on top of everything else (for fullscreen support).
    view.bringSubviewToFront(videoView)
    view.bringSubviewToFront(videoControls)

    // Check orientation, set to fullscreen if we're in landscape
    if UIDevice.current.orientation.isLandscape {
      viewDidEnterLandscape()
    }

    // Set up content player and IMA classes, then request ads. If the user selected "Custom",
    // get the ad tag from the pop-up dialog.
    setUpContentPlayer()
    setUpIMA()
  }

  override func viewDidAppear(_ animated: Bool) {
    guard !didRequestAds else {
      return
    }
    didRequestAds = true

    // Make the request only once the view has been instantiated.
    if video.tag == "custom" {
      let tagPrompt = UIAlertController(
        title: "Ad Tag",
        message: nil,
        preferredStyle: .alert)
      tagPrompt.addTextField(configurationHandler: addTextField)
      tagPrompt.addAction(
        UIAlertAction(title: "Cancel", style: .default, handler: nil))
      tagPrompt.addAction(
        UIAlertAction(title: "OK", style: .default, handler: tagEntered))
      present(tagPrompt, animated: true, completion: nil)
    } else {
      requestAdsWithTag(video.tag)
    }
  }

  // Handler when user clicks "OK" on the ad tag pop-up
  func tagEntered(_ alert: UIAlertAction!) {
    requestAdsWithTag(tagInput!.text)
  }

  // Used to create the text field in the language pop-up.
  func addTextField(_ textField: UITextField!) {
    textField.placeholder = ""
    tagInput = textField
  }

  override func viewWillDisappear(_ animated: Bool) {
    contentPlayer!.pause()
    // Don't reset if we're presenting a modal view (for example, in-app clickthrough).
    if (navigationController!.viewControllers as NSArray).index(of: self) == NSNotFound {
      if adsManager != nil {
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
    let contentUrl = URL(string: video.video)
    self.contentPlayer = AVPlayer(url: contentUrl!)
    guard let contentPlayer = self.contentPlayer else { return }

    // Playhead observers for progress bar.
    let controller: VideoViewController = self
    controller.contentPlayer?.addPeriodicTimeObserver(
      forInterval: CMTimeMake(value: 1, timescale: 30),
      queue: nil,
      using: { (time: CMTime) -> Void in
        if self.contentPlayer != nil {
          let duration = controller.getPlayerItemDuration(self.contentPlayer!.currentItem!)
          controller.updatePlayheadWithTime(time, duration: duration)
        }
      })
    contentPlayer.addObserver(
      self,
      forKeyPath: "rate",
      options: NSKeyValueObservingOptions.new,
      context: &contentRateContext)
    contentPlayer.addObserver(
      self,
      forKeyPath: "currentItem.duration",
      options: NSKeyValueObservingOptions.new,
      context: &contentDurationContext)
    NotificationCenter.default.addObserver(
      self,
      selector: #selector(VideoViewController.contentDidFinishPlaying(_:)),
      name: NSNotification.Name.AVPlayerItemDidPlayToEndTime,
      object: contentPlayer.currentItem)

    // Set up fullscreen tap listener to show controls
    videoTapRecognizer = UITapGestureRecognizer(
      target: self, action: #selector(VideoViewController.showFullscreenControls(_:)))
    videoView.addGestureRecognizer(videoTapRecognizer!)

    // Create a player layer for the player.
    contentPlayerLayer = AVPlayerLayer(player: contentPlayer)

    // Size, position, and display the AVPlayer.
    contentPlayerLayer!.frame = videoView.layer.bounds
    videoView.layer.addSublayer(contentPlayerLayer!)

    // Create content playhead
    contentPlayhead = IMAAVPlayerContentPlayhead(avPlayer: contentPlayer)

    // Set ourselves up for PiP.
    pictureInPictureProxy = IMAPictureInPictureProxy(avPictureInPictureControllerDelegate: self)
    pictureInPictureController = AVPictureInPictureController(playerLayer: contentPlayerLayer!)
    if pictureInPictureController != nil {
      pictureInPictureController!.delegate = pictureInPictureProxy
    }
    if !AVPictureInPictureController.isPictureInPictureSupported() && pictureInPictureButton != nil
    {
      pictureInPictureButton.isHidden = true
    }
  }

  // Handler for keypath listener that is added for content playhead observer.
  override func observeValue(
    forKeyPath keyPath: String?,
    of object: Any?,
    change: [NSKeyValueChangeKey: Any]?,
    context: UnsafeMutableRawPointer?
  ) {
    if context == &contentRateContext && contentPlayer == object as? AVPlayer {
      updatePlayheadState(contentPlayer!.rate != 0)
    } else if context == &contentDurationContext && contentPlayer == object as? AVPlayer {
      var time = CMTime.zero
      if let currentItem = contentPlayer?.currentItem {
        time = getPlayerItemDuration(currentItem)
      }
      updatePlayheadDurationWithTime(time)
    }
  }

  // MARK: UI handlers

  // Handle clicks on play/pause button.
  @IBAction func onPlayPauseClicked(_ sender: AnyObject) {
    if !isAdPlayback {
      if contentPlayer!.rate == 0 {
        contentPlayer!.play()
      } else {
        contentPlayer!.pause()
      }
    } else {
      if playheadButton.tag == PlayButtonType.playButton.rawValue {
        adsManager!.resume()
        setPlayButtonType(PlayButtonType.pauseButton)
      } else {
        adsManager!.pause()
        setPlayButtonType(PlayButtonType.playButton)
      }
    }
  }

  // Updates play button for provided playback state.
  func updatePlayheadState(_ isPlaying: Bool) {
    setPlayButtonType(isPlaying ? PlayButtonType.pauseButton : PlayButtonType.playButton)
  }

  // Sets play button type.
  func setPlayButtonType(_ buttonType: PlayButtonType) {
    playheadButton.tag = buttonType.rawValue
    playheadButton.setImage(
      buttonType == PlayButtonType.pauseButton ? pauseBtnBG : playBtnBG,
      for: .normal)
  }

  // Called when the user seeks.
  @IBAction func playheadValueChanged(_ sender: AnyObject) {
    if !sender.isKind(of: UISlider.self) {
      return
    }
    if !isAdPlayback {
      let slider = sender as! UISlider
      contentPlayer!.seek(to: CMTimeMake(value: Int64(slider.value), timescale: 1))
    }
  }

  // Used to track progress of ads for progress bar.
  func adDidProgressToTime(_ mediaTime: TimeInterval, totalTime: TimeInterval) {
    let time = CMTimeMakeWithSeconds(mediaTime, preferredTimescale: 1000)
    let duration = CMTimeMakeWithSeconds(totalTime, preferredTimescale: 1000)
    updatePlayheadWithTime(time, duration: duration)
    progressBar.maximumValue = Float(CMTimeGetSeconds(duration))
  }

  // Get the duration value from the player item.
  func getPlayerItemDuration(_ item: AVPlayerItem) -> CMTime {
    var itemDuration = CMTime.invalid
    if item.responds(to: #selector(getter: CAMediaTiming.duration)) {
      itemDuration = item.duration
    } else {
      if item.asset.responds(to: #selector(getter: CAMediaTiming.duration)) {
        itemDuration = item.asset.duration
      }
    }
    return itemDuration
  }

  // Updates progress bar for provided time and duration.
  func updatePlayheadWithTime(_ time: CMTime, duration: CMTime) {
    if !CMTIME_IS_VALID(time) {
      return
    }
    let currentTime = CMTimeGetSeconds(time)
    if currentTime.isNaN {
      return
    }
    progressBar.value = Float(currentTime)
    playheadTimeText.text =
      NSString(
        format: "%d:%02d", Int(currentTime / 60),
        Int(currentTime.truncatingRemainder(dividingBy: 60))) as String
    updatePlayheadDurationWithTime(duration)
  }

  func updatePlayheadDurationWithTime(_ time: CMTime!) {
    if !time.isValid {
      return
    }
    let durationValue = CMTimeGetSeconds(time)
    if durationValue.isNaN {
      return
    }
    progressBar.maximumValue = Float(durationValue)
    durationTimeText.text =
      NSString(
        format: "%d:%02d", Int(durationValue / 60),
        Int(durationValue.truncatingRemainder(dividingBy: 60))) as String
  }

  override func didRotate(
    from interfaceOrientation: UIInterfaceOrientation
  ) {
    switch interfaceOrientation {
    case UIInterfaceOrientation.landscapeLeft, UIInterfaceOrientation.landscapeRight:
      viewDidEnterPortrait()
      break
    case UIInterfaceOrientation.portrait, UIInterfaceOrientation.portraitUpsideDown:
      viewDidEnterLandscape()
      break
    default:
      break
    }
  }

  func viewDidEnterLandscape() {
    isFullscreen = true
    let screenRect = UIScreen.main.bounds
    if (UIDevice.current.systemVersion as NSString).floatValue < 8.0 {
      fullscreenVideoFrame = CGRect(
        x: 0, y: 0, width: screenRect.size.height, height: screenRect.size.width)
      fullscreenControlsFrame = CGRect(
        x: 0,
        y: screenRect.size.width - videoControls.frame.size.height,
        width: screenRect.size.height,
        height: self.videoControls.frame.size.height)
    } else {
      fullscreenVideoFrame = CGRect(
        x: 0, y: 0, width: screenRect.size.width, height: screenRect.size.height)
      fullscreenControlsFrame = CGRect(
        x: 0,
        y: screenRect.size.height - self.videoControls.frame.size.height,
        width: screenRect.size.width,
        height: self.videoControls.frame.size.height)
    }
    navigationController!.setNavigationBarHidden(true, animated: false)
    videoView.frame = fullscreenVideoFrame!
    contentPlayerLayer!.frame = fullscreenVideoFrame!
    videoControls.frame = fullscreenControlsFrame!
    videoControls.isHidden = true
  }

  func viewDidEnterPortrait() {
    isFullscreen = false
    navigationController!.setNavigationBarHidden(false, animated: false)
    videoView.frame = portraitVideoViewFrame!
    contentPlayerLayer!.frame = portraitVideoFrame!
    videoControls.frame = portraitControlsFrame!
  }

  @IBAction func videoControlsTouchStarted(_ sender: AnyObject) {
    NSObject.cancelPreviousPerformRequests(
      withTarget: self,
      selector: #selector(VideoViewController.hideFullscreenControls),
      object: self)
  }

  @IBAction func videoControlsTouchEnded(_ sender: AnyObject) {
    startHideControlsTimer()
  }

  @objc func showFullscreenControls(_ recognizer: UITapGestureRecognizer?) {
    if isFullscreen {
      videoControls.isHidden = false
      videoControls.alpha = 0.9
      startHideControlsTimer()
    }
  }

  func startHideControlsTimer() {
    Timer.scheduledTimer(
      timeInterval: 3,
      target: self,
      selector: #selector(VideoViewController.hideFullscreenControls),
      userInfo: nil,
      repeats: false)
  }

  @objc func hideFullscreenControls() {
    UIView.animate(withDuration: 0.5, animations: { () -> Void in self.videoControls.alpha = 0.0 })
  }

  @IBAction func onPipButtonClicked(_ sender: AnyObject) {
    if pictureInPictureController!.isPictureInPictureActive {
      pictureInPictureController!.stopPictureInPicture()
    } else {
      pictureInPictureController!.startPictureInPicture()
    }
  }

  // MARK: IMA SDK methods

  // Initialize ad display container.
  func createAdDisplayContainer() -> IMAAdDisplayContainer {
    // Create our AdDisplayContainer. Initialize it with our videoView as the container. This
    // will result in ads being displayed over our content video.
    if companionView != nil {
      return IMAAdDisplayContainer(
        adContainer: videoView, viewController: self, companionSlots: [companionSlot!])
    } else {
      return IMAAdDisplayContainer(
        adContainer: videoView, viewController: self, companionSlots: nil)
    }
  }

  // Register companion slots.
  func setUpCompanions() {
    companionSlot = IMACompanionAdSlot(
      view: companionView,
      width: Int(companionView.frame.size.width),
      height: Int(companionView.frame.size.height))
  }

  // Initialize AdsLoader.
  func setUpIMA() {
    if adsManager != nil {
      adsManager!.destroy()
    }
    adsLoader.contentComplete()
    adsLoader.delegate = self
    if companionView != nil {
      setUpCompanions()
    }
  }

  // Request ads for provided tag.
  func requestAdsWithTag(_ adTagUrl: String!) {
    guard let contentPlayer = self.contentPlayer else { return }
    guard let pictureInPictureProxy = self.pictureInPictureProxy else { return }
    logMessage("Requesting ads")
    // Create an ad request with our ad tag, display container, and optional user context.
    let request = IMAAdsRequest(
      adTagUrl: adTagUrl,
      adDisplayContainer: createAdDisplayContainer(),
      avPlayerVideoDisplay: IMAAVPlayerVideoDisplay(avPlayer: contentPlayer),
      pictureInPictureProxy: pictureInPictureProxy,
      userContext: nil)
    adsLoader.requestAds(with: request)
  }

  // Notify IMA SDK when content is done for post-rolls.
  @objc func contentDidFinishPlaying(_ notification: Notification) {
    // Make sure we don't call contentComplete as a result of an ad completing.
    if (notification.object as? AVPlayerItem) == contentPlayer!.currentItem {
      adsLoader.contentComplete()
    }
  }

  // MARK: AdsLoader Delegates

  func adsLoader(_ loader: IMAAdsLoader!, adsLoadedWith adsLoadedData: IMAAdsLoadedData!) {
    // Grab the instance of the IMAAdsManager and set ourselves as the delegate.
    adsManager = adsLoadedData.adsManager
    adsManager!.delegate = self
    // Create ads rendering settings to tell the SDK to use the in-app browser.
    let adsRenderingSettings = IMAAdsRenderingSettings()
    adsRenderingSettings.linkOpenerPresentingController = self
    // Initialize the ads manager.
    adsManager!.initialize(with: adsRenderingSettings)
  }

  func adsLoader(_ loader: IMAAdsLoader!, failedWith adErrorData: IMAAdLoadingErrorData!) {
    // Something went wrong loading ads. Log the error and play the content.
    logMessage("Error loading ads: \(String(describing: adErrorData.adError.message))")
    isAdPlayback = false
    setPlayButtonType(PlayButtonType.pauseButton)
    contentPlayer!.play()
  }

  // MARK: AdsManager Delegates

  func adsManager(_ adsManager: IMAAdsManager!, didReceive event: IMAAdEvent!) {
    logMessage("AdsManager event \(event.typeString)")
    switch event.type {
    case IMAAdEventType.LOADED:
      if pictureInPictureController == nil
        || !pictureInPictureController!.isPictureInPictureActive
      {
        adsManager.start()
      }
      break
    case IMAAdEventType.PAUSE:
      setPlayButtonType(PlayButtonType.playButton)
      break
    case IMAAdEventType.RESUME:
      setPlayButtonType(PlayButtonType.pauseButton)
      break
    case IMAAdEventType.TAPPED:
      showFullscreenControls(nil)
      break
    default:
      break
    }
  }

  func adsManager(_ adsManager: IMAAdsManager!, didReceive error: IMAAdError!) {
    // Something went wrong with the ads manager after ads were loaded. Log the error and play the
    // content.
    logMessage("AdsManager error: \(String(describing: error.message))")
    isAdPlayback = false
    setPlayButtonType(PlayButtonType.pauseButton)
    contentPlayer!.play()
  }

  func adsManagerDidRequestContentPause(_ adsManager: IMAAdsManager!) {
    // The SDK is going to play ads, so pause the content.
    isAdPlayback = true
    setPlayButtonType(PlayButtonType.pauseButton)
    contentPlayer!.pause()
  }

  func adsManagerDidRequestContentResume(_ adsManager: IMAAdsManager!) {
    // The SDK is done playing ads (at least for now), so resume the content.
    isAdPlayback = false
    setPlayButtonType(PlayButtonType.playButton)
    contentPlayer!.play()
  }

  // MARK: Utility methods
  func logMessage(_ log: String!) {
    consoleView.text = consoleView.text + ("\n" + log)
    NSLog(log)
    if consoleView.text.count > 0 {
      let bottom = NSMakeRange(consoleView.text.count - 1, 1)
      consoleView.scrollRangeToVisible(bottom)
    }
  }

  override var prefersStatusBarHidden: Bool {
    return isFullscreen
  }
}
