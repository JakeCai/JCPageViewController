//
//  UIViewController+ChildController.h
//  JCLightWeibo
//
//  Created by Jake on 18/04/2017.
//  Copyright © 2017 Jake Cai. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIViewController (ChildController)

-(void)addChildVC:(UIViewController *)viewController;

- (void)addChildViewController:(UIViewController *)viewController
                        inView:(UIView *)view
                     withFrame:(CGRect)frame;

- (void)addChildViewController:(UIViewController *)viewController
                         frame:(CGRect)frame;

- (void)addChildViewController:(UIViewController *)viewController
              setSubViewAction:(void(^)(UIViewController *superViewController,
                                        UIViewController *childViewController))setSubViewAction;

- (void)removeFromParentVC;

@end
