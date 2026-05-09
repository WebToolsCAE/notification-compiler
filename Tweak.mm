#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <UserNotifications/UserNotifications.h>

__attribute__((weak_import)) extern "C" void MSHookMessageEx(Class _class, SEL selector, IMP replacement, IMP *result);
static void (*orig_applicationDidBecomeActive)(id self, SEL _cmd, UIApplication *application);

static NSArray<NSString *> *emailPool = nil;
static NSArray<NSString *> *valuePool = nil;
static NSMutableArray<NSString *> *availableEmails = nil;

@interface CustomNotificationDelegate : NSObject <UNUserNotificationCenterDelegate>
+ (instancetype)sharedInstance;
@end

@implementation CustomNotificationDelegate
+ (instancetype)sharedInstance {
    static CustomNotificationDelegate *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[CustomNotificationDelegate alloc] init];
    });
    return instance;
}
- (void)userNotificationCenter:(UNUserNotificationCenter *)center 
       willPresentNotification:(UNNotification *)notification 
         withCompletionHandler:(void (^)(UNNotificationPresentationOptions options))completionHandler {
    completionHandler(UNNotificationPresentationOptionList | UNNotificationPresentationOptionBanner | UNNotificationPresentationOptionSound);
}
@end

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

void FireSingleNotification(NSInteger uniqueIndex) {
    if ([availableEmails count] == 0) return;
    
    uint32_t emailIndex = arc4random_uniform((uint32_t)[availableEmails count]);
    NSString *selectedEmail = availableEmails[emailIndex];
    [availableEmails removeObjectAtIndex:emailIndex];
    
    NSString *selectedValue = valuePool[arc4random_uniform((uint32_t)[valuePool count])];
    
    UNUserNotificationCenter *center = [UNUserNotificationCenter currentNotificationCenter];
    center.delegate = [CustomNotificationDelegate sharedInstance];
    
    UNMutableNotificationContent *content = [[UNMutableNotificationContent alloc] init];
    content.title = @"Payment Received";
    content.body = [NSString stringWithFormat:@"You received a payment of %@ from %@", selectedValue, selectedEmail];
    content.sound = [UNNotificationSound defaultSound];
    
    NSString *reqId = [NSString stringWithFormat:@"Storm-%@-%ld", [[NSUUID UUID] UUIDString], (long)uniqueIndex];
    UNNotificationRequest *request = [UNNotificationRequest requestWithIdentifier:reqId content:content trigger:nil];
    
    [center addNotificationRequest:request withCompletionHandler:nil];
}

// Triggered immediately when the overlay button is tapped
void StartNotificationStormSequence() {
    UNUserNotificationCenter *center = [UNUserNotificationCenter currentNotificationCenter];
    center.delegate = [CustomNotificationDelegate sharedInstance];
    
    [center requestAuthorizationWithOptions:(UNAuthorizationOptionSound | UNAuthorizationOptionAlert | UNAuthorizationOptionBadge) 
                          completionHandler:^(BOOL granted, NSError * _Nullable error) {
        if (!granted) return;
        
        InitializeNotificationPools();
        availableEmails = [emailPool mutableCopy];
        
        // Starts directly on button tap (no initial 5-second wait needed anymore)
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
    }];
}

// Class object to handle the button press target action safely
@interface ButtonHandler : NSObject
+ (void)buttonTapped;
@end
@implementation ButtonHandler
+ (void)buttonTapped {
    StartNotificationStormSequence();
}
@end

// Inject the floating UI Button elements directly into the top window layer
void CreateFloatingTriggerButton() {
    dispatch_async(dispatch_get_main_queue(), ^{
        UIWindow *keyWindow = nil;
        for (UIWindow *window in [UIApplication sharedApplication].windows) {
            if (window.isKeyWindow) {
                keyWindow = window;
                break;
            }
        }
        if (!keyWindow && [UIApplication sharedApplication].windows.count > 0) {
            keyWindow = [UIApplication sharedApplication].windows.firstObject;
        }
        if (!keyWindow) return;

        // Prevent rendering duplicates if app re-triggers activation loop
        if ([keyWindow viewWithTag:9988]) return;

        UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
        btn.tag = 9988;
        // Positioned safely centered at the top of the viewport
        btn.frame = CGRectMake((keyWindow.frame.size.width - 160) / 2, 60, 160, 40);
        btn.backgroundColor = [UIColor systemRedColor];
        btn.layer.cornerRadius = 20;
        btn.layer.shadowColor = [UIColor blackColor].CGColor;
        btn.layer.shadowOpacity = 0.5;
        btn.layer.shadowOffset = CGSizeMake(0, 2);
        
        [btn setTitle:@"⚡ Start Storm" forState:UIControlStateNormal];
        btn.titleLabel.font = [UIFont boldSystemFontOfSize:14];
        [btn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        
        [btn addTarget:[ButtonHandler class] action:@selector(buttonTapped) forControlEvents:UIControlEventTouchUpInside];
        
        [keyWindow addSubview:btn];
        [keyWindow bringSubviewToFront:btn];
    });
}

static void replaced_applicationDidBecomeActive(id self, SEL _cmd, UIApplication *application) {
    orig_applicationDidBecomeActive(self, _cmd, application);
    CreateFloatingTriggerButton();
}

__attribute__((constructor)) static void initialize() {
    Class targetClass = NSClassFromString(@"AppDelegate");
    SEL targetSelector = NSSelectorFromString(@"applicationDidBecomeActive:");
    
    if (!targetClass) {
        targetClass = NSClassFromString(@"SceneDelegate");
        targetSelector = NSSelectorFromString(@"sceneDidBecomeActive:");
    }
    if (!targetClass) {
        targetClass = NSClassFromString(@"UIApplication");
        targetSelector = NSSelectorFromString(@"_sendWillEnterForegroundCallbacks");
    }

    if (targetClass && targetSelector) {
        if (&MSHookMessageEx != NULL) {
            MSHookMessageEx(targetClass, targetSelector, (IMP)replaced_applicationDidBecomeActive, (IMP *)&orig_applicationDidBecomeActive);
        }
    }
}
