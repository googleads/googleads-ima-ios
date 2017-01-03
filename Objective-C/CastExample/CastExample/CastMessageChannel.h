@import Foundation;
@import GoogleCast;

@class CastMessageChannel;

@protocol CastMessageChannelDelegate<NSObject>

- (void)castChannel:(CastMessageChannel *)channel didReceiveMessage:(NSString *)message;

@end

@interface CastMessageChannel : GCKCastChannel

@property(nonatomic, weak) id<CastMessageChannelDelegate> delegate;

@end
