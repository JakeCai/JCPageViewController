# JCPageViewController
PageViewController for iOS.

A way to replace UIPageViewController, JCPageViewController  support ViewController page transform like UIPageViewController. 

![JCPageViewController ScreenShot](/demo.gif)

## Feature
* Manage childControllers' life cycles.
* Maintain childControllers with cache.
* Solve some problem of UIPageViewController.(Page changing, animation interrupting etc.)
* Support Swift

## GetStart
### Usage
Copy files to your project.

	import "JCPageViewController.h"

	JCPageViewController *vc = [[JCPageViewController alloc] init];
	vc.dataSource = self;
	[vc showPageAtIndex:0 animated:NO];
	[self.navigationController pushViewController:vc animated:YES];
	
	//MARK DataSource
	- (UIViewController *)pageViewController:(JCPageViewController *)pageViewController controllerAtIndex:(int)index
	{	
        return self.controllerArray[index];
	}

	- (int)numberOfControllers:(JCPageViewController *)pageViewController
	{
        return (int)self.controllerArray.count;
	}

### Override and Protocol
JCPageViewController provide some APIs to override.

About override the class, you can refer file 'JCTabPageViewController'

	#pragma mark - override
	- (void)pageViewControllerWillShowFromIndex:(int)fromIndex toIndex:(int)toIndex animated:(BOOL)animated;

	- (void)pageViewControllerDidShowFromIndex:(int)fromIndex toIndex:(int)toIndex finished:(BOOL)finished;

The usage of protocol is similar to override's usage.
