#import "CastMessageChannel.h"

@implementation CastMessageChannel

- (void)didReceiveTextMessage:(NSString *)message {
  [self.delegate castChannel:self didReceiveMessage:message];
}

@end
