// SPDX-License-Identifier: MIT

#import "DemoViewController.h"

@implementation DemoViewController {
    UILabel *_touchStatusLabel;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = UIColor.systemBackgroundColor;

    UIButton *button = [UIButton buttonWithType:UIButtonTypeSystem];
    [button setTitle:@"Tap" forState:UIControlStateNormal];
    button.accessibilityIdentifier = @"touch-target";
    [button addTarget:self action:@selector(buttonTapped:) forControlEvents:UIControlEventTouchUpInside];

    UILabel *instructions = [[UILabel alloc] init];
    instructions.text = @"Tap the button or drag to show touch markers";
    instructions.textAlignment = NSTextAlignmentCenter;
    instructions.numberOfLines = 0;

    _touchStatusLabel = [[UILabel alloc] init];
    _touchStatusLabel.text = @"Waiting for touch";
    _touchStatusLabel.accessibilityIdentifier = @"touch-status";

    UIStackView *stack = [[UIStackView alloc] initWithArrangedSubviews:@[ instructions, button, _touchStatusLabel ]];
    stack.axis = UILayoutConstraintAxisVertical;
    stack.alignment = UIStackViewAlignmentCenter;
    stack.spacing = 24;
    stack.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:stack];
    [NSLayoutConstraint activateConstraints:@[
        [stack.centerXAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.centerXAnchor],
        [stack.centerYAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.centerYAnchor],
        [stack.leadingAnchor constraintGreaterThanOrEqualToAnchor:self.view.safeAreaLayoutGuide.leadingAnchor
                                                         constant:20],
        [stack.trailingAnchor constraintLessThanOrEqualToAnchor:self.view.safeAreaLayoutGuide.trailingAnchor
                                                       constant:-20],
    ]];
}

- (void)buttonTapped:(UIButton *)sender {
    [sender setTitle:@"Tapped" forState:UIControlStateNormal];
}

- (void)setTouchStatus:(NSString *)status {
    _touchStatusLabel.text = status;
}

@end
