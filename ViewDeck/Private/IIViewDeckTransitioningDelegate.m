//
//  IIViewDeckTransitioningDelegate.m
//  Pods
//
//  Copyright (C) 2016, ViewDeck
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

#import "IIViewDeckTransitioningDelegate.h"

#import "IIEnvironment.h"
#import "IIViewDeckAnimatedTransition.h"
#import "IIViewDeckController.h"
#import "IIViewDeckPresentationController.h"
#import "IISideContainerViewController.h"


NS_ASSUME_NONNULL_BEGIN


@interface IIViewDeckTransitioningDelegate ()

@property (nonatomic, assign) IIViewDeckController *viewDeckController; // this is not weak as it is a required link! If the corresponding view deck controller will be removed, this class can no longer fullfill its purpose!

@end


@implementation IIViewDeckTransitioningDelegate

- (instancetype)init {
    NSAssert(NO, @"Please use initWithViewDeckController: instead.");
    return self;
}

- (instancetype)initWithViewDeckController:(IIViewDeckController *)viewDeckController {
    NSParameterAssert(viewDeckController);
    self = [super init];

    _viewDeckController = viewDeckController;

    return self;
}

- (nullable id <UIViewControllerAnimatedTransitioning>)animationControllerForPresentedController:(UIViewController *)presented presentingController:(UIViewController *)presenting sourceController:(UIViewController *)source {
    IIViewDeckController *viewDeckController = self.viewDeckController;
    NSParameterAssert(presenting == viewDeckController);
    NSParameterAssert([presented isKindOfClass:[IISideContainerViewController class]]);
    IISideContainerViewController *container = (IISideContainerViewController *)presented;
    NSParameterAssert(container.innerViewController == viewDeckController.leftViewController || container.innerViewController == viewDeckController.rightViewController);

    IIViewDeckSide side = container.side;
    IIViewDeckAnimatedTransition *transition = [[IIViewDeckAnimatedTransition alloc] initWithTypeAppearing:YES];
    return transition;
}

- (nullable id <UIViewControllerAnimatedTransitioning>)animationControllerForDismissedController:(UIViewController *)dismissed {
    IIViewDeckController *viewDeckController = self.viewDeckController;
    NSParameterAssert(dismissed.presentingViewController == viewDeckController);
    NSParameterAssert([dismissed isKindOfClass:[IISideContainerViewController class]]);
    IISideContainerViewController *container = (IISideContainerViewController *)dismissed;
    NSParameterAssert(container.innerViewController == viewDeckController.leftViewController || container.innerViewController == viewDeckController.rightViewController);

    IIViewDeckSide side = container.side;
    IIViewDeckAnimatedTransition *transition = [[IIViewDeckAnimatedTransition alloc] initWithTypeAppearing:NO];
    return transition;
}

//- (nullable id <UIViewControllerInteractiveTransitioning>)interactionControllerForPresentation:(id <UIViewControllerAnimatedTransitioning>)animator;

//- (nullable id <UIViewControllerInteractiveTransitioning>)interactionControllerForDismissal:(id <UIViewControllerAnimatedTransitioning>)animator;

- (nullable UIPresentationController *)presentationControllerForPresentedViewController:(UIViewController *)presented presentingViewController:(/*nullable*/ UIViewController *)presenting sourceViewController:(UIViewController *)source {
    IIViewDeckController *viewDeckController = self.viewDeckController;
    NSParameterAssert([presented isKindOfClass:[IISideContainerViewController class]]);
    NSParameterAssert(source == viewDeckController);
    IISideContainerViewController *container = (IISideContainerViewController *)presented;
    NSParameterAssert(container.innerViewController == viewDeckController.leftViewController || container.innerViewController == viewDeckController.rightViewController);

    IIViewDeckPresentationController *presentationController = [[IIViewDeckPresentationController alloc] initWithPresentedViewController:presented presentingViewController:presenting];
    return presentationController;
}

@end


NS_ASSUME_NONNULL_END
