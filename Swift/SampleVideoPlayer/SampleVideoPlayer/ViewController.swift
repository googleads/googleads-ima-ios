import AVFoundation
import UIKit

class ViewController: UIViewController {

  static let kTestAppContentUrl_MP4 =
    "https://storage.googleapis.com/gvabox/media/samples/stock.mp4"

  @IBOutlet weak var playButton: UIButton!
  @IBOutlet weak var videoView: UIView!
  var contentPlayer: AVPlayer?
  var playerLayer: AVPlayerLayer?

  override func viewDidLoad() {
    super.viewDidLoad()

    playButton.layer.zPosition = CGFloat.greatestFiniteMagnitude

    setUpContentPlayer()
  }

  override func viewDidAppear(_ animated: Bool) {
    playerLayer?.frame = videoView.layer.bounds
  }

  @IBAction func onPlayButtonTouch(_ sender: AnyObject) {
    contentPlayer?.play()
    playButton.isHidden = true
  }

  func setUpContentPlayer() {
    // Load AVPlayer with path to our content.
    guard let contentURL = URL(string: ViewController.kTestAppContentUrl_MP4) else {
      print("ERROR: use a valid URL for the content URL")
      return
    }
    contentPlayer = AVPlayer(url: contentURL)

    // Create a player layer for the player.
    playerLayer = AVPlayerLayer(player: contentPlayer)
    videoView.layer.addSublayer(playerLayer!)
  }
}
