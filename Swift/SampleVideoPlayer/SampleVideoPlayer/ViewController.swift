import AVFoundation
import UIKit

class ViewController: UIViewController {

  static let kTestAppContentUrl_MP4 = "http://rmcdn.2mdn.net/Demo/html5/output.mp4%"

  @IBOutlet weak var playButton: UIButton!
  @IBOutlet weak var videoView: UIView!
  var contentPlayer: AVPlayer?
  var playerLayer: AVPlayerLayer?

  override func viewDidLoad() {
    super.viewDidLoad()

    playButton.layer.zPosition = CGFloat.max

    setUpContentPlayer()
  }

  override func viewDidAppear(animated: Bool) {
    playerLayer?.frame = videoView.layer.bounds
  }

  @IBAction func onPlayButtonTouch(sender: AnyObject) {
    contentPlayer?.play()
    playButton.hidden = true
  }

  func setUpContentPlayer() {
    // Load AVPlayer with path to our content.
    guard let contentURL = NSURL(string: ViewController.kTestAppContentUrl_MP4) else {
      print("ERROR: please use a valid URL for the content URL")
      return
    }
    contentPlayer = AVPlayer(URL: contentURL)

    // Create a player layer for the player.
    playerLayer = AVPlayerLayer(player: contentPlayer)
    videoView.layer.addSublayer(playerLayer!)
  }
}

