//
//  ViewController.m
//  JCPageViewController
//
//  Created by Jake on 2018/7/10.
//  Copyright © 2018 Jake. All rights reserved.
//

#import "ViewController.h"
#import "PageTestViewController.h"
#import "JCTabPageViewViewController.h"
#import "CustomPageViewController.h"

@interface ViewController ()<JCPageViewControllerDataSource>

@property (nonatomic, strong) NSMutableArray<UIViewController *> *controllerArray;
@property (nonatomic, strong) NSMutableArray<NSString *> *titles;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if(indexPath.row == 0){
        JCTabPageViewViewController *tabVC = [JCTabPageViewViewController ViewControllerWithPageTitles:self.titles];
        tabVC.dataSource = self;
        [self.navigationController pushViewController:tabVC animated:YES];
    }else{
        CustomPageViewController *vc = [CustomPageViewController ViewControllerWithPageTitles:self.titles pageControllers:self.controllerArray];
        [self.navigationController pushViewController:vc animated:YES];
    }
}

- (int)numberOfControllers:(JCPageViewController *)pageViewController
{
    return (int)self.controllerArray.count;
}


- (UIViewController *)pageViewController:(JCPageViewController *)pageViewController controllerAtIndex:(int)index
{
    return self.controllerArray[index];
}

- (NSMutableArray<UIViewController *> *)controllerArray
{
    if (_controllerArray == nil) {
        _controllerArray = [NSMutableArray<UIViewController *> array];
        for (int i=0; i<20; i++) {
            PageTestViewController *tabVc = [[PageTestViewController alloc] init];
            tabVc.pageIndex = i;
            tabVc.view.backgroundColor = [UIColor colorWithRed:0.2 * ((i + 1) % 2) green:0.2 * ((i + 1)  % 3) blue:0.2 * ((i + 1)  % 5) alpha:1];
            
            UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(100, 100, 100, 100)];
            label.backgroundColor = [UIColor grayColor];
            label.text = [NSString stringWithFormat:@"tab %d",i];
            label.textAlignment = NSTextAlignmentCenter;
            [tabVc.view addSubview:label];
            [_controllerArray addObject:tabVc];
        }
    }
    return _controllerArray;
}

- (NSMutableArray<NSString *> *)titles
{
    if (_titles == nil) {
        _titles = [NSMutableArray<NSString *> array];
        for (int i=0; i<self.controllerArray.count; i++) {
            NSString *title = [NSString stringWithFormat:@"Tab%d",i];
            [_titles addObject:title];
        }
    }
    return _titles;
}

@end
