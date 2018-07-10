//
//  CustomPageViewController.m
//  MyGraduationProject
//
//  Created by Jake on 27/05/2017.
//  Copyright © 2017 Jake. All rights reserved.
//

#import "CustomPageViewController.h"
#import "HMSegmentedControl.h"
#import "Masonry.h"

@interface CustomPageViewController ()<UIPageViewControllerDelegate,UIPageViewControllerDataSource>

@property (nonatomic, strong) HMSegmentedControl *segmentedControl;
@property (nonatomic, strong) UIPageViewController *pageViewController;
@property (nonatomic, assign) int selectIndex;
@end

@implementation CustomPageViewController

+ (instancetype)ViewControllerWithPageTitles:(NSArray<NSString *> *)pageTitles
                             pageControllers:(NSArray<UIViewController *> *)controllers
{
    CustomPageViewController *vc = [[CustomPageViewController alloc] init];
    vc.controllers = controllers;
    vc.pageTitles = pageTitles;
    vc.selectIndex = 0;
    if (vc.pageTitles.count > 1) {
        vc.segmentedControl = [[HMSegmentedControl alloc] initWithSectionTitles:vc.pageTitles];
        [vc setupSegmentedControl:vc.segmentedControl];
    }
    return vc;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    // Do any additional setup after loading the view.
    [self layoutSegmentedControl:self.segmentedControl];
    [self addChildViewController:self.pageViewController];
    [self.view addSubview:self.pageViewController.view];
    
    [self.pageViewController.view mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.segmentedControl.mas_bottom);
        make.bottom.equalTo(self.view.mas_bottom);
        make.leading.equalTo(self.view.mas_leading);
        make.trailing.equalTo(self.view.mas_trailing);
        
    }];
    
    [self.view updateConstraints];
    [self.pageViewController didMoveToParentViewController:self];
    [self showViewControllerAtIndex:0];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)segmentValueChanged:(id)sender
{
    if (self.segmentedControl) {
        [self showViewControllerAtIndex:(int)self.segmentedControl.selectedSegmentIndex];
    }
}

- (void)showViewControllerAtIndex:(int)index
{
    UIPageViewControllerNavigationDirection direction = UIPageViewControllerNavigationDirectionReverse;
    if (self.pageViewController.viewControllers.count>0) {
        UIViewController *last = self.pageViewController.viewControllers.lastObject;
        int lastIndex = (int)[self.controllers indexOfObject:last];
        if (lastIndex != NSNotFound) {
            direction = self.selectIndex < index ? UIPageViewControllerNavigationDirectionReverse : UIPageViewControllerNavigationDirectionForward;
        }
    }
    [self.pageViewController setViewControllers:@[self.controllers[index]] direction:direction animated:YES completion:^(BOOL finished) {

    }];
}

- (void)setupSegmentedControl:(HMSegmentedControl *)segmentedControl
{
    if (segmentedControl) {
        segmentedControl.translatesAutoresizingMaskIntoConstraints = NO;
        segmentedControl.selectionIndicatorLocation = HMSegmentedControlSelectionIndicatorLocationDown;
        segmentedControl.selectionIndicatorColor = [UIColor blueColor];
        segmentedControl.selectionIndicatorHeight = 3.0;
        segmentedControl.segmentWidthStyle = HMSegmentedControlSegmentWidthStyleFixed;
        segmentedControl.titleTextAttributes = @{NSFontAttributeName : [UIFont systemFontOfSize:15],
                                                 NSForegroundColorAttributeName : [UIColor grayColor]};
        segmentedControl.selectedTitleTextAttributes = @{NSForegroundColorAttributeName : [UIColor blackColor]};
        segmentedControl.selectionStyle = HMSegmentedControlSelectionStyleFullWidthStripe;
        segmentedControl.backgroundColor = [UIColor whiteColor];
        [segmentedControl addTarget:self action:@selector(segmentValueChanged:) forControlEvents:UIControlEventValueChanged];
    }
}

- (void)layoutSegmentedControl:(HMSegmentedControl *)segmentedControl
{
    if (segmentedControl) {
        [self.view addSubview:segmentedControl];
        [segmentedControl mas_makeConstraints:^(MASConstraintMaker *make) {
            make.leading.equalTo(self.view.mas_leading);
            make.trailing.equalTo(self.view.mas_trailing);
            make.top.equalTo(self.mas_topLayoutGuideBottom);
            make.height.equalTo(@(44.0));
        }];
        [self.view updateConstraints];
    }
}

- (UIPageViewController *)pageViewController
{
    if (_pageViewController == nil) {
        _pageViewController = [[UIPageViewController alloc] initWithTransitionStyle:UIPageViewControllerTransitionStyleScroll
                                                              navigationOrientation:UIPageViewControllerNavigationOrientationHorizontal
                                                                            options:nil];
        _pageViewController.delegate = self;
        _pageViewController.dataSource = self;
    }
    return _pageViewController;
}

- (void)setControllers:(NSArray<UIViewController *> *)controllers
{
    _controllers = controllers;
}

- (UIViewController *)pageViewController:(UIPageViewController *)pageViewController viewControllerAfterViewController:(UIViewController *)viewController
{
    NSUInteger index = [self.controllers indexOfObject:viewController];
    if (index == self.controllers.count - 1 || index == NSNotFound) {
        return nil;
    }else{
        return self.controllers[index+1];
    }
}

- (UIViewController *)pageViewController:(UIPageViewController *)pageViewController viewControllerBeforeViewController:(UIViewController *)viewController
{
    NSUInteger index = [self.controllers indexOfObject:viewController];
    if (index == 0 || index == NSNotFound) {
        return nil;
    }else{
        return self.controllers[index-1];
    }
}

- (void)pageViewController:(UIPageViewController *)pageViewController didFinishAnimating:(BOOL)finished previousViewControllers:(NSArray<UIViewController *> *)previousViewControllers transitionCompleted:(BOOL)completed
{
    self.selectIndex = (int)[self.controllers indexOfObject:pageViewController.viewControllers.lastObject];
    [self.segmentedControl setSelectedSegmentIndex:self.selectIndex animated:YES];
}
@end
