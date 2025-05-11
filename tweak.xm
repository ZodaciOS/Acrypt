#import <UIKit/UIKit.h>
#import <LocalAuthentication/LocalAuthentication.h>
#import "AcryptManager.h"

// iOS 14-16 Compatibility
@interface SBIcon : NSObject
- (NSString *)applicationBundleID;
@end

@interface SBIconView : UIView
- (SBIcon *)icon;
@end

__attribute__((constructor)) void init() {
    EKInit();
    
    // Core Hooks
    EKRegisterHook(SBIconView, @selector(_handleLongPress:));
    EKRegisterHook(NSClassFromString(@"SBApplication"), @selector(launchFromSource:));
    
    // iOS 15+ Only Features
    if (NSClassFromString(@"SBAppSwitcherController")) {
        EKRegisterHook(NSClassFromString(@"SBAppSwitcherController"), @selector(_handleAppLaunch:));
    }
}

EK_HOOK(SBIconView)
- (void)_handleLongPress:(id)gesture {
    NSString *bundleID = [[self icon] applicationBundleID];
    if (!bundleID) return EK_ORIG(void, gesture);
    
    UIAlertController *alert = [UIAlertController 
        alertControllerWithTitle:[[AcryptManager shared] isAppLocked:bundleID] ? @"🔓 Unlock" : @"🔒 Lock"
        message:nil
        preferredStyle:UIAlertControllerStyleActionSheet];
    
    [alert addAction:[UIAlertAction 
        actionWithTitle:@"Toggle Lock" 
        style:UIAlertActionStyleDefault 
        handler:^(UIAlertAction *action) {
            [[AcryptManager shared] toggleLockForApp:bundleID];
        }]];
    
    [[UIApplication sharedApplication].keyWindow.rootViewController presentViewController:alert animated:YES completion:nil];
    
    EK_ORIG(void, gesture);
}
EK_END

EK_HOOK(SBApplication)
- (void)launchFromSource:(int)source {
    NSString *bundleID = self.bundleIdentifier;
    if ([[AcryptManager shared] isAppLocked:bundleID]) {
        [[AcryptManager shared] authenticateForApp:bundleID completion:^(BOOL success) {
            if (success) EK_ORIG(void, source);
        }];
    } else {
        EK_ORIG(void, source);
    }
}
EK_END

// iOS 15+ Only
EK_HOOK(SBAppSwitcherController)
- (void)_handleAppLaunch:(id)app {
    NSString *bundleID = [app bundleIdentifier];
    if ([[AcryptManager shared] isAppLocked:bundleID]) return;
    EK_ORIG(void, app);
}
EK_END