import AVFoundation
import UIKit

import GoogleInteractiveMediaAds

class ViewController: UIViewController, IMAAdsLoaderDelegate, IMAAdsManagerDelegate {

  let kTestAppContentUrl_MP4 = "http://rmcdn.2mdn.net/Demo/html5/output.mp4"

  @IBOutlet weak var playButton: UIButton!
  @IBOutlet weak var videoView: UIView!
  var contentPlayer: AVPlayer?

  var contentPlayhead: IMAAVPlayerContentPlayhead?
  var adsLoader: IMAAdsLoader?
  var adsManager: IMAAdsManager?

  let kTestAppAdTagUrl =
      "https://pubads.g.doubleclick.net/gampad/ads?sz=640x480&" +
      "iu=/124319096/external/single_ad_samples&ciu_szs=300x250&impl=s&gdfp_req=1&env=vp&" +
      "output=vast&unviewed_position_start=1&" +
      "cust_params=deployment%3Ddevsite%26sample_ct%3Dlinear&correlator=";

  override func viewDidLoad() {
    super.viewDidLoad()

    playButton.layer.zPosition = CGFloat.max

    setUpContentPlayer()
    setUpAdsLoader()
  }

  @IBAction func onPlayButtonTouch(sender: AnyObject) {
    //contentPlayer!.play()
    requestAds()
    playButton.hidden = true
  }

  func setUpContentPlayer() {
    // Load AVPlayer with path to our content.
    let contentURL = NSURL(string: kTestAppContentUrl_MP4)
    contentPlayer = AVPlayer(URL: contentURL!)

    // Create a player layer for the player.
    let playerLayer = AVPlayerLayer(player: contentPlayer)

    // Size, position, and display the AVPlayer.
    playerLayer.frame = self.videoView.layer.bounds
    videoView.layer.addSublayer(playerLayer)

    // Set up our content playhead and contentComplete callback.
    contentPlayhead = IMAAVPlayerContentPlayhead(AVPlayer: contentPlayer)
    NSNotificationCenter.defaultCenter().addObserver(
      self,
      selector: "contentDidFinishPlaying:",
      name: AVPlayerItemDidPlayToEndTimeNotification,
      object: contentPlayer!.currentItem);
  }

  func contentDidFinishPlaying(notification: NSNotification) {
    // Make sure we don't call contentComplete as a result of an ad completing.
    if ((notification.object as! AVPlayerItem) == contentPlayer!.currentItem) {
      adsLoader!.contentComplete()
    }
  }

  func setUpAdsLoader() {
    adsLoader = IMAAdsLoader(settings: nil)
    adsLoader!.delegate = self
  }

  func requestAds() {
    // Create ad display container for ad rendering.
    let adDisplayContainer = IMAAdDisplayContainer(adContainer: videoView, companionSlots: nil)
    // Create an ad request with our ad tag, display container, and optional user context.
    let request = IMAAdsRequest(
        adTagUrl: kTestAppAdTagUrl,
        adDisplayContainer: adDisplayContainer,
        contentPlayhead: contentPlayhead,
        userContext: nil)

    adsLoader!.requestAdsWithRequest(request)
  }

  func adsLoader(loader: IMAAdsLoader!, adsLoadedWithData adsLoadedData: IMAAdsLoadedData!) {
    // Grab the instance of the IMAAdsManager and set ourselves as the delegate.
    adsManager = adsLoadedData.adsManager
    adsManager!.delegate = self

    // Create ads rendering settings and tell the SDK to use the in-app browser.
    let adsRenderingSettings = IMAAdsRenderingSettings()
    adsRenderingSettings.webOpenerPresentingController = self

    // Initialize the ads manager.
    adsManager!.initializeWithAdsRenderingSettings(adsRenderingSettings)
  }

  func adsLoader(loader: IMAAdsLoader!, failedWithErrorData adErrorData: IMAAdLoadingErrorData!) {
    NSLog("Error loading ads: \(adErrorData.adError.message)")
    contentPlayer!.play()
  }

  func adsManager(adsManager: IMAAdsManager!, didReceiveAdEvent event: IMAAdEvent!) {
    if (event.type == IMAAdEventType.LOADED) {
      // When the SDK notifies us that ads have been loaded, play them.
      adsManager.start()
    }
  }

  func adsManager(adsManager: IMAAdsManager!, didReceiveAdError error: IMAAdError!) {
    // Something went wrong with the ads manager after ads were loaded. Log the error and play the
    // content.
    NSLog("AdsManager error: \(error.message)")
    contentPlayer!.play()
  }

  func adsManagerDidRequestContentPause(adsManager: IMAAdsManager!) {
    // The SDK is going to play ads, so pause the content.
    contentPlayer!.pause()
  }

  func adsManagerDidRequestContentResume(adsManager: IMAAdsManager!) {
    // The SDK is done playing ads (at least for now), so resume the content.
    contentPlayer!.play()
  }
}

