//
//  ViewController.swift
//  BasicExample
//
//  Created by Shawn Busolits on 5/4/15.
//

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

  let kTestAppAdTagUrl = "http://pubads.g.doubleclick.net/gampad/ads?sz=640x360" +
      "&iu=/6062/iab_vast_samples/skippable&ciu_szs=300x250,728x90&impl=s&gdfp_req=1&env=vp&" +
      "output=xml_vast3&unviewed_position_start=1&url=[referrer_url]&correlator=[timestamp]";

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
    var contentURL = NSURL(string: kTestAppContentUrl_MP4)
    contentPlayer = AVPlayer(URL: contentURL)

    // Create a player layer for the player.
    var playerLayer = AVPlayerLayer(player: contentPlayer)

    // Size, position, and display the AVPlayer.
    playerLayer.frame = self.videoView.layer.bounds
    videoView.layer.addSublayer(playerLayer)
  }

  func createContentPlayhead() {
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
    var adDisplayContainer = IMAAdDisplayContainer(adContainer: videoView, companionSlots: nil)
    // Create an ad request with our ad tag, display container, and optional user context.
    var request = IMAAdsRequest(
        adTagUrl: kTestAppAdTagUrl,
        adDisplayContainer: adDisplayContainer,
        userContext: nil)

    adsLoader!.requestAdsWithRequest(request)
  }

  func adsLoader(loader: IMAAdsLoader!, adsLoadedWithData adsLoadedData: IMAAdsLoadedData!) {
    // Grab the instance of the IMAAdsManager and set ourselves as the delegate.
    adsManager = adsLoadedData.adsManager
    adsManager!.delegate = self

    // Create ads rendering settings and tell the SDK to use the in-app browser.
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
    NSLog("Error loading ads: \(adErrorData.adError.message)")
    contentPlayer!.play()
  }

  func adsManager(adsManager: IMAAdsManager!, didReceiveAdEvent event: IMAAdEvent!) {
    if (event.type.value == kIMAAdEvent_LOADED.value) {
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

