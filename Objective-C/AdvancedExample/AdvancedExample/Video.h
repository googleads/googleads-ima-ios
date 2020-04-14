@import AVFoundation;
@import UIKit;

@interface Video : NSObject

/// The title of the video.
@property(nonatomic, copy) NSString *title;

/// The thumbnail for the video list.
@property(nonatomic, strong) UIImage *thumbnail;

/// The URL for the video media file.
@property(nonatomic, copy) NSString *video;

/// The URL for the VAST response.
@property(nonatomic, copy) NSString *tag;

/// Returns an initialized video.
- (instancetype)initWithTitle:(NSString *)title
                    thumbnail:(UIImage *)thumbnail
                        video:(NSString *)video
                          tag:(NSString *)tag;

@end
