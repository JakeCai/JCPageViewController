//
//  UIViewController+ChildController.m
//  JCLightWeibo
//
//  Created by Jake on 18/04/2017.
//  Copyright © 2017 Jake Cai. All rights reserved.
//

#import "UIViewController+ChildController.h"

@implementation UIViewController (ChildController)

-(void)addChildVC:(UIViewController *)viewController
{
    [self addChildViewController:viewController frame:self.view.bounds];
}

- (void)addChildViewController:(UIViewController *)viewController
                        inView:(UIView *)view
                     withFrame:(CGRect)frame
{
    [self addChildViewController:viewController
                setSubViewAction:^(UIViewController *superViewController,
                                   UIViewController *childViewController) {
                    childViewController.view.frame = frame;
        
                    if (![view.subviews containsObject:childViewController.view]) {
                        [view addSubview:childViewController.view];
                    }
                }];
}

- (void)addChildViewController:(UIViewController *)viewController
                         frame:(CGRect)frame
{
    [self addChildViewController:viewController
                setSubViewAction:^(UIViewController *superViewController,
                                   UIViewController *childViewController) {
                    childViewController.view.frame = frame;
                    
                    if (![superViewController.view.subviews containsObject:viewController.view]) {
                        [superViewController.view addSubview:viewController.view];
                    }
                }];
}

- (void)addChildViewController:(UIViewController *)viewController
              setSubViewAction:(void(^)(UIViewController *superViewController,
                                        UIViewController *childViewController))setSubViewAction
{
    BOOL containsVC = [self.childViewControllers containsObject:viewController];
    
    if (!containsVC) {
        [self addChildViewController:viewController];
    }
    
    if (setSubViewAction) {
        setSubViewAction(self , viewController);
    }
    
    if (!containsVC) {
        [viewController didMoveToParentViewController:self];
    }
    
}

- (void)removeFromParentVC
{
    [self willMoveToParentViewController:nil];
    [self.view removeFromSuperview];
    [self removeFromParentViewController];
}

@end
