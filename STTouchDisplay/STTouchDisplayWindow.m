//  Copyright (c) 2014 Scott Talbot. All rights reserved.

#import "STTouchDisplayWindow.h"
#import "STTouchDisplayImage.h"


@implementation STTouchDisplayWindow {
@private
    NSMapTable *_touchViews;
}

- (id)initWithFrame:(CGRect)frame {
    if ((self = [super initWithFrame:frame])) {
        self.windowLevel = (UIWindowLevelNormal + UIWindowLevelAlert) / 2.f;
        self.userInteractionEnabled = NO;
        self.hidden = NO;

        _touchViews = [[NSMapTable alloc] initWithKeyOptions:NSPointerFunctionsStrongMemory valueOptions:NSPointerFunctionsStrongMemory capacity:0];
    }
    return self;
}

// this dirty hack is to work around this window, being uppermost, taking control of the status bar style
- (UIViewController *)rootViewController {
    UIApplication * const application = [UIApplication sharedApplication];
    UIWindow * const keyWindow = application.keyWindow;
    return keyWindow.rootViewController;
}

- (void)updateWithTouches:(NSSet *)touches {
    return [self updateWithTouches:touches animated:YES];
}
- (void)updateWithTouches:(NSSet *)touches animated:(BOOL)animated {
    NSMutableSet * const existingTouches = self.st_knownTouches.mutableCopy;

    for (UITouch *touch in touches) {
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
        if ([existingTouches containsObject:touch]) {
            [existingTouches removeObject:touch];
        } else {
            UIImageView * const view = [[UIImageView alloc] initWithFrame:(CGRect){ .size = { .width = 38, .height = 38 } }];
            view.image = STTouchDisplayImage;
            [self st_setView:view forTouch:touch animated:animated];
        }
    }

    for (UITouch *touch in existingTouches) {
        [self st_setView:nil forTouch:touch animated:animated];
    }

    [self setNeedsLayout];
    if (animated) {
        UIViewAnimationOptions const animationOptions = UIViewAnimationOptionAllowUserInteraction;//|UIViewAnimationOptionBeginFromCurrentState;
        [UIView animateWithDuration:1./4. delay:0 options:animationOptions|UIViewAnimationOptionCurveEaseInOut animations:^{
            [self layoutIfNeeded];
        } completion:nil];
    }
}

- (NSSet *)st_knownTouches {
    NSMutableSet * const knownTouches = [[NSMutableSet alloc] init];
    NSMapTable * const touchViews = _touchViews;
    for (UITouch *touch in touchViews) {
        [knownTouches addObject:touch];
    }
    return knownTouches.copy;
}

- (void)st_setView:(UIView *)view forTouch:(UITouch *)touch animated:(BOOL)animated {
    NSMapTable * const touchViews = _touchViews;

    UIViewAnimationOptions const animationOptions = UIViewAnimationOptionAllowUserInteraction;//|UIViewAnimationOptionBeginFromCurrentState;

    if (view) {
        view.alpha = 0;
        view.center = [touch locationInView:self];
        [touchViews setObject:view forKey:touch];

        void (^animations)(void) = ^{
            if (view) {
                view.alpha = 1;
                [self addSubview:view];
            }
        };
        if (animated) {
            [UIView animateWithDuration:1./8. delay:0 options:animationOptions|UIViewAnimationOptionCurveEaseOut animations:^{
                animations();
            } completion:nil];
        } else {
            animations();
        }
    } else {
        UIView * const existingView = [touchViews objectForKey:touch];
        [touchViews removeObjectForKey:touch];

        void (^animations)(void) = ^{
            existingView.alpha = 0;
        };
        void (^completion)(BOOL) = ^(BOOL finished) {
            [existingView removeFromSuperview];
        };
        if (animated) {
            [UIView animateWithDuration:1./4. delay:0 options:animationOptions|UIViewAnimationOptionCurveEaseIn animations:^{
                animations();
            } completion:completion];
        } else {
            animations();
            completion(YES);
        }
    }
}

- (void)layoutSubviews {
    [super layoutSubviews];

    NSMapTable * const touchViews = _touchViews;
    for (UITouch *touch in touchViews) {
        UIView *touchView = [touchViews objectForKey:touch];
        touchView.center = [touch locationInView:self];
    }
}

@end