#import "AcryptManager.h"
#import <Security/Security.h>

#define PLIST_PATH @"/var/mobile/Library/Preferences/com.yourname.acrypt.plist"

@implementation AcryptManager {
    NSMutableDictionary *_lockedApps;
}

+ (instancetype)shared {
    static AcryptManager *shared = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        shared = [[self alloc] init];
    });
    return shared;
}

- (instancetype)init {
    if (self = [super init]) {
        _lockedApps = [NSMutableDictionary dictionaryWithContentsOfFile:PLIST_PATH] ?: [NSMutableDictionary new];
    }
    return self;
}

- (BOOL)isAppLocked:(NSString *)bundleID {
    return [_lockedApps[bundleID] boolValue];
}

- (void)toggleLockForApp:(NSString *)bundleID {
    _lockedApps[bundleID] = @(![self isAppLocked:bundleID]);
    [_lockedApps writeToFile:PLIST_PATH atomically:YES];
}

- (void)authenticateForApp:(NSString *)bundleID completion:(void(^)(BOOL))completion {
    LAContext *context = [LAContext new];
    NSError *error;
    
    BOOL canAuth = [context canEvaluatePolicy:LAPolicyDeviceOwnerAuthentication error:&error];
    
    if (canAuth) {
        [context evaluatePolicy:LAPolicyDeviceOwnerAuthentication
                localizedReason:@"Unlock App" 
                          reply:^(BOOL success, NSError *error) {
            completion(success);
        }];
    } else {
        // Fallback to passcode input
        UIAlertController *alert = [UIAlertController 
            alertControllerWithTitle:@"Enter Passcode"
            message:nil
            preferredStyle:UIAlertControllerStyleAlert];
        
        [alert addTextFieldWithConfigurationHandler:^(UITextField *textField) {
            textField.secureTextEntry = YES;
        }];
        
        [alert addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil]];
        [alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
            completion([alert.textFields.firstObject.text isEqualToString:@"1234"]); // Replace with keychain check
        }]];
        
        [[UIApplication sharedApplication].keyWindow.rootViewController presentViewController:alert animated:YES completion:nil];
    }
}
@end
