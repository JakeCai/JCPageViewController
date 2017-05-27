//
//  JCPageViewController.h
//  JCLightWeibo
//
//  Created by Jake on 18/04/2017.
//  Copyright © 2017 Jake Cai. All rights reserved.
//

#import <UIKit/UIKit.h>

@class JCPageViewController;

@protocol JCPageViewControllerDataSource <NSObject>

@required
- (UIViewController *)pageViewController:(JCPageViewController *)pageViewController
                       controllerAtIndex:(int)index;

- (int)numberOfControllers:(JCPageViewController *)pageViewController;

@end

@protocol JCPageViewControllerDelegate <NSObject>

@optional
- (void)pageViewController:(JCPageViewController *)pageViewController
        willTransitionFrom:(UIViewController *)fromVC
          toViewController:(UIViewController *)toVC;

- (void)pageViewController:(JCPageViewController *)pageViewController
        didTransitonFrom:(UIViewController *)fromVC
          toViewController:(UIViewController *)toVC;

@end

@interface JCPageViewController : UIViewController

@property (nonatomic, weak) id<JCPageViewControllerDelegate> delegate;

@property (nonatomic, weak) id<JCPageViewControllerDataSource> dataSource;

@property (nonatomic, assign) int pageCount;

@property (nonatomic, assign) int cacheLimit;

@property (nonatomic, strong) UIScrollView *scrollView;

- (void)showPageAtIndex:(int)index animated:(BOOL)animated;

#pragma mark - override

- (void)pageViewControllerWillShowFromIndex:(int)fromIndex toIndex:(int)toIndex animated:(BOOL)animated;

- (void)pageViewControllerDidShowFromIndex:(int)fromIndex toIndex:(int)toIndex finished:(BOOL)finished;

@end
