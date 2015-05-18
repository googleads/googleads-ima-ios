//
//  ViewController.swift
//  SampleVideoPlayer
//
//  Created by Shawn Busolits on 5/4/15.
//

import AVFoundation
import UIKit

class ViewController: UIViewController {

  let kTestAppContentUrl_MP4 = "http://rmcdn.2mdn.net/Demo/html5/output.mp4"

  @IBOutlet weak var playButton: UIButton!
  @IBOutlet weak var videoView: UIView!
  var contentPlayer: AVPlayer?

  override func viewDidLoad() {
    super.viewDidLoad()

    playButton.layer.zPosition = CGFloat.max

    setUpContentPlayer()
  }

  @IBAction func onPlayButtonTouch(sender: AnyObject) {
    contentPlayer!.play()
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
}

