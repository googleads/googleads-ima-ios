//
//  VideoTableViewCell.m
//  AdvancedExample
//
//  Created by Shawn Busolits on 11/19/14.
//  Copyright (c) 2014 Google, Inc. All rights reserved.
//

#import "VideoTableViewCell.h"

@implementation VideoTableViewCell

- (void)populateWithVideo:(Video *)video {
  self.videoLabel.text = video.title;
  [self.thumbnail setImage:video.thumbnail];
}

@end
