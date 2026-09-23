// SPDX-License-Identifier: MIT

#import <STTouchDisplay/STTouchDisplay.h>
#import <XCTest/XCTest.h>

// These doubles supply the UIKit touch and event values consumed by the view.
@interface STFakeTouch : NSObject
@property(nonatomic, strong) UIWindow *window;
@property(nonatomic) UITouchPhase phase;
@property(nonatomic) CGPoint location;
@end

@implementation STFakeTouch
- (CGPoint)locationInView:(UIView *)view {
    return self.location;
}
@end

@interface STFakeEvent : NSObject
@property(nonatomic) UIEventType type;
@property(nonatomic, copy) NSSet<UITouch *> *allTouches;
@end

@implementation STFakeEvent
- (NSSet<UITouch *> *)touchesForWindow:(UIWindow *)window {
    return [self.allTouches objectsPassingTest:^BOOL(UITouch *touch, BOOL *stop) {
      return touch.window == window;
    }];
}
@end

@interface STTouchDisplayTests : XCTestCase
@end

@implementation STTouchDisplayTests

- (void)testDisplayDoesNotInterceptTouches {
    STTouchDisplayView *display = [[STTouchDisplayView alloc] initWithFrame:CGRectMake(0, 0, 100, 100)];

    XCTAssertFalse(display.userInteractionEnabled);
    XCTAssertEqual(display.subviews.count, 0U);
}

- (void)testOwnWindowTouchIsShownAndOtherWindowEventDoesNotClearIt {
    UIWindow *ownWindow = [[UIWindow alloc] initWithFrame:CGRectMake(0, 0, 100, 100)];
    UIWindow *otherWindow = [[UIWindow alloc] initWithFrame:CGRectMake(0, 0, 100, 100)];
    STTouchDisplayView *display = [[STTouchDisplayView alloc] initWithFrame:ownWindow.bounds];
    [ownWindow addSubview:display];

    STFakeTouch *ownTouch = [[STFakeTouch alloc] init];
    ownTouch.window = ownWindow;
    ownTouch.phase = UITouchPhaseBegan;
    ownTouch.location = CGPointMake(40, 50);

    STFakeEvent *ownEvent = [[STFakeEvent alloc] init];
    ownEvent.type = UIEventTypeTouches;
    ownEvent.allTouches = [NSSet setWithObject:(UITouch *)ownTouch];
    [display updateWithEvent:(UIEvent *)ownEvent];

    XCTAssertEqual(display.subviews.count, 1U);
    UIImageView *marker = (UIImageView *)display.subviews.firstObject;
    XCTAssertNotNil(marker.image);
    XCTAssertEqualWithAccuracy(marker.center.x, 40, 0.001);
    XCTAssertEqualWithAccuracy(marker.center.y, 50, 0.001);

    STFakeTouch *otherTouch = [[STFakeTouch alloc] init];
    otherTouch.window = otherWindow;
    otherTouch.phase = UITouchPhaseBegan;
    STFakeEvent *otherEvent = [[STFakeEvent alloc] init];
    otherEvent.type = UIEventTypeTouches;
    otherEvent.allTouches = [NSSet setWithObject:(UITouch *)otherTouch];
    [display updateWithEvent:(UIEvent *)otherEvent];

    XCTAssertEqual(display.subviews.count, 1U);
    XCTAssertIdentical(display.subviews.firstObject, marker);

    STFakeEvent *motionEvent = [[STFakeEvent alloc] init];
    motionEvent.type = UIEventTypeMotion;
    motionEvent.allTouches = [NSSet set];
    [display updateWithEvent:(UIEvent *)motionEvent];

    XCTAssertIdentical(display.subviews.firstObject, marker);
}

- (void)testTouchMovesAndEnds {
    UIWindow *window = [[UIWindow alloc] initWithFrame:CGRectMake(0, 0, 100, 100)];
    STTouchDisplayView *display = [[STTouchDisplayView alloc] initWithFrame:window.bounds];
    [window addSubview:display];

    STFakeTouch *touch = [[STFakeTouch alloc] init];
    touch.window = window;
    touch.phase = UITouchPhaseBegan;
    touch.location = CGPointMake(20, 30);

    STFakeEvent *event = [[STFakeEvent alloc] init];
    event.type = UIEventTypeTouches;
    event.allTouches = [NSSet setWithObject:(UITouch *)touch];
    [display updateWithEvent:(UIEvent *)event];

    UIImageView *marker = (UIImageView *)display.subviews.firstObject;
    XCTAssertNotNil(marker);

    touch.phase = UITouchPhaseMoved;
    touch.location = CGPointMake(70, 80);
    [display updateWithEvent:(UIEvent *)event];

    XCTAssertIdentical(display.subviews.firstObject, marker);
    XCTAssertEqualWithAccuracy(marker.center.x, 70, 0.001);
    XCTAssertEqualWithAccuracy(marker.center.y, 80, 0.001);

    touch.phase = UITouchPhaseEnded;
    [display updateWithEvent:(UIEvent *)event];

    NSPredicate *removed = [NSPredicate predicateWithFormat:@"subviews.@count == 0"];
    XCTNSPredicateExpectation *removal = [[XCTNSPredicateExpectation alloc] initWithPredicate:removed object:display];
    XCTAssertEqual([XCTWaiter waitForExpectations:@[ removal ] timeout:2], XCTWaiterResultCompleted);
}

- (void)testMovingToAnotherWindowClearsMarkers {
    UIWindow *firstWindow = [[UIWindow alloc] initWithFrame:CGRectMake(0, 0, 100, 100)];
    UIWindow *secondWindow = [[UIWindow alloc] initWithFrame:CGRectMake(0, 0, 100, 100)];
    STTouchDisplayView *display = [[STTouchDisplayView alloc] initWithFrame:firstWindow.bounds];
    [firstWindow addSubview:display];

    STFakeTouch *touch = [[STFakeTouch alloc] init];
    touch.window = firstWindow;
    touch.phase = UITouchPhaseBegan;
    touch.location = CGPointMake(20, 30);
    STFakeEvent *event = [[STFakeEvent alloc] init];
    event.type = UIEventTypeTouches;
    event.allTouches = [NSSet setWithObject:(UITouch *)touch];
    [display updateWithEvent:(UIEvent *)event];
    XCTAssertEqual(display.subviews.count, 1U);

    [secondWindow addSubview:display];
    XCTAssertEqual(display.subviews.count, 0U);

    [display updateWithEvent:(UIEvent *)event];
    XCTAssertEqual(display.subviews.count, 0U);
}

- (void)testWindowMoveRemovesFadingMarker {
    UIWindow *firstWindow = [[UIWindow alloc] initWithFrame:CGRectMake(0, 0, 100, 100)];
    UIWindow *secondWindow = [[UIWindow alloc] initWithFrame:CGRectMake(0, 0, 100, 100)];
    STTouchDisplayView *display = [[STTouchDisplayView alloc] initWithFrame:firstWindow.bounds];
    [firstWindow addSubview:display];
    UIView *callerView = [[UIView alloc] initWithFrame:CGRectZero];
    [display addSubview:callerView];

    STFakeTouch *touch = [[STFakeTouch alloc] init];
    touch.window = firstWindow;
    touch.phase = UITouchPhaseBegan;
    touch.location = CGPointMake(20, 30);
    STFakeEvent *event = [[STFakeEvent alloc] init];
    event.type = UIEventTypeTouches;
    event.allTouches = [NSSet setWithObject:(UITouch *)touch];
    [display updateWithEvent:(UIEvent *)event];
    XCTAssertEqual(display.subviews.count, 2U);

    touch.phase = UITouchPhaseEnded;
    [display updateWithEvent:(UIEvent *)event];
    XCTAssertEqual(display.subviews.count, 2U);

    [secondWindow addSubview:display];
    XCTAssertEqual(display.subviews.count, 1U);
    XCTAssertIdentical(display.subviews.firstObject, callerView);
}

@end
