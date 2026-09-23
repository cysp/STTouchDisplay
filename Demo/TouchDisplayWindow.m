// SPDX-License-Identifier: MIT

#import "TouchDisplayWindow.h"

#import "DemoViewController.h"
#import <STTouchDisplay/STTouchDisplay.h>

@implementation TouchDisplayWindow {
    STTouchDisplayView *_touchDisplay;
    BOOL _hasShownTouch;
}

- (void)installTouchDisplay {
    _touchDisplay = [[STTouchDisplayView alloc] initWithFrame:self.bounds];
    _touchDisplay.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self addSubview:_touchDisplay];
}

- (void)sendEvent:(UIEvent *)event {
    [super sendEvent:event];
    [_touchDisplay updateWithEvent:event];
    [self st_updateTouchStatusForEvent:event];
}

- (void)st_updateTouchStatusForEvent:(UIEvent *)event {
    if (event.type != UIEventTypeTouches) {
        return;
    }

    if (_touchDisplay.subviews.count > 0) {
        _hasShownTouch = YES;
        [(DemoViewController *)self.rootViewController setTouchStatus:@"Touch shown"];
    }

    if (!_hasShownTouch) {
        return;
    }

    for (UITouch *touch in [event touchesForWindow:self]) {
        if (touch.phase != UITouchPhaseEnded && touch.phase != UITouchPhaseCancelled) {
            continue;
        }
        __weak typeof(self) weakSelf = self;
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
          typeof(self) strongSelf = weakSelf;
          if (strongSelf && strongSelf->_touchDisplay.subviews.count == 0) {
              [(DemoViewController *)strongSelf.rootViewController setTouchStatus:@"Touch cleared"];
          }
        });
        break;
    }
}

@end
