# STTouchDisplay

STTouchDisplay draws touch markers over an iOS app. It is an Objective-C static library for iOS 15 and later.

## Integrate

Add `STTouchDisplay.xcodeproj` to your app project as a project reference. Make `STTouchDisplay` a target dependency of your app, link `libSTTouchDisplay.a`, and add `$(BUILT_PRODUCTS_DIR)/include` to the app target's Header Search Paths. The library exports `STTouchDisplay.h` and `STTouchDisplayView.h` under `STTouchDisplay/`.

## Display touches

Install one display view in each window you want to observe. For an iOS scene, create your window with `initWithWindowScene:`, assign its root view controller, and install the overlay before making the window key and visible. A window subclass can forward touch events:

```objc
#import <STTouchDisplay/STTouchDisplay.h>

@interface TouchDisplayWindow : UIWindow
@property(nonatomic, strong) STTouchDisplayView *touchDisplay;
- (void)installTouchDisplay;
@end

@implementation TouchDisplayWindow
- (void)installTouchDisplay {
    self.touchDisplay = [[STTouchDisplayView alloc] initWithFrame:self.bounds];
    self.touchDisplay.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self addSubview:self.touchDisplay];
}

- (void)sendEvent:(UIEvent *)event {
    [super sendEvent:event];
    [self.touchDisplay updateWithEvent:event];
}
@end
```

In your scene delegate's `scene:willConnectToSession:options:`, after creating `rootViewController`:

```objc
UIWindowScene *windowScene = (UIWindowScene *)scene;
TouchDisplayWindow *window = [[TouchDisplayWindow alloc] initWithWindowScene:windowScene];
window.rootViewController = rootViewController;
[window installTouchDisplay];
self.window = window;
[window makeKeyAndVisible];
```

The overlay does not intercept touches and only tracks events from its own window. Markers are a visual aid, not a measurement of finger contact area.

## Development

Open `STTouchDisplay.xcodeproj` and run the `STTouchDisplay` scheme's unit tests on an iOS simulator. [CI](.github/workflows/ci.yml) checks formatting, builds the library, runs the unit tests, and performs static analysis. `STTouchDisplayImage.m` contains embedded image data and is excluded from the formatting check.

## License

The project is licensed under the [MIT License](LICENSE).
