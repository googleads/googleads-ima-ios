//
//  Copyright 2024 Google LLC
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

import AVFoundation
import GoogleInteractiveMediaAds

class PlayerContainerViewController: UIViewController, IMAAdsLoaderDelegate, IMAAdsManagerDelegate {
  static let contentURL = URL(
    string: "https://storage.googleapis.com/gvabox/media/samples/stock.mp4")!

  static let adTagURLString =
    "https://pubads.g.doubleclick.net/gampad/ads?iu=/21775744923/external/"
    + "single_ad_samples&sz=640x480&cust_params=sample_ct%3Dlinear&ciu_szs=300x250%2C728x90&"
    + "gdfp_req=1&output=vast&unviewed_position_start=1&env=vp&impl=s&correlator="

  private let adsLoader = IMAAdsLoader()
  private var adsManager: IMAAdsManager?
  private var contentPlayer = AVPlayer(url: PlayerContainerViewController.contentURL)

  private lazy var videoView: UIView = {
    let videoView = UIView()
    videoView.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(videoView)

    NSLayoutConstraint.activate([
      videoView.bottomAnchor.constraint(
        equalTo: view.safeAreaLayoutGuide.bottomAnchor),
      videoView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
      videoView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
      videoView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
    ])
    return videoView
  }()

  private lazy var contentPlayhead: IMAAVPlayerContentPlayhead = {
    IMAAVPlayerContentPlayhead(avPlayer: contentPlayer)
  }()

  private lazy var playerLayer: AVPlayerLayer = {
    AVPlayerLayer(player: contentPlayer)
  }()

  // MARK: - View controller lifecycle methods

  override func viewDidLoad() {
    super.viewDidLoad()

    videoView.layer.addSublayer(playerLayer)
    adsLoader.delegate = self

    NotificationCenter.default.addObserver(
      self,
      selector: #selector(contentDidFinishPlaying(_:)),
      name: .AVPlayerItemDidPlayToEndTime,
      object: contentPlayer.currentItem)
  }

  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
    playerLayer.frame = videoView.layer.bounds
  }

  override func viewWillTransition(
    to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator
  ) {
    coordinator.animate { _ in
      // do nothing
    } completion: { _ in
      self.playerLayer.frame = self.videoView.layer.bounds
    }
  }

  // MARK: - Public methods

  func playButtonPressed() {
    requestAds()
  }

  // MARK: - IMA integration methods

  private func requestAds() {
    // Create ad display container for ad rendering.
    let adDisplayContainer = IMAAdDisplayContainer(
      adContainer: videoView, viewController: self, companionSlots: nil)
    // Create an ad request with our ad tag, display container, and optional user context.
    let request = IMAAdsRequest(
      adTagUrl: PlayerContainerViewController.adTagURLString,
      adDisplayContainer: adDisplayContainer,
      contentPlayhead: contentPlayhead,
      userContext: nil)

    adsLoader.requestAds(with: request)
  }

  // MARK: - Content player methods

  @objc func contentDidFinishPlaying(_ notification: Notification) {
    // Make sure we don't call contentComplete as a result of an ad completing.
    if notification.object as? AVPlayerItem == contentPlayer.currentItem {
      adsLoader.contentComplete()
    }
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
    if let message = adErrorData.adError.message {
      print("Error loading ads: \(message)")
    }
    contentPlayer.play()
  }

  // MARK: - IMAAdsManagerDelegate

  func adsManager(_ adsManager: IMAAdsManager, didReceive event: IMAAdEvent) {
    // When the SDK notifies us the ads have been loaded, play them.
    if event.type == IMAAdEventType.LOADED {
      adsManager.start()
    }
  }

  func adsManager(_ adsManager: IMAAdsManager, didReceive error: IMAAdError) {
    // Something went wrong with the ads manager after ads were loaded.
    // Log the error and play the content.
    if let message = error.message {
      print("AdsManager error: \(message)")
    }
    contentPlayer.play()
  }

  func adsManagerDidRequestContentPause(_ adsManager: IMAAdsManager) {
    // The SDK is going to play ads, so pause the content.
    contentPlayer.pause()
  }

  func adsManagerDidRequestContentResume(_ adsManager: IMAAdsManager) {
    // The SDK is done playing ads (at least for now), so resume the content.
    contentPlayer.play()
  }

  // MARK: - deinit

  deinit {
    NotificationCenter.default.removeObserver(self)
  }
}
