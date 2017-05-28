//
//  JCPageViewController.m
//  JCLightWeibo
//
//  Created by Jake on 18/04/2017.
//  Copyright © 2017 Jake Cai. All rights reserved.
//

#import "JCPageViewController.h"
#import "UIViewController+ChildController.h"

typedef enum {
    JCPageScrollDirectionLeft = 0,
    JCPageScrollDirectionRight = 1,
} JCPageScrollDirection;

@interface JCPageViewController ()<UIScrollViewDelegate,NSCacheDelegate>

@property (nonatomic, assign) int currentPageIndex;
@property (nonatomic, strong) NSCache<NSNumber *, UIViewController *> *memCache;

@property (nonatomic, strong) NSMutableSet<UIViewController *> *childsToClean;

@property (nonatomic, assign) CGFloat originOffset;
@property (nonatomic, assign) int guessToIndex;
@property (nonatomic, assign) int lastSelectedIndex;
@property (nonatomic, assign) BOOL firstWillAppear;
@property (nonatomic, assign) BOOL firstDidAppear;
@property (nonatomic, assign) BOOL firstDidLayoutSubViews;
@property (nonatomic, assign) BOOL firstWillLayoutSubViews;
@property (nonatomic, assign) BOOL isDecelerating;
@end

@implementation JCPageViewController

- (instancetype)init
{
    self = [super init];
    if (self) {
        _currentPageIndex = 0;
        
        _guessToIndex = 0.0;
        _lastSelectedIndex = 0;
        _firstWillAppear = true;
        _firstDidAppear = true;
        _firstDidLayoutSubViews = true;
        _firstWillLayoutSubViews = true;
        _isDecelerating = false;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    
    self.memCache.delegate = self;
    
    [self configScrollView:self.scrollView];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    if (self.firstWillAppear) {
        [self pageViewControllerWillShowFromIndex:self.lastSelectedIndex
                                          toIndex:self.currentPageIndex
                                         animated:NO];
        if ([self.delegate respondsToSelector:@selector(pageViewController:willTransitionToViewControllers:)]) {
            [self.delegate pageViewController:self
                           willTransitionFrom:[self controllerAtIndex:self.lastSelectedIndex]
                             toViewController:[self controllerAtIndex:self.currentPageIndex]];
        }
    }
    [[self controllerAtIndex:self.currentPageIndex] beginAppearanceTransition:YES animated:YES];
}

- (void)viewWillLayoutSubviews
{
    [super viewWillLayoutSubviews];
}

- (void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];
    if (self.firstDidLayoutSubViews) {
        if (self.navigationController) {
            if ([self.navigationController.viewControllers[self.navigationController.viewControllers.count - 1] isKindOfClass:[self class]]) {
                self.scrollView.contentOffset = CGPointZero;
                self.scrollView.contentInset = UIEdgeInsetsZero;
            }
        }
        [self updateScrollViewLayoutIfNeeded];
        [self updateScrollViewDisplayIndexIfNeeded];

        self.firstDidLayoutSubViews = NO;
    }else{
            [self updateScrollViewLayoutIfNeeded];
    }
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    if (self.firstDidAppear) {
        [self pageViewControllerDidShowFromIndex:self.lastSelectedIndex
                                         toIndex:self.currentPageIndex
                                        finished:YES];
        self.firstDidAppear = NO;
    }
    [[self controllerAtIndex:self.currentPageIndex] endAppearanceTransition];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    [[self controllerAtIndex:self.currentPageIndex] beginAppearanceTransition:NO animated:YES];
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    
    [[self controllerAtIndex:self.currentPageIndex] endAppearanceTransition];
}

- (void)configScrollView:(UIScrollView *)scrollView
{
    scrollView.translatesAutoresizingMaskIntoConstraints = false;
    scrollView.delegate = self;
    scrollView.showsHorizontalScrollIndicator = false;
    scrollView.showsVerticalScrollIndicator = false;
    [scrollView setPagingEnabled:YES];
    scrollView.backgroundColor = [UIColor clearColor];
    scrollView.scrollsToTop = false;
    scrollView.frame = self.view.bounds;
    [self.view addSubview:scrollView];
    
}

- (UIViewController *)controllerAtIndex:(int)index
{
    return [self.dataSource pageViewController:self controllerAtIndex:index];
}

- (void)showPageAtIndex:(int)index animated:(BOOL)animated
{
    if (index < 0 || index >= self.pageCount) {
        return;
    }
    
    int oldSelectedIndex = self.lastSelectedIndex;
    self.lastSelectedIndex = self.currentPageIndex;
    self.currentPageIndex = index;
    
    if (self.scrollView.frame.size.width > 0.0 && self.scrollView.contentSize.width > 0.0){
        [self pageViewControllerWillShowFromIndex:self.lastSelectedIndex
                                          toIndex:self.currentPageIndex
                                         animated:animated];
        if ([self.delegate respondsToSelector:@selector(pageViewController:willTransitionToViewControllers:)]) {
            [self.delegate pageViewController:self
                           willTransitionFrom:[self controllerAtIndex:self.lastSelectedIndex]
                             toViewController:[self controllerAtIndex:self.currentPageIndex]];
        }
        [self addVisibleViewContorllerWith:index];
        
        [self scrollBeginAnimation:animated];
        
        if (animated) {
            if (self.lastSelectedIndex != self.currentPageIndex) {
                CGSize pageSize = self.scrollView.frame.size;
                JCPageScrollDirection direction = (self.lastSelectedIndex < self.currentPageIndex) ? JCPageScrollDirectionRight : JCPageScrollDirectionLeft;
                UIView *lastView = [self controllerAtIndex:self.lastSelectedIndex].view;
                UIView *currentView = [self controllerAtIndex:self.currentPageIndex].view;
                UIView *oldSelectView = [self controllerAtIndex:oldSelectedIndex].view;
                CGFloat duration = 0.3;
                int backgroundIndex = [self calcIndexWithOffset:self.scrollView.contentOffset.x
                                                          width:self.scrollView.frame.size.width];
                UIView *backgroundView;
                
                if (oldSelectView.layer.animationKeys.count > 0 && lastView.layer.animationKeys.count > 0) {
                    UIView *tmpView = [self controllerAtIndex:backgroundIndex].view;
                    if (tmpView != currentView && tmpView != lastView) {
                        backgroundView = tmpView;
                        backgroundView.hidden = YES;
                    }
                }
                
                [self.scrollView.layer removeAllAnimations];
                [oldSelectView.layer removeAllAnimations];
                [lastView.layer removeAllAnimations];
                [currentView.layer removeAllAnimations];
                
                [self moveBackToOriginPositionIfNeeded:oldSelectView index:oldSelectedIndex];
                
                [self.scrollView bringSubviewToFront:lastView];
                [self.scrollView bringSubviewToFront:currentView];
                lastView.hidden = NO;
                currentView.hidden = NO;
                
                CGPoint lastView_StartOrigin = lastView.frame.origin;
                CGPoint currentView_StartOrigin = lastView.frame.origin;
                if (direction == JCPageScrollDirectionRight) {
                    currentView_StartOrigin.x += self.scrollView.frame.size.width;
                }else{
                    currentView_StartOrigin.x -= self.scrollView.frame.size.width;
                }
                
                CGPoint lastView_AnimateToOrigin = lastView.frame.origin;
                if (direction == JCPageScrollDirectionRight) {
                    lastView_AnimateToOrigin.x -= self.scrollView.frame.size.width;
                }else{
                    lastView_AnimateToOrigin.x += self.scrollView.frame.size.width;
                }
                CGPoint currentView_AnimateToOrigin = lastView.frame.origin;
                
                CGPoint lastView_EndOrigin = lastView.frame.origin;
                CGPoint currentView_EndOrigin = currentView.frame.origin;
                
                lastView.frame = CGRectMake(lastView_StartOrigin.x, lastView_StartOrigin.y, pageSize.width, pageSize.height);
                currentView.frame = CGRectMake(currentView_StartOrigin.x, currentView_StartOrigin.y, pageSize.width, pageSize.height);
                __weak typeof(self) wself = self;
                [UIView animateWithDuration:duration delay:0.0 options:kNilOptions animations:^{
                    lastView.frame = CGRectMake(lastView_AnimateToOrigin.x, lastView_AnimateToOrigin.y, pageSize.width, pageSize.height);
                    currentView.frame = CGRectMake(currentView_AnimateToOrigin.x, currentView_AnimateToOrigin.y, pageSize.width, pageSize.height);
                } completion:^(BOOL finished) {
                    if (finished) {
                        __strong typeof(wself) sself = wself;
                        lastView.frame = CGRectMake(lastView_EndOrigin.x, lastView_EndOrigin.y, pageSize.width, pageSize.height);
                        currentView.frame = CGRectMake(currentView_EndOrigin.x, currentView_EndOrigin.y, pageSize.width, pageSize.height);
                        backgroundView.hidden = NO;
                        [sself moveBackToOriginPositionIfNeeded:currentView index:sself.currentPageIndex];
                        [sself moveBackToOriginPositionIfNeeded:lastView index:sself.lastSelectedIndex];
                        
                        [sself scrollAnimation:animated];
                        [sself scrollEndAnimation:animated];
                    }
                }];
                
            }else{
                [self scrollAnimation:animated];
                [self scrollEndAnimation:animated];
            }
        }else{
            [self scrollAnimation:animated];
            [self scrollEndAnimation:animated];
        }
    }
    
}

- (void)scrollBeginAnimation:(BOOL)animated
{
    [[self controllerAtIndex:self.currentPageIndex] beginAppearanceTransition:YES animated:animated];
    if (self.currentPageIndex != self.lastSelectedIndex) {
        [[self controllerAtIndex:self.lastSelectedIndex] beginAppearanceTransition:NO animated:animated];
    }
}

- (void)scrollAnimation:(BOOL)animated
{
    [self.scrollView setContentOffset:[self calcOffsetWithIndex:self.currentPageIndex
                                                          width:self.scrollView.frame.size.width
                                                       maxWidth:self.scrollView.contentSize.width] animated:NO];
}

- (void)scrollEndAnimation:(BOOL)animated
{
    [[self controllerAtIndex:self.currentPageIndex] endAppearanceTransition];
    if (self.currentPageIndex != self.lastSelectedIndex) {
        [[self controllerAtIndex:self.lastSelectedIndex] endAppearanceTransition];
    }
    
    [self pageViewControllerDidShowFromIndex:self.lastSelectedIndex
                                     toIndex:self.currentPageIndex
                                    finished:animated];
    
    if ([self.delegate respondsToSelector:@selector(pageViewController:didTransitonFrom:toViewController:)]) {
        [self.delegate pageViewController:self
                         didTransitonFrom:[self controllerAtIndex:self.lastSelectedIndex]
                         toViewController:[self controllerAtIndex:self.currentPageIndex]];
    }
    [self cleanCacheToClean];
}

- (void)moveBackToOriginPositionIfNeeded:(UIView *)view index:(int)index
{
    if (index < 0 || index >= self.pageCount) {
        return;
    }
    if (view == nil) {
        return;
    }
    UIView *destView = view;
    
    CGPoint originPosition = [self calcOffsetWithIndex:index
                                                 width:self.scrollView.frame.size.width
                                              maxWidth:self.scrollView.contentSize.width];
    
    if (destView.frame.origin.x != originPosition.x) {
        destView.frame = (CGRect){originPosition,{destView.frame.size.width, destView.frame.size.height}};
    }
}

- (CGRect)calcVisibleViewControllerFrameWithIndex:(int)index
{
    CGFloat offsetX = 0.0;
    offsetX = index * self.scrollView.frame.size.width;
    
    return CGRectMake(offsetX, 0, self.scrollView.frame.size.width, self.scrollView.frame.size.height);
}

- (void)addVisibleViewContorllerWith:(int)index
{
    if (index < 0 || index > self.pageCount) {
        return;
    }
    
    UIViewController *vc = [self.memCache objectForKey:[NSNumber numberWithInt:index]];
    if (vc == nil) {
        vc = [self controllerAtIndex:index];
    }
    
    CGRect childViewFrame = [self calcVisibleViewControllerFrameWithIndex:index];
    [self addChildViewController:vc
                          inView:self.scrollView
                       withFrame:childViewFrame];
    
    [self.memCache setObject:[self controllerAtIndex:index]
                      forKey:[NSNumber numberWithInt:index]];
}

- (void)updateScrollViewDisplayIndexIfNeeded
{
    if (self.scrollView.frame.size.width > 0.0) {
        [self addVisibleViewContorllerWith:self.currentPageIndex];
        CGPoint newoffset = [self calcOffsetWithIndex:self.currentPageIndex
                                                width:self.scrollView.frame.size.width
                                             maxWidth:self.scrollView.contentSize.width];
        
        if (newoffset.x != self.scrollView.contentOffset.x ||
            newoffset.y != self.scrollView.contentOffset.y) {
            self.scrollView.contentOffset = newoffset;
        }
        [self controllerAtIndex:self.currentPageIndex].view.frame = [self calcVisibleViewControllerFrameWithIndex:self.currentPageIndex];
    }
}

- (void)updateScrollViewLayoutIfNeeded
{
    if (self.scrollView.frame.size.width > 0.0) {
        CGFloat width = self.pageCount * self.scrollView.frame.size.width;
        CGFloat height = self.scrollView.frame.size.height;
        CGSize oldContentSize = self.scrollView.contentSize;
        
        if (width != oldContentSize.width ||
            height != oldContentSize.height) {
            self.scrollView.contentSize = CGSizeMake(width, height);
        }
    }
}

- (CGPoint)calcOffsetWithIndex:(int)index width:(CGFloat)width maxWidth:(CGFloat)maxWidth
{
    CGFloat offsetX = index * width;
    if (offsetX < 0) {
        offsetX = 0;
    }
    
    if (maxWidth > 0.0 && offsetX > maxWidth - width) {
        offsetX = maxWidth - width;
    }
    
    return CGPointMake(offsetX, 0);
}

- (int)calcIndexWithOffset:(CGFloat)offset width:(CGFloat)width
{
    int startIndex = offset / width;
    
    if (startIndex < 0) {
        startIndex = 0;
    }
    return startIndex;
}

#pragma mark - cache

- (void)cleanCacheToClean
{
    UIViewController *currentPage = [self controllerAtIndex:self.currentPageIndex];
    if ([self.childsToClean containsObject:currentPage]) {
        [self.childsToClean removeObject:currentPage];
        [self.memCache setObject:currentPage forKey:[NSNumber numberWithInt:self.currentPageIndex]];
    }
    
    for (UIViewController *vc in self.childsToClean) {
        [vc removeFromParentVC];
    }
    
    [self.childsToClean removeAllObjects];
}

- (void)cache:(NSCache *)cache willEvictObject:(id)obj
{
    if ([obj isKindOfClass:[UIViewController class]]) {
        UIViewController *vc = obj;
        
        if ([self.childViewControllers containsObject:vc]) {
            if (self.scrollView.isDragging == NO &&
                self.scrollView.isTracking == NO &&
                self.scrollView.isDecelerating == NO) {
                UIViewController *lastPage = [self controllerAtIndex:self.lastSelectedIndex];
                UIViewController *currentPage = [self controllerAtIndex:self.currentPageIndex];
                if ([lastPage isEqual:vc] || [currentPage isEqual:vc]) {
                    [self.childsToClean addObject:vc];
                }
                
            }else if (self.scrollView.isDragging == YES){
                [self addCacheToCleanIfNeed:vc midIndex:self.guessToIndex];
            }
            if (self.childsToClean.count > 0) {
                return;
            }
            [vc removeFromParentVC];
        }
    }
}

- (void)addCacheToCleanIfNeed:(UIViewController *)vc midIndex:(int)midIndex
{
    int leftIndex = midIndex - 1;
    int rightIndex = midIndex + 1;
    if (leftIndex < 0) {
        leftIndex = midIndex;
    }
    if (rightIndex > self.pageCount - 1) {
        rightIndex = midIndex;
    }
    
    UIViewController *leftNeighbour;
    UIViewController *midPage;
    UIViewController *rightNeighbour;
    
    if ([self.dataSource respondsToSelector:@selector(pageViewController:controllerAtIndex:)]) {
        leftNeighbour = [self.dataSource pageViewController:self controllerAtIndex:leftIndex];
        midPage = [self.dataSource pageViewController:self controllerAtIndex:midIndex];
        rightNeighbour = [self.dataSource pageViewController:self controllerAtIndex:rightIndex];
    }
    
    if ([leftNeighbour isEqual:vc] || [midPage isEqual:vc] || [rightNeighbour isEqual:vc] ) {
        [self.childsToClean addObject:vc];
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
    [self.memCache removeAllObjects];
}

#pragma mark - scrollview delegate

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    if (scrollView.isTracking &&
        scrollView.isDecelerating) {
        
    }
    
    if (scrollView.isDragging &&
        [scrollView isEqual:self.scrollView]) {
        CGFloat offset = scrollView.contentOffset.x;
        CGFloat width = scrollView.frame.size.width;
        int lastGuessIndex = self.guessToIndex < 0 ? self.currentPageIndex : self.guessToIndex;
        
        if (self.originOffset < offset) {
            self.guessToIndex = ceil(offset / width);
        }else if(self.originOffset > offset){
            self.guessToIndex = floor(offset / width);
        }
        
        int maxCount = self.pageCount;
        
        if ((_guessToIndex != self.currentPageIndex &&
            !self.scrollView.isDecelerating) ||
            self.scrollView.isDecelerating) {
            if (lastGuessIndex != self.guessToIndex &&
                self.guessToIndex >= 0 &&
                self.guessToIndex < maxCount) {
                [self pageViewControllerWillShowFromIndex:self.guessToIndex
                                                  toIndex:self.currentPageIndex
                                                 animated:YES];
                if ([self.delegate respondsToSelector:@selector(pageViewController:willTransitionFrom:toViewController:)]) {
                    [self.delegate pageViewController:self
                                   willTransitionFrom:[self controllerAtIndex:self.guessToIndex]
                                     toViewController:[self controllerAtIndex:self.currentPageIndex]];
                }
                [self addVisibleViewContorllerWith:self.guessToIndex];
                [[self controllerAtIndex:self.guessToIndex] beginAppearanceTransition:YES animated:YES];
                
                if (lastGuessIndex == self.currentPageIndex) {
                    [[self controllerAtIndex:self.currentPageIndex] beginAppearanceTransition:YES animated:YES];
                }
                
                if (lastGuessIndex != self.currentPageIndex &&
                    lastGuessIndex >= 0 &&
                    lastGuessIndex < maxCount) {
                    [[self controllerAtIndex:lastGuessIndex] beginAppearanceTransition:NO animated:YES];
                    [[self controllerAtIndex:lastGuessIndex] endAppearanceTransition];
                }
            }
        }
    }
}

- (void)scrollViewWillBeginDecelerating:(UIScrollView *)scrollView
{
    self.isDecelerating = YES;
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
    [self updatePageViewAfterDragging:scrollView];
}

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView
{
    if (!scrollView.isDecelerating) {
        self.originOffset = scrollView.contentOffset.x;
        self.guessToIndex = self.currentPageIndex;
    }
}

- (void)scrollViewWillEndDragging:(UIScrollView *)scrollView
                     withVelocity:(CGPoint)velocity
              targetContentOffset:(inout CGPoint *)targetContentOffset
{
    if (scrollView.isDecelerating) {
        CGFloat offset = scrollView.contentOffset.x;
        CGFloat width = scrollView.frame.size.width;
        if (velocity.x > 0) {
            self.originOffset = floor(offset / width) * width;
        }else if (velocity.x < 0){
            self.originOffset = ceil(offset / width) * width;
        }
        
    }
    
    // 如果松手时位置，刚好不需要decelerating,则主动调用刷新page
    CGFloat offset = scrollView.contentOffset.x;
    CGFloat scrollViewWidth = scrollView.frame.size.width;
    if ((int)(offset * 100) % (int)(scrollViewWidth * 100) == 0) {
        [self updatePageViewAfterDragging:scrollView];
    }
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate
{
    
}

- (void)scrollViewDidEndScrollingAnimation:(UIScrollView *)scrollView
{
    
}

- (BOOL)shouldAutomaticallyForwardAppearanceMethods
{
    return NO;
}

- (void)updatePageViewAfterDragging:(UIScrollView *)scrollView
{
    int newIndex = [self calcIndexWithOffset:scrollView.contentOffset.x
                                       width:scrollView.frame.size.width];
    int oldIndex = self.currentPageIndex;
    self.currentPageIndex = newIndex;
    
    if (newIndex == oldIndex) {
        if (self.guessToIndex >= 0 &&
            self.guessToIndex < self.pageCount) {
            [[self controllerAtIndex:oldIndex] beginAppearanceTransition:YES animated:YES];
            
            [[self controllerAtIndex:oldIndex] endAppearanceTransition];
            
            [[self controllerAtIndex:self.guessToIndex] beginAppearanceTransition:YES animated:YES];
            
            [[self controllerAtIndex:self.guessToIndex] endAppearanceTransition];
        }
    }else{
        [[self controllerAtIndex:newIndex] endAppearanceTransition];
        [[self controllerAtIndex:oldIndex] endAppearanceTransition];
    }
    
    self.originOffset = scrollView.contentOffset.x;
    self.guessToIndex = self.currentPageIndex;
    
    [self pageViewControllerDidShowFromIndex:self.guessToIndex
                                     toIndex:self.currentPageIndex
                                    finished:YES];
    if ([self.delegate respondsToSelector:@selector(pageViewController:didTransitonFrom:toViewController:)]) {
        [self.delegate pageViewController:self
                         didTransitonFrom:[self controllerAtIndex:self.guessToIndex]
                         toViewController:[self controllerAtIndex:self.currentPageIndex]];
    }
    self.isDecelerating = NO;
    
    [self cleanCacheToClean];
}


#pragma mark - getter and setter
- (int)pageCount
{
    return [self.dataSource numberOfControllers:self];
}

- (NSCache<NSNumber *,UIViewController *> *)memCache
{
    if (_memCache == nil) {
        _memCache = [[NSCache<NSNumber *, UIViewController *> alloc] init];
        _memCache.countLimit = 3;
    }
    return _memCache;
}

- (NSMutableSet<UIViewController *> *)childsToClean
{
    if (_childsToClean == nil) {
        _childsToClean = [NSMutableSet<UIViewController *> set];
    }
    return _childsToClean;
}

- (void)setCacheLimit:(int)cacheLimit
{
    self.memCache.countLimit = cacheLimit;
}

- (int)cacheLimit
{
    return (int)self.memCache.countLimit;
}

- (UIScrollView *)scrollView
{
    if (_scrollView == nil) {
        _scrollView = [[UIScrollView alloc] init];
    }
    return _scrollView;
}


#pragma mark - override

- (void)pageViewControllerWillShowFromIndex:(int)fromIndex toIndex:(int)toIndex animated:(BOOL)animated{ }

- (void)pageViewControllerDidShowFromIndex:(int)fromIndex toIndex:(int)toIndex finished:(BOOL)finished{ }

@end
