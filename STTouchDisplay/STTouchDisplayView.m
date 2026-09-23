// Copyright (c) 2014 Scott Talbot.
// SPDX-License-Identifier: MIT

#import "STTouchDisplayView.h"
#import "STTouchDisplayImage.h"

static CGFloat const STTouchRadiusDefault = 5;

static CGAffineTransform STTouchViewTransformForRadius(CGFloat radius) {
    CGFloat const scale = (radius > 0 ? radius : STTouchRadiusDefault) / STTouchRadiusDefault;
    return CGAffineTransformMakeScale(scale, scale);
}

@implementation STTouchDisplayView {
  @private
    NSMapTable<UITouch *, UIView *> *_touchViews;
    NSMutableSet<UIView *> *_fadingTouchViews;
}

- (id)initWithFrame:(CGRect)frame {
    if ((self = [super initWithFrame:frame])) {
        [self st_initialize];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder {
    if ((self = [super initWithCoder:coder])) {
        [self st_initialize];
    }
    return self;
}

- (void)st_initialize {
    self.userInteractionEnabled = NO;
    _touchViews = [[NSMapTable alloc] initWithKeyOptions:NSPointerFunctionsStrongMemory
                                            valueOptions:NSPointerFunctionsStrongMemory
                                                capacity:0];
    _fadingTouchViews = [[NSMutableSet alloc] init];
}

- (void)didMoveToWindow {
    [super didMoveToWindow];

    for (UIView *view in _touchViews.objectEnumerator) {
        [view removeFromSuperview];
    }
    for (UIView *view in _fadingTouchViews) {
        [view removeFromSuperview];
    }
    [_touchViews removeAllObjects];
    [_fadingTouchViews removeAllObjects];
}

- (void)updateWithEvent:(UIEvent *)event {
    if (event.type != UIEventTypeTouches || !self.window) {
        return;
    }

    NSSet<UITouch *> *const windowTouches = [event touchesForWindow:self.window];
    if (windowTouches.count == 0) {
        return;
    }

    NSMutableSet<UITouch *> *const existingTouches = self.st_knownTouches.mutableCopy;

    for (UITouch *touch in windowTouches) {
        switch (touch.phase) {
        case UITouchPhaseBegan:
        case UITouchPhaseMoved:
        case UITouchPhaseStationary:
            break;
        case UITouchPhaseCancelled:
        case UITouchPhaseEnded:
        default:
            continue;
        }
        UIView *touchView = [self st_viewForTouch:touch];
        if (touchView) {
            [existingTouches removeObject:touch];
        } else {
            UIImageView *const view = [[UIImageView alloc] initWithFrame:(CGRect){.size = {.width = 38, .height = 38}}];
            view.image = STTouchDisplayImage;
            [self st_setView:view forTouch:touch];
            touchView = view;
        }

        touchView.center = [touch locationInView:self];

        touchView.transform = STTouchViewTransformForRadius(touch.majorRadius);
    }

    for (UITouch *touch in existingTouches) {
        [self st_setView:nil forTouch:touch];
    }
}

- (NSSet<UITouch *> *)st_knownTouches {
    NSMutableSet *const knownTouches = [[NSMutableSet alloc] init];
    NSMapTable<UITouch *, UIView *> *const touchViews = _touchViews;
    for (UITouch *touch in touchViews) {
        [knownTouches addObject:touch];
    }
    return knownTouches.copy;
}

- (UIView *)st_viewForTouch:(UITouch *)touch {
    NSMapTable<UITouch *, UIView *> *const touchViews = _touchViews;
    UIView *const view = [touchViews objectForKey:touch];
    return view;
}

- (void)st_setView:(UIView *)view forTouch:(UITouch *)touch {
    NSMapTable<UITouch *, UIView *> *const touchViews = _touchViews;

    if (view) {
        view.center = [touch locationInView:self];
        [touchViews setObject:view forKey:touch];
        [self addSubview:view];
    } else {
        UIView *const existingView = [touchViews objectForKey:touch];
        CGAffineTransform const existingTransform = existingView.transform;
        [touchViews removeObjectForKey:touch];
        [_fadingTouchViews addObject:existingView];
        [UIView animateWithDuration:.25
            delay:0
            options:UIViewAnimationOptionAllowUserInteraction | UIViewAnimationOptionCurveEaseIn
            animations:^{
              existingView.alpha = 0;
              existingView.transform = CGAffineTransformScale(existingTransform, 2, 2);
            }
            completion:^(BOOL finished) {
              [existingView removeFromSuperview];
              [self->_fadingTouchViews removeObject:existingView];
            }];
    }
}

@end
