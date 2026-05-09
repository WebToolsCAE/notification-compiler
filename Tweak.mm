#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <UserNotifications/UserNotifications.h>

// Added attribute to tell compiler this function resolves at runtime on the device
__attribute__((weak_import)) extern "C" void MSHookMessageEx(Class _class, SEL selector, IMP replacement, IMP *result);
static void (*orig_applicationDidBecomeActive)(id self, SEL _cmd, UIApplication *application);

static NSArray<NSString *> *emailPool = nil;
static NSArray<NSString *> *valuePool = nil;
static NSMutableArray<NSString *> *availableEmails = nil;

void InitializeNotificationPools() {
    if (!emailPool) {
        emailPool = @[
            @"emily.parker92@gmail.com", @"x7qv19n@gmail.com", @"justinlee.work@outlook.com",
            @"moonlightmaria@yahoo.com", @"alexf1998@gmail.com", @"c4r8k2z@protonmail.com",
            @"samantha.james.hr@gmail.com", @"wildpixel77@icloud.com", @"ryan.taylor.dev@gmail.com",
            @"noah_2481@outlook.com", @"bluecoffeebean@yahoo.com", @"l9m2x8qv@gmail.com",
            @"olivergrant.business@gmail.com", @"ivyrose.art@icloud.com", @"daniel.kim23@gmail.com",
            @"protonuser883@protonmail.com", @"xxshadowfaxxx@gmail.com", @"harper.finance@outlook.com",
            @"emmawilliams448@gmail.com", @"pz7krt91@yahoo.com"
        ];
        valuePool = @[@"53.00€", @"27.31€"];
    }
}

void ResetSessionPool() {
    InitializeNotificationPools();
    availableEmails = [emailPool mutableCopy];
}

void FireSingleNotification(NSInteger uniqueIndex) {
    if ([availableEmails count] == 0) return;
    
    uint32_t emailIndex = arc4random_uniform((uint32_t)[availableEmails count]);
    NSString *selectedEmail = availableEmails[emailIndex];
    [availableEmails removeObjectAtIndex:emailIndex];
    
    NSString *selectedValue = valuePool[arc4random_uniform((uint32_t)[valuePool count])];
    
    UNUserNotificationCenter *center = [UNUserNotificationCenter currentNotificationCenter];
    UNMutableNotificationContent *content = [[UNMutableNotificationContent alloc] init];
    content.title = @"Payment Received";
    content.body = [NSString stringWithFormat:@"You received a payment of %@ from %@", selectedValue, selectedEmail];
    content.sound = [UNNotificationSound defaultSound];
    
    NSString *reqId = [NSString stringWithFormat:@"Storm-%@-%ld", [[NSUUID UUID] UUIDString], (long)uniqueIndex];
    UNNotificationRequest *request = [UNNotificationRequest requestWithIdentifier:reqId content:content trigger:nil];
    
    // Fixed typo from commonwealthHandler to withCompletionHandler
    [center addNotificationRequest:request withCompletionHandler:nil];
}

void ExecuteRhythmSequence() {
    UNUserNotificationCenter *center = [UNUserNotificationCenter currentNotificationCenter];
    [center requestAuthorizationWithOptions:(UNAuthorizationOptionSound | UNAuthorizationOptionAlert) 
                          completionHandler:^(BOOL granted, NSError * _Nullable error) {
        if (!granted) return;
        
        ResetSessionPool();
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(5.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            for (int i = 0; i < 10; i++) {
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)((i * 0.3) * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    FireSingleNotification(i);
                });
            }
            
            double waveTwoStartOffset = 4.7;
            for (int j = 0; j < 5; j++) {
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)((waveTwoStartOffset + (j * 0.3)) * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    FireSingleNotification(10 + j);
                });
            }
        });
    }];
}

static void replaced_applicationDidBecomeActive(id self, SEL _cmd, UIApplication *application) {
    orig_applicationDidBecomeActive(self, _cmd, application);
    ExecuteRhythmSequence();
}

__attribute__((constructor)) static void initialize() {
    Class targetClass = NSClassFromString(@"AppDelegate"); 
    SEL targetSelector = NSSelectorFromString(@"applicationDidBecomeActive:");
    if (targetClass && targetSelector) {
        // Safe check to verify MSHookMessageEx exists at runtime from libsubstrate
        if (&MSHookMessageEx != NULL) {
            MSHookMessageEx(targetClass, targetSelector, (IMP)replaced_applicationDidBecomeActive, (IMP *)&orig_applicationDidBecomeActive);
        }
    }
}
