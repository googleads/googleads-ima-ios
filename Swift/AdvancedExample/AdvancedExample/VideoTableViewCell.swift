//
//  VideoTableViewCell.swift
//  AdvancedExample
//
//  Created by Shawn Busolits on 5/6/15.
//

import Foundation
import UIKit

class VideoTableViewCell: UITableViewCell {

  @IBOutlet weak var thumbnail: UIImageView!
  @IBOutlet weak var videoLabel: UILabel!

  func populateWithVideo(video: Video) {
    videoLabel.text = video.title
    thumbnail.image = video.thumbnail
  }
}
