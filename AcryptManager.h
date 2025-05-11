#import <Foundation/Foundation.h>
#import <LocalAuthentication/LocalAuthentication.h>

@interface AcryptManager : NSObject
+ (instancetype)shared;
- (BOOL)isAppLocked:(NSString *)bundleID;
- (void)toggleLockForApp:(NSString *)bundleID;
- (void)authenticateForApp:(NSString *)bundleID completion:(void(^)(BOOL))completion;
@end
