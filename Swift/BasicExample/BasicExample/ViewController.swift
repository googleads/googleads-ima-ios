import AVFoundation
import GoogleInteractiveMediaAds
import UIKit

class ViewController: UIViewController, IMAAdsLoaderDelegate, IMAAdsManagerDelegate {

//  static let kTestAppContentUrl_MP4 = "http://rmcdn.2mdn.net/Demo/html5/output.mp4"
  static let kTestAppContentUrl_MP4 = "http://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerBlazes.mp4"

  @IBOutlet weak var playButton: UIButton!
  @IBOutlet weak var videoView: UIView!
  var contentPlayer: AVPlayer?
  var playerLayer: AVPlayerLayer?

  var contentPlayhead: IMAAVPlayerContentPlayhead?
  var adsLoader: IMAAdsLoader!
  var adsManager: IMAAdsManager!

//  static let kTestAppAdTagUrl =
//      "https://pubads.g.doubleclick.net/gampad/ads?sz=640x480&" +
//      "iu=/124319096/external/single_ad_samples&ciu_szs=300x250&impl=s&gdfp_req=1&env=vp&" +
//      "output=vast&unviewed_position_start=1&" +
//      "cust_params=deployment%3Ddevsite%26sample_ct%3Dlinear&correlator=";
    
    static let kTestAppAdTagUrl = "https://sneezy.aws.rubiconproject.com/rp-eng-soln/rp-qa-sites/videoTest/ad1/recycling_VAST2.xml";

  override func viewDidLoad() {
    super.viewDidLoad()

    playButton.layer.zPosition = CGFloat.greatestFiniteMagnitude

    setUpContentPlayer()
    setUpAdsLoader()
  }

  override func viewDidAppear(_ animated: Bool) {
    playerLayer?.frame = self.videoView.layer.bounds
  }

  @IBAction func onPlayButtonTouch(_ sender: AnyObject) {
    //contentPlayer.play()
    requestAds()
    playButton.isHidden = true
  }

  func setUpContentPlayer() {
    // Load AVPlayer with path to our content.
    guard let contentURL = URL(string: ViewController.kTestAppContentUrl_MP4) else {
      print("ERROR: please use a valid URL for the content URL")
      return
    }
    contentPlayer = AVPlayer(url: contentURL)

    // Create a player layer for the player.
    playerLayer = AVPlayerLayer(player: contentPlayer)

    // Size, position, and display the AVPlayer.
    playerLayer?.frame = videoView.layer.bounds
    videoView.layer.addSublayer(playerLayer!)

    // Set up our content playhead and contentComplete callback.
    contentPlayhead = IMAAVPlayerContentPlayhead(avPlayer: contentPlayer)
    NotificationCenter.default.addObserver(
      self,
      selector: #selector(ViewController.contentDidFinishPlaying(_:)),
      name: NSNotification.Name.AVPlayerItemDidPlayToEndTime,
      object: contentPlayer?.currentItem);
  }

  @objc func contentDidFinishPlaying(_ notification: Notification) {
    // Make sure we don't call contentComplete as a result of an ad completing.
    if (notification.object as! AVPlayerItem) == contentPlayer?.currentItem {
      adsLoader.contentComplete()
    }
  }

  func setUpAdsLoader() {
    adsLoader = IMAAdsLoader(settings: nil)
    adsLoader.delegate = self
  }

  func requestAds() {
    // Create ad display container for ad rendering.
    let adDisplayContainer = IMAAdDisplayContainer(adContainer: videoView, companionSlots: nil)
    // Create an ad request with our ad tag, display container, and optional user context.
    let request = IMAAdsRequest(
        adTagUrl: ViewController.kTestAppAdTagUrl,
        adDisplayContainer: adDisplayContainer,
        contentPlayhead: contentPlayhead,
        userContext: nil)

    adsLoader.requestAds(with: request)
  }

  // MARK: - IMAAdsLoaderDelegate

  func adsLoader(_ loader: IMAAdsLoader!, adsLoadedWith adsLoadedData: IMAAdsLoadedData!) {
    // Grab the instance of the IMAAdsManager and set ourselves as the delegate.
    adsManager = adsLoadedData.adsManager
    adsManager.delegate = self

    // Create ads rendering settings and tell the SDK to use the in-app browser.
    let adsRenderingSettings = IMAAdsRenderingSettings()
    adsRenderingSettings.webOpenerPresentingController = self

    // Initialize the ads manager.
    adsManager.initialize(with: adsRenderingSettings)
  }

  func adsLoader(_ loader: IMAAdsLoader!, failedWith adErrorData: IMAAdLoadingErrorData!) {
    print("Error loading ads: \(adErrorData.adError.message)")
    contentPlayer?.play()
  }

  // MARK: - IMAAdsManagerDelegate

  func adsManager(_ adsManager: IMAAdsManager!, didReceive event: IMAAdEvent!) {
    if event.type == IMAAdEventType.LOADED {
      // When the SDK notifies us that ads have been loaded, play them.
      adsManager.start()
    }
  }

  func adsManager(_ adsManager: IMAAdsManager!, didReceive error: IMAAdError!) {
    // Something went wrong with the ads manager after ads were loaded. Log the error and play the
    // content.
    print("AdsManager error: \(error.message)")
    contentPlayer?.play()
  }

  func adsManagerDidRequestContentPause(_ adsManager: IMAAdsManager!) {
    // The SDK is going to play ads, so pause the content.
    contentPlayer?.pause()
  }

  func adsManagerDidRequestContentResume(_ adsManager: IMAAdsManager!) {
    // The SDK is done playing ads (at least for now), so resume the content.
    contentPlayer?.play()
  }
}

