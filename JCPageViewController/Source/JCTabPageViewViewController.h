//
//  JCTabPageViewViewController.h
//  JCLightWeibo
//
//  Created by Jake on 18/04/2017.
//  Copyright © 2017 Jake Cai. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "JCPageViewController.h"

@interface JCTabPageViewViewController : JCPageViewController

@property (nonatomic, strong) NSArray<NSString *> *pageTitles;

@property (nonatomic, assign) CGFloat segmentHeight;

+ (instancetype)ViewControllerWithPageTitles:(NSArray<NSString *> *)pageTitles;
@end
