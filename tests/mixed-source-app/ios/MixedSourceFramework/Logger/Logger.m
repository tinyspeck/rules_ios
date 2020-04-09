
#import "Logger.h"

@implementation Logger

+ (instancetype)sharedInstance {
    static Logger *sharedInstance = nil;

    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[Logger alloc] init];
    });

    return sharedInstance;
}

- (void)logWithMessage:(NSString *)message {
    NSLog(@"%@", message);
}

@end
