// SPDX-License-Identifier: MIT

#import "DemoViewController.h"
#import "TouchDisplayWindow.h"

@interface DemoSceneDelegate : UIResponder <UIWindowSceneDelegate>
@property(nonatomic, strong) UIWindow *window;
@end

@implementation DemoSceneDelegate

- (void)scene:(UIScene *)scene
    willConnectToSession:(UISceneSession *)session
                 options:(UISceneConnectionOptions *)connectionOptions {
    if (![scene isKindOfClass:[UIWindowScene class]]) {
        return;
    }

    TouchDisplayWindow *window = [[TouchDisplayWindow alloc] initWithWindowScene:(UIWindowScene *)scene];
    window.rootViewController = [[DemoViewController alloc] init];
    [window installTouchDisplay];
    self.window = window;
    [window makeKeyAndVisible];
}

@end
