// Tweak.xm
#import <UIKit/UIKit.h>
#import <LocalAuthentication/LocalAuthentication.h>
#import <Security/Security.h>
#import <ElleKit/ElleKit.h> // Modern hooking framework

// Keychain Helper Functions
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

// Hooking with ElleKit - Modern syntax
EK_HOOK(SBApplicationController)
+ (BOOL)deviceHasTouchID {
    LAContext *context = [[LAContext alloc] init];
    return [context canEvaluatePolicy:LAPolicyDeviceOwnerAuthenticationWithBiometrics error:nil] && 
           [context biometryType] == LABiometryTypeTouchID;
}

+ (BOOL)deviceHasFaceID {
    LAContext *context = [[LAContext alloc] init];
    return [context canEvaluatePolicy:LAPolicyDeviceOwnerAuthenticationWithBiometrics error:nil] && 
           [context biometryType] == LABiometryTypeFaceID;
}
EK_END

EK_HOOK(SBApplication)
- (void)launchFromSource:(int)source {
    NSString *bundleID = self.bundleIdentifier;
    NSString *passcode = getPasscodeFromKeychain(bundleID);
    NSDictionary *prefs = [NSDictionary dictionaryWithContentsOfFile:@"/var/jb/var/mobile/Library/Preferences/com.yourname.applocker.plist"];
    
    if (passcode && [prefs[@"enabled"] boolValue]) {
        LAContext *context = [[LAContext alloc] init];
        
        if (([prefs[@"useTouchID"] boolValue] && [SBApplicationController deviceHasTouchID]) || 
            ([prefs[@"useFaceID"] boolValue] && [SBApplicationController deviceHasFaceID])) {
            [context evaluatePolicy:LAPolicyDeviceOwnerAuthentication
                    localizedReason:@"Unlock App"
                              reply:^(BOOL success, NSError *error) {
                if (success) EK_ORIG(void, source);
                else if ([prefs[@"usePasscode"] boolValue]) [self showPasscodePrompt];
            }];
        } else if ([prefs[@"usePasscode"] boolValue]) {
            [self showPasscodePrompt];
        } else {
            EK_ORIG(void, source);
        }
    } else {
        EK_ORIG(void, source);
    }
}

- (void)showPasscodePrompt {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Enter Passcode"
                                                                 message:nil
                                                          preferredStyle:UIAlertControllerStyleAlert];
    [alert addTextFieldWithConfigurationHandler:^(UITextField *textField) {
        textField.secureTextEntry = YES;
        textField.placeholder = @"Passcode";
    }];
    
    [alert addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil]];
    [alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        if ([alert.textFields.firstObject.text isEqualToString:getPasscodeFromKeychain(self.bundleIdentifier)]) {
            EK_ORIG(void, 0); // Continue launch
        } else {
            // Show error
            UIAlertController *errorAlert = [UIAlertController alertControllerWithTitle:@"Wrong Passcode"
                                                                              message:nil
                                                                       preferredStyle:UIAlertControllerStyleAlert];
            [errorAlert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil]];
            [[UIApplication sharedApplication].keyWindow.rootViewController presentViewController:errorAlert animated:YES completion:nil];
        }
    }]];
    
    [[UIApplication sharedApplication].keyWindow.rootViewController presentViewController:alert animated:YES completion:nil];
}
EK_END

// Initialize ElleKit when tweak loads
__attribute__((constructor)) static void init() {
    EK_INIT();
    EK_REGISTER(SBApplicationController);
    EK_REGISTER(SBApplication);
    NSLog(@"AppLocker loaded successfully!");
}