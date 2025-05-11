#import <UIKit/UIKit.h>
#import <LocalAuthentication/LocalAuthentication.h>
#import <Security/Security.h>
#import <ElleKit/ElleKit.h>

// Keychain Helper (unchanged)
BOOL savePasscodeToKeychain(NSString *bundleID, NSString *passcode) {
    NSDictionary *query = @{
        (__bridge id)kSecClass: (__bridge id)kSecClassGenericPassword,
        (__bridge id)kSecAttrAccount: bundleID,
        (__bridge id)kSecValueData: [passcode dataUsingEncoding:NSUTF8StringEncoding],
        (__bridge id)kSecAttrAccessible: (__bridge id)kSecAttrAccessibleWhenPasscodeSetThisDeviceOnly
    };
    SecItemDelete((__bridge CFDictionaryRef)query);
    return (SecItemAdd((__bridge CFDictionaryRef)query, NULL) == errSecSuccess);
}

NSString *getPasscodeFromKeychain(NSString *bundleID) {
    NSDictionary *query = @{
        (__bridge id)kSecClass: (__bridge id)kSecClassGenericPassword,
        (__bridge id)kSecAttrAccount: bundleID,
        (__bridge id)kSecReturnData: @YES,
        (__bridge id)kSecMatchLimit: (__bridge id)kSecMatchLimitOne
    };
    CFTypeRef result = NULL;
    SecItemCopyMatching((__bridge CFDictionaryRef)query, &result);
    return result ? [[NSString alloc] initWithData:(__bridge NSData *)result encoding:NSUTF8StringEncoding] : nil;
}

// Hook SpringBoard to prevent app launches from ANYWHERE
EK_HOOK(SBApplication)
- (void)launchFromSource:(int)source animated:(BOOL)animated {
    [self checkAndBlockLaunch];
}

- (void)launchFromLocation:(int)location animated:(BOOL)animated {
    [self checkAndBlockLaunch];
}

- (void)checkAndBlockLaunch {
    NSString *bundleID = self.bundleIdentifier;
    NSString *passcode = getPasscodeFromKeychain(bundleID);
    NSDictionary *prefs = [NSDictionary dictionaryWithContentsOfFile:@"/var/jb/var/mobile/Library/Preferences/com.yourname.applocker.plist"];
    
    if (passcode && [prefs[@"enabled"] boolValue]) {
        LAContext *context = [[LAContext alloc] init];
        
        if (([prefs[@"useTouchID"] boolValue] && [%c(SBApplicationController) deviceHasTouchID]) || 
            ([prefs[@"useFaceID"] boolValue] && [%c(SBApplicationController) deviceHasFaceID])) {
            
            __block BOOL authSuccess = NO;
            dispatch_semaphore_t sema = dispatch_semaphore_create(0);
            
            [context evaluatePolicy:LAPolicyDeviceOwnerAuthentication
                    localizedReason:@"Unlock App"
                              reply:^(BOOL success, NSError *error) {
                authSuccess = success;
                dispatch_semaphore_signal(sema);
            }];
            
            dispatch_semaphore_wait(sema, DISPATCH_TIME_FOREVER);
            
            if (!authSuccess && [prefs[@"usePasscode"] boolValue]) {
                [self showPasscodePrompt];
            }
        } else if ([prefs[@"usePasscode"] boolValue]) {
            [self showPasscodePrompt];
        }
    } else {
        EK_ORIG(void, 0); // Allow launch if not locked
    }
}
EK_END

// Hook icon launches
EK_HOOK(SBIconController)
- (void)launchIcon:(id)icon {
    NSString *bundleID = [icon applicationBundleID];
    if ([self isAppLocked:bundleID]) {
        return; // Block launch
    }
    EK_ORIG(void, icon);
}
EK_END

// Hook App Library
EK_HOOK(SBAppSwitcherController)
- (void)launchAppFromAppSwitcher:(id)app {
    NSString *bundleID = [app bundleIdentifier];
    if ([self isAppLocked:bundleID]) {
        return; // Block launch
    }
    EK_ORIG(void, app);
}
EK_END