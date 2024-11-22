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
  @IBOutlet private weak var privacySettingsButton: UIButton!
  @IBOutlet private weak var videoView: UIView!
  private var contentPlayer: AVPlayer?
  private var playerLayer: AVPlayerLayer?
  private var contentPlayhead: IMAAVPlayerContentPlayhead?
  private let adsLoader = IMAAdsLoader(settings: nil)
  private var adsManager: IMAAdsManager?

  // MARK: - View controller lifecycle methods

  // Handle changes to user consent.
  @IBAction func privacySettingsTapped(_ sender: UIBarButtonItem) {
    ConsentManager.shared.presentPrivacyOptionsForm(from: self) {
      [weak self] formError in
      guard let self, let formError else { return }

      let alertController = UIAlertController(
        title: formError.localizedDescription, message: "Try again later.",
        preferredStyle: .alert)
      alertController.addAction(UIAlertAction(title: "OK", style: .cancel))
      self.present(alertController, animated: true)
    }
  }

  override func viewDidLoad() {
    super.viewDidLoad()

    playButton.layer.zPosition = CGFloat.greatestFiniteMagnitude

    ConsentManager.shared.gatherConsent(from: self) { [weak self] consentError in
      guard let self else { return }

      if let consentError {
        // Consent gathering failed. This sample loads ads using
        // consent obtained in the previous session.
        print("Error: \(consentError.localizedDescription)")
      }

      self.privacySettingsButton.isEnabled = ConsentManager.shared.isPrivacyOptionsRequired
    }

    setUpContentPlayer()
    adsLoader.delegate = self
  }

  override func viewDidAppear(_ animated: Bool) {
    playerLayer?.frame = self.videoView.layer.bounds
  }

  // MARK: Button Actions
  @IBAction func onPlayButtonTouch(_ sender: AnyObject) {
    if ConsentManager.shared.canRequestAds {
      requestAds()
    } else {
      contentPlayer?.play()
    }
    playButton.isHidden = true
  }

  @IBAction func onPrivacySettingsTouch(_ sender: UIButton) {
    ConsentManager.shared.presentPrivacyOptionsForm(from: self) {
      [weak self] formError in
      guard let self, let formError else { return }

      let alertController = UIAlertController(
        title: formError.localizedDescription, message: "Try again later.",
        preferredStyle: .alert)
      alertController.addAction(UIAlertAction(title: "OK", style: .cancel))
      self.present(alertController, animated: true)
    }
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
