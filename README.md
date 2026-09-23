# STTouchDisplay

STTouchDisplay draws touch markers over an iOS app. It is an Objective-C static library for iOS 15 and later.

## Integrate

Add `STTouchDisplay.xcodeproj` to your app project as a project reference. Make `STTouchDisplay` a target dependency of your app, link `libSTTouchDisplay.a`, and add `$(BUILT_PRODUCTS_DIR)/include` to the app target's Header Search Paths. The library exports `STTouchDisplay.h` and `STTouchDisplayView.h` under `STTouchDisplay/`.

## Demo

Open `STTouchDisplay.xcworkspace` and run the `STTouchDisplayDemo` scheme on an iOS simulator. The demo links the root project's `libSTTouchDisplay.a` product through an Xcode project reference. Tap the button or drag on the screen to see markers without blocking the app's controls.

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

Marker size scales uniformly with UIKit's `UITouch.majorRadius`; a nonpositive radius uses the default size. The display does not represent contact rotation or an exact ellipse.

## Development

The `STTouchDisplay` scheme in the root project runs the library's unit tests. The demo scheme runs a UI test for button interaction and touch marker lifecycle. [CI](.github/workflows/ci.yml) checks formatting, builds and analyzes both projects, and runs both test targets. `STTouchDisplayImage.m` contains embedded image data and is excluded from the formatting check.

Run the same checks locally with `./scripts/check-formatting.sh`, `./scripts/build-library.sh`, `./scripts/test-library.sh`, and `./scripts/analyze-library.sh`. For the demo, run `./scripts/build-demo.sh`, `./scripts/test-demo-ui.sh`, and `./scripts/analyze-demo.sh`. Both test scripts use an iPhone 17 simulator by default; pass an Xcode destination string as the argument to use another device.

## License

The project is licensed under the [MIT License](LICENSE).
