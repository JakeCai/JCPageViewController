//
//  CustomPageViewController.h
//  MyGraduationProject
//
//  Created by Jake on 27/05/2017.
//  Copyright © 2017 Jake. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface CustomPageViewController : UIViewController

@property (nonatomic, strong) NSArray<NSString *> *pageTitles;

@property (nonatomic, strong) NSArray<UIViewController *> *controllers;

+ (instancetype)ViewControllerWithPageTitles:(NSArray<NSString *> *)pageTitles
                             pageControllers:(NSArray<UIViewController *> *)controllers;

@end
