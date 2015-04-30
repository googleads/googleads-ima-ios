//
//  VideoTableViewCell.h
//  AdvancedExample
//
//  Created by Shawn Busolits on 11/19/14.
//  Copyright (c) 2014 Google, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "Video.h"

@interface VideoTableViewCell : UITableViewCell

@property(nonatomic, weak, readwrite) IBOutlet UIImageView *thumbnail;
@property(nonatomic, weak, readwrite) IBOutlet UILabel *videoLabel;

- (void)populateWithVideo:(Video *)Video;

@end
