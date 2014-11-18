//  Copyright (c) 2014 Scott Talbot. All rights reserved.

#import "STTouchDisplayView.h"
#import "STTouchDisplayImage.h"


static CGFloat const STTouchPathMajorRadiusDefault = 5;
static CGFloat const STTouchPathMinorRadiusDefault = 5;
static CGFloat const STTouchTwistDefault = 90;


#if __has_include(<STIOHID/STIOHIDEvent.h>)
#include <STIOHID/STIOHIDEvent.h>
#include <STIOHID/STIOHIDEventFunctions.h>

@protocol STUIEvent <NSObject>
@end
@protocol STUIInternalEvent <STUIEvent>
- (STIOHIDEventRef)_hidEvent;
@end
@protocol STUITouch <NSObject>
- (NSUInteger)_pathIndex;
- (NSUInteger)_pathIdentity;
@end

static STIOHIDEventRef STIOHIDEventForUIEvent(UIEvent *event) {
    switch (event.type) {
        case UIEventTypeTouches:
            break;
        case UIEventTypeMotion:
        case UIEventTypeRemoteControl:
            return NULL;
    }

    if ([event respondsToSelector:@selector(_hidEvent)]) {
        return [(id<STUIInternalEvent>)event _hidEvent];
    }

    return NULL;
}

static STIOHIDEventRef STIOHIDDigitizerQualityEventForUIEventAndTouch(UIEvent *event, UITouch *touch) {
    STIOHIDEventRef const her = STIOHIDEventForUIEvent(event);
    if (!her) {
        return NULL;
    }

    struct STIOHIDDigitizerEvent *heb = (struct STIOHIDDigitizerEvent *)her;
    if (heb->base.base.type != STIOHIDEventTypeDigitizer) {
        return NULL;
    }

    NSUInteger const pathIndex = ((id<STUITouch>)touch)._pathIndex;
    NSUInteger const pathIdentity = ((id<STUITouch>)touch)._pathIdentity;

    CFArrayRef const children = heb->base.base.base.children;
    if (!children) {
        return NULL;
    }
    CFIndex const nChildren = CFArrayGetCount(children);
    for (CFIndex i = 0; i < nChildren; ++i) {
        STIOHIDEventRef const child = CFArrayGetValueAtIndex(children, i);
        struct STIOHIDDigitizerQualityEvent const * const cdqe = (struct STIOHIDDigitizerQualityEvent *)child;
        if (cdqe->base.base.base.type != STIOHIDEventTypeDigitizer) {
            continue;
        }
        if (cdqe->base.orientationType != STIOHIDDigitizerOrientationTypeQuality) {
            continue;
        }
        if (cdqe->base.identity != pathIdentity) {
            continue;
        }
        if (cdqe->base.transducerIndex != pathIndex) {
            continue;
        }
        return child;
    }

    return NULL;
}


static CGFloat const STTouchPathMajorRadius(UIEvent *event, UITouch *touch) {
    STIOHIDEventRef const dqer = STIOHIDDigitizerQualityEventForUIEventAndTouch(event, touch);
    if (dqer) {
        struct STIOHIDDigitizerQualityEvent const * const dqe = (struct STIOHIDDigitizerQualityEvent *)dqer;
        return STIOFixedToDouble(dqe->orientation.majorRadius);
    }
    return STTouchPathMajorRadiusDefault;
}

static CGFloat const STTouchPathMinorRadius(UIEvent *event, UITouch *touch) {
    STIOHIDEventRef const dqer = STIOHIDDigitizerQualityEventForUIEventAndTouch(event, touch);
    if (dqer) {
        struct STIOHIDDigitizerQualityEvent const * const dqe = (struct STIOHIDDigitizerQualityEvent *)dqer;
        return STIOFixedToDouble(dqe->orientation.minorRadius);
    }
    return STTouchPathMinorRadiusDefault;
}

static CGFloat const STTouchTwist(UIEvent *event, UITouch *touch) {
    STIOHIDEventRef const dqer = STIOHIDDigitizerQualityEventForUIEventAndTouch(event, touch);
    if (dqer) {
        struct STIOHIDDigitizerQualityEvent const * const dqe = (struct STIOHIDDigitizerQualityEvent *)dqer;
        return STIOFixedToDouble(dqe->base.twist);
    }
    return STTouchTwistDefault;
}

#else

static CGFloat const STTouchPathMajorRadius(UIEvent *event, UITouch *touch) {
    return STTouchPathMajorRadiusDefault;
}

static CGFloat const STTouchPathMinorRadius(UIEvent *event, UITouch *touch) {
    return STTouchPathMinorRadiusDefault;
}

static CGFloat const STTouchTwist(UIEvent *event, UITouch *touch) {
    return STTouchTwistDefault;
}

#endif


static CGAffineTransform STTouchViewTransformForRadiiAndTwist(CGFloat pathMajorRadius, CGFloat pathMinorRadius, CGFloat twist) {
    CGFloat const scaleX = (pathMajorRadius ?: 5) / 5.;
    CGFloat const scaleY = (pathMinorRadius ?: 5) / 5.;
    CGFloat const twistInRadians = M_PI_2 - twist * M_PI / 180.;
    CGAffineTransform transform = CGAffineTransformMakeRotation(twistInRadians);
    transform = CGAffineTransformScale(transform, scaleX, scaleY);
    return transform;
}


@implementation STTouchDisplayView {
@private
    NSMapTable *_touchViews;
}

- (id)initWithFrame:(CGRect)frame {
    if ((self = [super initWithFrame:frame])) {
        self.userInteractionEnabled = NO;

        _touchViews = [[NSMapTable alloc] initWithKeyOptions:NSPointerFunctionsStrongMemory valueOptions:NSPointerFunctionsStrongMemory capacity:0];
    }
    return self;
}

- (void)updateWithEvent:(UIEvent *)event {
    switch (event.type) {
        case UIEventTypeTouches:
            break;
        case UIEventTypeMotion:
        case UIEventTypeRemoteControl:
            return;
    }

    NSMutableSet * const existingTouches = self.st_knownTouches.mutableCopy;

    for (UITouch *touch in event.allTouches) {
        if (!touch.window) {
            continue;
        }
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
            UIImageView * const view = [[UIImageView alloc] initWithFrame:(CGRect){ .size = { .width = 38, .height = 38 } }];
            view.image = STTouchDisplayImage;
            [self st_setView:view forTouch:touch];
            touchView = view;
        }

        touchView.center = [touch locationInView:self];

        CGFloat const touchPathMajorRadius = STTouchPathMajorRadius(event, touch);
        CGFloat const touchPathMinorRadius = STTouchPathMinorRadius(event, touch);
        CGFloat const touchTwist = STTouchTwist(event, touch);
        CGAffineTransform const touchViewTransform = STTouchViewTransformForRadiiAndTwist(touchPathMajorRadius, touchPathMinorRadius, touchTwist);
        touchView.transform = touchViewTransform;
    }

    for (UITouch *touch in existingTouches) {
        [self st_setView:nil forTouch:touch];
    }

    [self setNeedsLayout];
    [self layoutIfNeeded];
}

- (NSSet *)st_knownTouches {
    NSMutableSet * const knownTouches = [[NSMutableSet alloc] init];
    NSMapTable * const touchViews = _touchViews;
    for (UITouch *touch in touchViews) {
        [knownTouches addObject:touch];
    }
    return knownTouches.copy;
}

- (UIView *)st_viewForTouch:(UITouch *)touch {
    NSMapTable * const touchViews = _touchViews;
    UIView * const view = [touchViews objectForKey:touch];
    return view;
}

- (void)st_setView:(UIView *)view forTouch:(UITouch *)touch {
    NSMapTable * const touchViews = _touchViews;

    if (view) {
        view.center = [touch locationInView:self];
        [touchViews setObject:view forKey:touch];
        [self addSubview:view];
    } else {
        UIView * const existingView = [touchViews objectForKey:touch];
        CGAffineTransform const existingTransform = existingView.transform;
        [touchViews removeObjectForKey:touch];
        [UIView animateWithDuration:.25 delay:0 options:UIViewAnimationOptionAllowUserInteraction|UIViewAnimationOptionCurveEaseIn animations:^{
            existingView.alpha = 0;
            existingView.transform = CGAffineTransformScale(existingTransform, 2, 2);
        } completion:^(BOOL finished) {
            [existingView removeFromSuperview];
        }];
    }
}

@end
