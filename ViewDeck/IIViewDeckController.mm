//
//  IIViewDeckController.m
//  IIViewDeck
//
//  Copyright (C) 2011-2016, ViewDeck
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy of
//  this software and associated documentation files (the "Software"), to deal in
//  the Software without restriction, including without limitation the rights to
//  use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies
//  of the Software, and to permit persons to whom the Software is furnished to do
//  so, subject to the following conditions:
// 
//  The above copyright notice and this permission notice shall be included in all
//  copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//  SOFTWARE.
//

#import "IIViewDeckController.h"

#import "IISideContainerViewController.h"
#import "IIViewDeckTransitioningDelegate.h"
#import "UIViewController+Private.h"


NS_ASSUME_NONNULL_BEGIN

NSString* NSStringFromIIViewDeckSide(IIViewDeckSide side) {
    switch (side) {
        case IIViewDeckSideLeft:
            return @"left";
            
        case IIViewDeckSideRight:
            return @"right";
            
        default:
            return @"unknown";
    }
}


// View subclasses for easier view debugging:
@interface IIViewDeckView : UIView @end

@implementation IIViewDeckView @end


@interface IIViewDeckController ()

@property (nonatomic) id<UIViewControllerTransitioningDelegate> defaultTransitioningDelegate;

@property (nonatomic, nullable) IISideContainerViewController *leftContainerViewController;
@property (nonatomic, nullable) IISideContainerViewController *rightContainerViewController;

@end


@implementation IIViewDeckController

@synthesize leftContainerViewController = _leftContainerViewController;
@synthesize rightContainerViewController = _rightContainerViewController;

#pragma mark - Object Initialization

- (instancetype)initWithCenterViewController:(UIViewController*)centerViewController {
    return [self initWithCenterViewController:centerViewController leftViewController:nil rightViewController:nil];
}

- (instancetype)initWithCenterViewController:(UIViewController*)centerViewController leftViewController:(nullable UIViewController*)leftViewController {
    return [self initWithCenterViewController:centerViewController leftViewController:leftViewController rightViewController:nil];
}

- (instancetype)initWithCenterViewController:(UIViewController*)centerViewController rightViewController:(nullable UIViewController*)rightViewController {
    return [self initWithCenterViewController:centerViewController leftViewController:nil rightViewController:rightViewController];
}

- (instancetype)initWithCenterViewController:(UIViewController*)centerViewController leftViewController:(nullable UIViewController*)leftViewController rightViewController:(nullable UIViewController*)rightViewController {
    self = [super initWithNibName:nil bundle:nil];
    if (self) {
        NSParameterAssert(centerViewController);

        _defaultTransitioningDelegate = [[IIViewDeckTransitioningDelegate alloc] initWithViewDeckController:self];

        // Trigger the setter as they keep track of the view controller hierarchy!
        self.centerViewController = centerViewController;
        self.leftViewController = leftViewController;
        self.rightViewController = rightViewController;
    }
    return self;
}

- (BOOL)definesPresentationContext {
    return YES;
}



#pragma mark - View Lifecycle

- (void)loadView {
    CGRect screenFrame = UIScreen.mainScreen.bounds;
    self.view = [[IIViewDeckView alloc] initWithFrame:screenFrame];
}

- (void)viewDidLoad {
    [super viewDidLoad];

    [self ii_exchangeViewFromController:nil toController:self.centerViewController inContainerView:self.view];
}



#pragma mark - Child Controller Lifecycle

- (void)setCenterViewController:(UIViewController *)centerViewController {
    if (_centerViewController && _centerViewController == centerViewController) {
        return;
    }
    
    UIViewController *oldViewController = _centerViewController;
    _centerViewController = centerViewController;

    [self ii_exchangeViewController:oldViewController withViewController:centerViewController viewTransition:^{
        [self ii_exchangeViewFromController:oldViewController toController:centerViewController inContainerView:self.view];
    }];
    
    [self setNeedsStatusBarAppearanceUpdate];
    
    // TODO: Start monitoring tab bar items here...
}

- (void)setLeftViewController:(nullable UIViewController *)leftViewController {
    if (_leftViewController && _leftViewController == leftViewController) {
        return;
    }
    NSAssert(_leftViewController == nil || _leftViewController.presentingViewController == nil, @"You can not exchange a side view controller while it is being presented.");
    _leftViewController = leftViewController;

    IISideContainerViewController *container;
    if (leftViewController) {
        container = [[IISideContainerViewController alloc] initWithViewController:leftViewController viewDeckController:self];
        container.transitioningDelegate = self.defaultTransitioningDelegate;
    }
    self.leftContainerViewController = container;
}

- (void)setLeftContainerViewController:(nullable IISideContainerViewController *)leftContainerViewController {
    NSAssert(_leftContainerViewController.presentingViewController == nil, @"You can not exchange a side view controller while it is being presented.");
    _leftContainerViewController = leftContainerViewController;
}

- (void)setRightViewController:(nullable UIViewController *)rightViewController {
    if (_rightViewController && _rightViewController == rightViewController) {
        return;
    }
    NSAssert(_rightViewController == nil || _rightViewController.presentingViewController == nil, @"You can not exchange a side view controller while it is being presented.");
    _rightViewController = rightViewController;

    IISideContainerViewController *container;
    if (rightViewController) {
        container = [[IISideContainerViewController alloc] initWithViewController:rightViewController viewDeckController:self];
        container.transitioningDelegate = self.defaultTransitioningDelegate;
    }
    self.rightContainerViewController = container;
}

- (void)setRightContainerViewController:(nullable IISideContainerViewController *)rightContainerViewController {
    NSAssert(_rightContainerViewController.presentingViewController == nil, @"You can not exchange a side view controller while it is being presented.");
    _rightContainerViewController = rightContainerViewController;
}



#pragma mark - Side State

static inline BOOL IIIsAllowedTransition(IIViewDeckSide fromSide, IIViewDeckSide toSide) {
    return (IIViewDeckSideIsValid(fromSide) && !IIViewDeckSideIsValid(toSide)) || (!IIViewDeckSideIsValid(fromSide) && IIViewDeckSideIsValid(toSide));
}

- (void)setOpenSide:(IIViewDeckSide)openSide {
    [self openSide:openSide animated:NO];
}

- (void)openSide:(IIViewDeckSide)side animated:(BOOL)animated {
    [self openSide:side animated:animated completion:NULL];
}

// could be made public if needed, but for now: Keep the interface as small as possible.
- (void)openSide:(IIViewDeckSide)side animated:(BOOL)animated completion:(nullable void(^)(void))completion {
    if (side == _openSide) {
        return;
    }
    NSAssert(IIIsAllowedTransition(_openSide, side), @"Open and close transitions are only allowed between a side and the center. You can not transition straight from one side to another side.");
    _openSide = side;
    switch (side) {
        case IIViewDeckSideNone:
            [self dismissViewControllerAnimated:animated completion:completion];
            break;
        case IIViewDeckSideLeft:
            [self presentViewController:self.leftContainerViewController animated:animated completion:completion];
            break;
        case IIViewDeckSideRight:
            [self presentViewController:self.rightContainerViewController animated:animated completion:completion];
            break;
    }
}

- (void)closeSide:(BOOL)animated {
    [self closeSide:animated completion:NULL];
}

// could be made public if needed, but for now: Keep the interface as small as possible.
- (void)closeSide:(BOOL)animated completion:(nullable void(^)(void))completion {
    [self openSide:IIViewDeckSideNone animated:animated completion:completion];
}

@end

NS_ASSUME_NONNULL_END
