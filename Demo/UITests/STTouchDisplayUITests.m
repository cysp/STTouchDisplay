// SPDX-License-Identifier: MIT

#import <XCTest/XCTest.h>

@interface STTouchDisplayUITests : XCTestCase
@end

@implementation STTouchDisplayUITests

- (void)testRealWindowTouchShowsAndClearsMarkerWithoutBlockingButton {
    XCUIApplication *app = [[XCUIApplication alloc] init];
    [app launch];

    XCUIElement *button = app.buttons[@"touch-target"];
    XCTAssertTrue([button waitForExistenceWithTimeout:10]);
    [button tap];

    XCTAssertEqualObjects(button.label, @"Tapped");

    XCUIElement *touchStatus = app.staticTexts[@"touch-status"];
    NSPredicate *cleared = [NSPredicate predicateWithFormat:@"label == %@", @"Touch cleared"];
    XCTNSPredicateExpectation *expectation = [[XCTNSPredicateExpectation alloc] initWithPredicate:cleared
                                                                                           object:touchStatus];
    XCTAssertEqual([XCTWaiter waitForExpectations:@[ expectation ] timeout:10], XCTWaiterResultCompleted);
}

@end
