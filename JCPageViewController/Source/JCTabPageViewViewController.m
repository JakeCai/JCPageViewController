//
//  JCTabPageViewViewController.m
//  JCLightWeibo
//
//  Created by Jake on 18/04/2017.
//  Copyright © 2017 Jake Cai. All rights reserved.
//

#import "JCTabPageViewViewController.h"
#import "HMSegmentedControl.h"
#import "Masonry.h"

@interface JCTabPageViewViewController ()
@property (nonatomic, strong) HMSegmentedControl *segmentedControl;
@end

@implementation JCTabPageViewViewController

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.segmentHeight = 44.0;
    }
    return self;
}

+ (instancetype)ViewControllerWithPageTitles:(NSArray<NSString *> *)pageTitles
{
    JCTabPageViewViewController *vc = [[JCTabPageViewViewController alloc] init];
    vc.pageTitles = pageTitles;
    if (vc.pageTitles.count > 1) {
        vc.segmentedControl = [[HMSegmentedControl alloc] initWithSectionTitles:vc.pageTitles];
        [vc setupSegmentedControl:vc.segmentedControl];
    }
    return vc;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    if (self.pageTitles.count == self.pageCount) {
        if (self.pageTitles.count > 1) {
            [self layoutSegmentedControl:self.segmentedControl];
        }
        [self resetScrollViewLayoutConstraints:self.scrollView];
    }
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
}

- (void)segmentValueChanged:(id)sender
{
    if (self.segmentedControl) {
        [self showPageAtIndex:(int)self.segmentedControl.selectedSegmentIndex animated:YES];
    }
}

- (void)resetScrollViewLayoutConstraints:(UIScrollView *)scrollView
{
    [scrollView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.segmentedControl.mas_bottom);
        make.bottom.equalTo(self.mas_bottomLayoutGuideTop);
        make.leading.equalTo(self.view.mas_leading);
        make.trailing.equalTo(self.view.mas_trailing);
    }];
    
    [self.view updateConstraints];
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
            make.height.equalTo(@(self.segmentHeight));
        }];
        [self.view updateConstraints];
    }
}

- (void)setSegmentHeight:(CGFloat)segmentHeight
{
    _segmentHeight = segmentHeight;
    [self.segmentedControl mas_updateConstraints:^(MASConstraintMaker *make) {
        make.height.equalTo(@(segmentHeight));
    }];
}

- (void)pageViewControllerDidShowFromIndex:(int)fromIndex toIndex:(int)toIndex finished:(BOOL)finished
{
    [super pageViewControllerDidShowFromIndex:fromIndex toIndex:toIndex finished:finished];
    [self.segmentedControl setSelectedSegmentIndex:toIndex animated:YES];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
