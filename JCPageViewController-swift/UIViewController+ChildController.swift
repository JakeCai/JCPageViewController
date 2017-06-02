//
//  UIViewController+ChildController.swift
//  JCPhotoBrowser-Swift
//
//  Created by Jake on 31/05/2017.
//  Copyright © 2017 Jake. All rights reserved.
//
import UIKit

extension UIViewController {
    func addChildVC(_ viewController:UIViewController) {
        self.addChildViewController(viewController,frame: self.view.bounds)
    }
    
    func addChildViewController(_ viewController:UIViewController,inView:UIView,withFrame:CGRect) {
        self.addChildViewController(viewController) { (superViewController,childViewController) in
            childViewController.view.frame = withFrame;
            
            if inView.subviews.contains(viewController.view) == false {
                inView.addSubview(viewController.view)
            }
        }
    }
    
    func addChildViewController(_ viewController:UIViewController,frame:CGRect) {
        self.addChildViewController(viewController) { (superViewController,childViewController) in
            childViewController.view.frame = frame;
            
            if superViewController.view.subviews.contains(viewController.view) == false {
                superViewController.view.addSubview(viewController.view)
            }
        }
    }
    
    func addChildViewController(_ viewController:UIViewController,
                                   setSubViewAction:((_ superViewController:UIViewController,_ childViewController:UIViewController) -> Void)?) {
        
        let containsVC = self.childViewControllers.contains(viewController)
        
        if containsVC == false {
            self.addChildViewController(viewController)
        }
        
        setSubViewAction?(self,viewController)
        
        if containsVC == false {
            viewController.didMove(toParentViewController: self)
        }
    }
    
    func removeFromParentVC() {
        self.willMove(toParentViewController: nil)
        self.view.removeFromSuperview()
        self.removeFromParentViewController()
    }
}
