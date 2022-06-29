import AVFoundation
import GoogleInteractiveMediaAds
import UIKit

class ViewController: UIViewController, IMAAdsLoaderDelegate, IMAAdsManagerDelegate {

  static let testAppContentURL = "https://storage.googleapis.com/gvabox/media/samples/stock.mp4"

  static let testAppAdTagURL =
    "https://pubads.g.doubleclick.net/gampad/ads?iu=/21775744923/external/"
    + "single_ad_samples&sz=640x480&cust_params=sample_ct%3Dlinear&ciu_szs=300x250%2C728x90&"
    + "gdfp_req=1&output=vast&unviewed_position_start=1&env=vp&impl=s&correlator="

  @IBOutlet private weak var playButton: UIButton!
  @IBOutlet private weak var videoView: UIView!
  private var contentPlayer: AVPlayer?
  private var playerLayer: AVPlayerLayer?
  private var contentPlayhead: IMAAVPlayerContentPlayhead?
  private let adsLoader = IMAAdsLoader(settings: nil)
  private var adsManager: IMAAdsManager?

  // MARK: - View controller lifecycle methods

  override func viewDidLoad() {
    super.viewDidLoad()

    playButton.layer.zPosition = CGFloat.greatestFiniteMagnitude

    setUpContentPlayer()
    adsLoader.delegate = self
  }

  override func viewDidAppear(_ animated: Bool) {
    playerLayer?.frame = self.videoView.layer.bounds
  }

  // MARK: Button Actions
  @IBAction func onPlayButtonTouch(_ sender: AnyObject) {
    requestAds()
    playButton.isHidden = true
  }

  // MARK: Content player methods

  private func setUpContentPlayer() {
    // Load AVPlayer with path to our content.
    guard let contentURL = URL(string: ViewController.testAppContentURL) else {
      print("ERROR: use a valid URL for the content URL")
      return
    }
    self.contentPlayer = AVPlayer(url: contentURL)
    guard let contentPlayer = self.contentPlayer else { return }

    // Create a player layer for the player.
    self.playerLayer = AVPlayerLayer(player: contentPlayer)
    guard let playerLayer = self.playerLayer else { return }

    // Size, position, and display the AVPlayer.
    playerLayer.frame = videoView.layer.bounds
    videoView.layer.addSublayer(playerLayer)

    // Set up our content playhead and contentComplete callback.
    contentPlayhead = IMAAVPlayerContentPlayhead(avPlayer: contentPlayer)
    NotificationCenter.default.addObserver(
      self,
      selector: #selector(ViewController.contentDidFinishPlaying(_:)),
      name: NSNotification.Name.AVPlayerItemDidPlayToEndTime,
      object: contentPlayer.currentItem)
  }

  @objc func contentDidFinishPlaying(_ notification: Notification) {
    // Make sure we don't call contentComplete as a result of an ad completing.
    if (notification.object as! AVPlayerItem) == contentPlayer?.currentItem {
      adsLoader.contentComplete()
    }
  }

  // MARK: IMA integration methods

  private func requestAds() {
    // Create ad display container for ad rendering.
    let adDisplayContainer = IMAAdDisplayContainer(
      adContainer: videoView, viewController: self, companionSlots: nil)
    // Create an ad request with our ad tag, display container, and optional user context.
    let request = IMAAdsRequest(
      adTagUrl: ViewController.testAppAdTagURL,
      adDisplayContainer: adDisplayContainer,
      contentPlayhead: contentPlayhead,
      userContext: nil)

    adsLoader.requestAds(with: request)
  }

  // MARK: - IMAAdsLoaderDelegate

  func adsLoader(_ loader: IMAAdsLoader, adsLoadedWith adsLoadedData: IMAAdsLoadedData) {
    // Grab the instance of the IMAAdsManager and set ourselves as the delegate.
    adsManager = adsLoadedData.adsManager
    adsManager?.delegate = self

    // Create ads rendering settings and tell the SDK to use the in-app browser.
    let adsRenderingSettings = IMAAdsRenderingSettings()
    adsRenderingSettings.linkOpenerPresentingController = self

    // Initialize the ads manager.
    adsManager?.initialize(with: adsRenderingSettings)
  }

  func adsLoader(_ loader: IMAAdsLoader, failedWith adErrorData: IMAAdLoadingErrorData) {
    print("Error loading ads: \(adErrorData.adError.message ?? "nil")")
    contentPlayer?.play()
  }

  // MARK: - IMAAdsManagerDelegate

  func adsManager(_ adsManager: IMAAdsManager, didReceive event: IMAAdEvent) {
    if event.type == IMAAdEventType.LOADED {
      // When the SDK notifies us that ads have been loaded, play them.
      adsManager.start()
    }
  }

  func adsManager(_ adsManager: IMAAdsManager, didReceive error: IMAAdError) {
    // Something went wrong with the ads manager after ads were loaded. Log the error and play the
    // content.
    print("AdsManager error: \(error.message ?? "nil")")
    contentPlayer?.play()
  }

  func adsManagerDidRequestContentPause(_ adsManager: IMAAdsManager) {
    // The SDK is going to play ads, so pause the content.
    contentPlayer?.pause()
  }

  func adsManagerDidRequestContentResume(_ adsManager: IMAAdsManager) {
    // The SDK is done playing ads (at least for now), so resume the content.
    contentPlayer?.play()
  }
}
