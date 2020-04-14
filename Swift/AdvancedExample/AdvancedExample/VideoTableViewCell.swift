import Foundation
import UIKit

class VideoTableViewCell: UITableViewCell {

  @IBOutlet weak var thumbnail: UIImageView!
  @IBOutlet weak var videoLabel: UILabel!

  func populateWithVideo(_ video: Video) {
    videoLabel.text = video.title
    thumbnail.image = video.thumbnail
  }
}
