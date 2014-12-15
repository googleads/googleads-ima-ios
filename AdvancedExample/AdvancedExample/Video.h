#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface Video : NSObject

// The title of the video
@property(nonatomic, strong) NSString *title;

// The thumbnail for the video list.
@property(nonatomic, strong) UIImage *thumbnail;

// The URL for the video media file
@property(nonatomic, strong) NSString *video;

// The URL for the VAST response
@property(nonatomic, strong) NSString *tag;

// Language
@property(nonatomic, strong) NSString *language;

// Returns an initialized video.
- (instancetype)initWithTitle:(NSString *)title
                    thumbnail:(UIImage *)thumbnail
                        video:(NSString *)video
                          tag:(NSString *)tag
                     language:(NSString *)language;

@end