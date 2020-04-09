#ifndef Logger_h
#define Logger_h

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface Logger: NSObject

+ (instancetype)sharedInstance;

- (void)logWithMessage:(NSString *)message;

@end

NS_ASSUME_NONNULL_END

#endif /* Logger_h */
