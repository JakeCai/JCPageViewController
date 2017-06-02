//
//  JCPageViewController.swift
//  JCPhotoBrowser-Swift
//
//  Created by Jake on 31/05/2017.
//  Copyright © 2017 Jake. All rights reserved.
//
import UIKit


enum JCPageScrollDirection {
    case left
    case right
}

@objc protocol JCPageViewControllerDataSource {
    func pageViewController(_:JCPageViewController,
                               controllerAtIndex index:Int) -> UIViewController!
    
    func numberOfControllers(_:JCPageViewController) -> Int
}

@objc protocol JCPageViewControllerDelegate {

    @objc optional func pageViewController(_ pageViewController: JCPageViewController,
                                              willTransitonFrom fromVC:UIViewController,
                                              toViewController toVC:UIViewController)

    @objc optional func pageViewController(_ pageViewController: JCPageViewController,
                                              didTransitonFrom fromVC:UIViewController,
                                              toViewController toVC:UIViewController)
}

class JCPageViewController: UIViewController, UIScrollViewDelegate, NSCacheDelegate {
    weak var delegate:JCPageViewControllerDelegate?
    weak var dataSource:JCPageViewControllerDataSource?
    
    fileprivate(set) var scrollView:UIScrollView! = UIScrollView()
    var pageCount:Int {
        get {
            return self.dataSource!.numberOfControllers(self)
        }
    }
    fileprivate(set) var currentPageIndex = 0
    fileprivate lazy var memCache:NSCache<NSNumber, UIViewController> = {
        let cache = NSCache<NSNumber, UIViewController>()
        cache.countLimit = 3
        return cache
    }()
    
    var cacheLimit:Int {
        get {
            return self.memCache.countLimit
        }
        set {
            self.memCache.countLimit = newValue;
        }
    }
    
    fileprivate var childsToClean = Set<UIViewController>()
    
    fileprivate var originOffset = 0.0                  //用于手势拖动scrollView时，判断方向
    fileprivate var guessToIndex = -1                   //用于手势拖动scrollView时，判断要去的页面
    fileprivate var lastSelectedIndex = 0               //用于记录上次选择的index
    fileprivate var firstWillAppear = true              //用于界定页面首次WillAppear。
    fileprivate var firstDidAppear = true               //用于界定页面首次DidAppear。
    fileprivate var firstDidLayoutSubViews = true       //用于界定页面首次DidLayoutsubviews。
    fileprivate var firstWillLayoutSubViews = true      //用于界定页面首次WillLayoutsubviews。
    fileprivate var isDecelerating = false              //正在减速操作
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.view.backgroundColor = UIColor.white
        self.memCache.delegate = self
        
        self.configScrollView(self.scrollView)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if self.firstWillAppear {
            //Config init page
            self.pageViewControllerWillShow(self.lastSelectedIndex, toIndex: self.currentPageIndex, animated: false)
            self.delegate?.pageViewController?(self, willTransitonFrom: self.controllerAtIndex(self.lastSelectedIndex), toViewController: self.controllerAtIndex(self.currentPageIndex))
            self.firstWillAppear = false
        }
        self.controllerAtIndex(self.currentPageIndex).beginAppearanceTransition(true, animated: true)
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        if self.firstDidLayoutSubViews {
            if let navigationController = self.navigationController {
                if navigationController.viewControllers[navigationController.viewControllers.count - 1] == self{
                    self.scrollView.contentOffset = CGPoint.zero;
                    self.scrollView.contentInset = UIEdgeInsets.zero;
                }
            }
            self.updateScrollViewLayoutIfNeeded()
            self.updateScrollViewDisplayIndexIfNeeded()
            self.firstDidLayoutSubViews = false
        } else {
            self.updateScrollViewLayoutIfNeeded()
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if self.firstDidAppear {
            self.pageViewControllerDidShow(self.lastSelectedIndex, toIndex: self.currentPageIndex, finished: true)
            self.delegate?.pageViewController?(self, didTransitonFrom: self.controllerAtIndex(self.lastSelectedIndex), toViewController: self.controllerAtIndex(self.currentPageIndex))
            
            self.firstDidAppear = false
        }
        self.controllerAtIndex(self.currentPageIndex).endAppearanceTransition()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.controllerAtIndex(self.currentPageIndex).beginAppearanceTransition(false, animated: true)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        self.controllerAtIndex(self.currentPageIndex).endAppearanceTransition()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        
        self.memCache.removeAllObjects()
    }
    
    @objc public func showPageAtIndex(_ index:Int,animated:Bool) {
        if index < 0 || index >= self.pageCount {
            return
        }
        let oldSelectedIndex = self.lastSelectedIndex
        self.lastSelectedIndex = self.currentPageIndex
        self.currentPageIndex = index
        
        if self.scrollView.frame.size.width > 0.0 &&
            self.scrollView.contentSize.width > 0.0{
            
            self.pageViewControllerWillShow(self.lastSelectedIndex, toIndex: self.currentPageIndex, animated: animated)
            self.delegate?.pageViewController?(self, willTransitonFrom: self.controllerAtIndex(self.lastSelectedIndex),
                                                  toViewController: self.controllerAtIndex(self.currentPageIndex))
            
            self.addVisibleViewContorllerWith(index)
            
            let scrollBeginAnimation = { () -> Void in
                self.controllerAtIndex(self.currentPageIndex).beginAppearanceTransition(true, animated: animated)
                if self.currentPageIndex != self.lastSelectedIndex {
                    self.controllerAtIndex(self.lastSelectedIndex).beginAppearanceTransition(false, animated: animated)
                }
            }
            let scrollAnimation = { () -> Void in
                self.scrollView.setContentOffset(self.calcOffsetWithIndex(
                    self.currentPageIndex,
                    width:Float(self.scrollView.frame.size.width),
                    maxWidth:Float(self.scrollView.contentSize.width)), animated: false)
            }
            
            // Action closure after simulated scroll animation
            let scrollEndAnimation = { () -> Void in
                self.controllerAtIndex(self.currentPageIndex).endAppearanceTransition()
                if self.currentPageIndex != self.lastSelectedIndex {
                    self.controllerAtIndex(self.lastSelectedIndex).endAppearanceTransition()
                }
                
                self.pageViewControllerDidShow(self.lastSelectedIndex, toIndex: self.currentPageIndex, finished: animated)
                self.delegate?.pageViewController?(self, didTransitonFrom: self.controllerAtIndex(self.lastSelectedIndex),toViewController: self.controllerAtIndex(self.currentPageIndex))
                self.cleanCacheToClean()
            }
            
            scrollBeginAnimation()
            
            if animated {
                if self.lastSelectedIndex != self.currentPageIndex {
                    let pageSize = self.scrollView.frame.size
                    let direction = (self.lastSelectedIndex < self.currentPageIndex) ? JCPageScrollDirection.right : JCPageScrollDirection.left
                    let lastView:UIView = self.controllerAtIndex(self.lastSelectedIndex).view
                    let currentView:UIView = self.controllerAtIndex(self.currentPageIndex).view
                    let oldSelectView:UIView = self.controllerAtIndex(oldSelectedIndex).view
                    let duration = 0.3
                    let backgroundIndex = self.calcIndexWithOffset(Float(self.scrollView.contentOffset.x),
                                                                   width: Float(self.scrollView.frame.size.width))
                    var backgroundView:UIView?
                    
                    if ((oldSelectView.layer.animationKeys()?.count)! > 0 &&
                        (lastView.layer.animationKeys()?.count)! > 0)
                    {
                        let tmpView = self.controllerAtIndex(backgroundIndex).view
                        if tmpView != currentView &&
                            tmpView != lastView
                        {
                            backgroundView = tmpView
                            backgroundView?.isHidden = true
                        }
                    }
                    self.scrollView.layer.removeAllAnimations()
                    oldSelectView.layer.removeAllAnimations()
                    lastView.layer.removeAllAnimations()
                    currentView.layer.removeAllAnimations()
                    
                    self.moveBackToOriginPositionIfNeeded(oldSelectView, index: oldSelectedIndex)
                    
                    self.scrollView.bringSubview(toFront: lastView)
                    self.scrollView.bringSubview(toFront: currentView)
                    lastView.isHidden = false
                    currentView.isHidden = false
                    
                    let lastView_StartOrigin = lastView.frame.origin
                    var currentView_StartOrigin = lastView.frame.origin
                    if direction == .right {
                        currentView_StartOrigin.x += self.scrollView.frame.size.width
                    } else {
                        currentView_StartOrigin.x -= self.scrollView.frame.size.width
                    }
                    
                    var lastView_AnimateToOrigin = lastView.frame.origin
                    if direction == .right {
                        lastView_AnimateToOrigin.x -= self.scrollView.frame.size.width
                    } else {
                        lastView_AnimateToOrigin.x += self.scrollView.frame.size.width
                    }
                    let currentView_AnimateToOrigin = lastView.frame.origin
                    
                    let lastView_EndOrigin = lastView.frame.origin
                    let currentView_EndOrigin = currentView.frame.origin
                    
                    lastView.frame = CGRect(x: lastView_StartOrigin.x, y: lastView_StartOrigin.y, width: pageSize.width, height: pageSize.height)
                    currentView.frame = CGRect(x: currentView_StartOrigin.x, y: currentView_StartOrigin.y, width: pageSize.width, height: pageSize.height)
                    
                    UIView.animate(withDuration: duration,
                                   delay: 0.0,
                                   options: UIViewAnimationOptions(),
                                   animations:
                        {
                            lastView.frame = CGRect(x: lastView_AnimateToOrigin.x, y: lastView_AnimateToOrigin.y, width: pageSize.width, height: pageSize.height)
                            currentView.frame = CGRect(x: currentView_AnimateToOrigin.x, y: currentView_AnimateToOrigin.y, width: pageSize.width, height: pageSize.height)
                        },
                                   completion:
                        { [weak self] (finished) in
                            if finished {
                                lastView.frame = CGRect(x: lastView_EndOrigin.x, y: lastView_EndOrigin.y, width: pageSize.width, height: pageSize.height)
                                currentView.frame = CGRect(x: currentView_EndOrigin.x, y: currentView_EndOrigin.y, width: pageSize.width, height: pageSize.height)
                                backgroundView?.isHidden = false
                                if let weakSelf = self {
                                    weakSelf.moveBackToOriginPositionIfNeeded(currentView, index: weakSelf.currentPageIndex)
                                    weakSelf.moveBackToOriginPositionIfNeeded(lastView, index: weakSelf.lastSelectedIndex)
                                }
                                scrollAnimation()
                                scrollEndAnimation()
                            }
                        }
                    )
                } else {
                    scrollAnimation()
                    scrollEndAnimation()
                }
            } else {
                scrollAnimation()
                scrollEndAnimation()
            }
        }
    }
    
    @objc fileprivate func moveBackToOriginPositionIfNeeded(_ view:UIView?,index:Int)
    {
        if index < 0 || index >= self.pageCount {
            return
        }
        guard let destView = view else {
            return
        }
        let originPosition = self.calcOffsetWithIndex(index,
                                                      width: Float(self.scrollView.frame.size.width),
                                                      maxWidth: Float(self.scrollView.contentSize.width))
        if destView.frame.origin.x != originPosition.x {
            var newFrame = destView.frame
            newFrame.origin = originPosition
            destView.frame = newFrame
        }
    }
    
    @objc fileprivate func calcVisibleViewControllerFrameWith(_ index:Int) -> CGRect {
        var offsetX = 0.0
        offsetX = Double(index) * Double(self.scrollView.frame.size.width)
        return CGRect(x: CGFloat(offsetX), y: 0, width: self.scrollView.frame.size.width, height: self.scrollView.frame.size.height)
    }
    
    @objc fileprivate func addVisibleViewContorllerWith(_ index:Int) {
        if index < 0 || index > self.pageCount {
            return
        }
        
        var vc:UIViewController? = self.memCache.object(forKey: NSNumber(value: index))
        if vc == nil {
            vc = self.controllerAtIndex(index)
        }
        
        let childViewFrame = self.calcVisibleViewControllerFrameWith(index)
        self.addChildViewController(vc!,
                                       inView: self.scrollView,
                                       withFrame: childViewFrame)
        self.memCache.setObject(self.controllerAtIndex(index), forKey: NSNumber(value: index))
    }
    
    @objc fileprivate func updateScrollViewDisplayIndexIfNeeded() {
        if self.scrollView.frame.size.width > 0.0 {
            self.addVisibleViewContorllerWith(self.currentPageIndex)
            let newOffset = self.calcOffsetWithIndex(
                self.currentPageIndex,
                width:Float(self.scrollView.frame.size.width),
                maxWidth:Float(self.scrollView.contentSize.width))
            
            if newOffset.x != self.scrollView.contentOffset.x ||
                newOffset.y != self.scrollView.contentOffset.y
            {
                self.scrollView.contentOffset = newOffset
            }
            self.controllerAtIndex(self.currentPageIndex).view.frame = self.calcVisibleViewControllerFrameWith(self.currentPageIndex)
        }
    }
    
    @objc fileprivate func updateScrollViewLayoutIfNeeded() {
        if self.scrollView.frame.size.width > 0.0 {
            let width = CGFloat(self.pageCount) * self.scrollView.frame.size.width
            let height = self.scrollView.frame.size.height
            let oldContentSize = self.scrollView.contentSize
            if width != oldContentSize.width ||
                height != oldContentSize.height
            {
                self.scrollView.contentSize = CGSize(width: width, height: height)
            }
        }
    }
    
    //MARK: - Helper methods
    @objc fileprivate func calcOffsetWithIndex(_ index:Int,width:Float,maxWidth:Float) -> CGPoint {
        var offsetX = Float(Float(index) * width)
        
        if offsetX < 0 {
            offsetX = 0
        }
        
        if maxWidth > 0.0 &&
            offsetX > maxWidth - width
        {
            offsetX = maxWidth - width
        }
        
        return CGPoint(x: CGFloat(offsetX),y: 0)
    }
    
    @objc fileprivate func calcIndexWithOffset(_ offset:Float,width:Float) -> Int {
        var startIndex = Int(offset/width)
        
        if startIndex < 0 {
            startIndex = 0
        }
        
        return startIndex
    }
    
    @objc fileprivate func controllerAtIndex(_ index:NSInteger) -> UIViewController
    {
        return self.dataSource!.pageViewController(self, controllerAtIndex:index);
    }
    
    @objc fileprivate func cleanCacheToClean() {
        let currentPage = self.controllerAtIndex(self.currentPageIndex)
        if self.childsToClean.contains(currentPage) {
            if let removeIndex = self.childsToClean.index(of: currentPage) {
                self.childsToClean.remove(at: removeIndex)
                self.memCache.setObject(currentPage, forKey: NSNumber(value: self.currentPageIndex))
            }
        }
        
        for vc in self.childsToClean {
            vc.removeFromParentViewController()
        }
        self.childsToClean.removeAll()
    }
    
    //MARK: - Subviews Configuration
    @objc fileprivate func configScrollView(_ scrollView:UIScrollView) {
        scrollView.frame = self.view.bounds
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.delegate = self
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.showsVerticalScrollIndicator = false
        scrollView.isPagingEnabled = true
        scrollView.backgroundColor = UIColor.clear
        scrollView.scrollsToTop = false
        
        self.view.addSubview(scrollView)
    }
    
    //MARK: - NSCacheDelegate
    func cache(_ cache: NSCache<AnyObject, AnyObject>, willEvictObject obj: Any) {
        if (obj as AnyObject).isKind(of: UIViewController.self) {
            let vc = obj as! UIViewController
            if self.childViewControllers.contains(vc) {
                
                if self.scrollView.isDragging == false &&
                    self.scrollView.isTracking == false &&
                    self.scrollView.isDecelerating == false
                {
                    let lastPage = self.controllerAtIndex(self.lastSelectedIndex)
                    let currentPage = self.controllerAtIndex(self.currentPageIndex)
                    if lastPage == vc || currentPage == vc {
                        self.childsToClean.insert(vc)
                    }
                } else if self.scrollView.isDragging == true{
                    self.addCacheToCleanIfNeed(vc, midIndex: self.guessToIndex)
                }
                
                if self.childsToClean.count > 0 {
                    return
                }
                vc.removeFromParentVC()
            }
        }
    }
    
    @objc fileprivate func addCacheToCleanIfNeed(_ vc:UIViewController,midIndex:Int){
        var leftIndex = midIndex - 1;
        var rightIndex = midIndex + 1;
        if leftIndex < 0 {
            leftIndex = midIndex
        }
        if rightIndex > self.pageCount - 1 {
            rightIndex = midIndex
        }
        
        let leftNeighbour = self.dataSource!.pageViewController(self, controllerAtIndex: leftIndex)
        let midPage = self.dataSource!.pageViewController(self, controllerAtIndex: midIndex)
        let rightNeighbour = self.dataSource!.pageViewController(self, controllerAtIndex: rightIndex)
        
        if leftNeighbour == vc || rightNeighbour == vc || midPage == vc
        {
            self.childsToClean.insert(vc)
        }
    }
    
    //MARK: - UIScrollViewDelegate
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if scrollView.isDragging == true && scrollView == self.scrollView {
            let offset = scrollView.contentOffset.x
            let width = scrollView.frame.width
            let lastGuessIndex = self.guessToIndex < 0 ? self.currentPageIndex : self.guessToIndex
            if self.originOffset < Double(offset) {
                self.guessToIndex = Int(ceil((offset)/width))
            } else if (self.originOffset > Double(offset)) {
                self.guessToIndex = Int(floor((offset)/width))
            } else {}
            let maxCount = self.pageCount
            
            if (guessToIndex != self.currentPageIndex &&
                self.scrollView.isDecelerating == false) ||
                self.scrollView.isDecelerating == true
            {
                if lastGuessIndex != self.guessToIndex &&
                    self.guessToIndex >= 0 &&
                    self.guessToIndex < maxCount
                {
                    self.pageViewControllerWillShow(self.guessToIndex, toIndex: self.currentPageIndex, animated: true)
                    self.delegate?.pageViewController?(self, willTransitonFrom: self.controllerAtIndex(self.guessToIndex),
                                                          toViewController: self.controllerAtIndex(self.currentPageIndex))
                    
                    self.addVisibleViewContorllerWith(self.guessToIndex)
                    self.controllerAtIndex(self.guessToIndex).beginAppearanceTransition(true, animated: true)

                    if lastGuessIndex == self.currentPageIndex {
                        self.controllerAtIndex(self.currentPageIndex).beginAppearanceTransition(false, animated: true)
                    }
                    
                    if lastGuessIndex != self.currentPageIndex &&
                        lastGuessIndex >= 0 &&
                        lastGuessIndex < maxCount{
                        self.controllerAtIndex(lastGuessIndex).beginAppearanceTransition(false, animated: true)
                        self.controllerAtIndex(lastGuessIndex).endAppearanceTransition()
                    }
                }
            }
        }
    }
    
    func scrollViewWillBeginDecelerating(_ scrollView: UIScrollView) {
        self.isDecelerating = true
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        self.updatePageViewAfterTragging(scrollView: scrollView)
    }
    
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        if scrollView.isDecelerating == false {
            self.originOffset = Double(scrollView.contentOffset.x)
            self.guessToIndex = self.currentPageIndex
        }
    }
    
    func scrollViewWillEndDragging(_ scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
        
        if scrollView.isDecelerating == true {
            let offset = scrollView.contentOffset.x
            let width = scrollView.frame.width
            if velocity.x > 0 { // to right page
                self.originOffset = Double(floor(offset/width)) * Double(width)
            } else if velocity.x < 0 {// to left page
                self.originOffset = Double(ceil(offset/width)) * Double(width)
            }
        }
        let offset = scrollView.contentOffset.x
        let scrollViewWidth = scrollView.frame.size.width
        if (Int(offset * 100) % Int(scrollViewWidth * 100)) == 0 {
            self.updatePageViewAfterTragging(scrollView: scrollView)
        }
    }
    
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
    }
    
    func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
    }
    
    override var shouldAutomaticallyForwardAppearanceMethods : Bool {
        return false
    }
    
    func updatePageViewAfterTragging(scrollView:UIScrollView) {
        let newIndex = self.calcIndexWithOffset(Float(scrollView.contentOffset.x),
                                                width: Float(scrollView.frame.size.width))
        let oldIndex = self.currentPageIndex
        self.currentPageIndex = newIndex
        
        if newIndex == oldIndex {
            if self.guessToIndex >= 0 && self.guessToIndex < self.pageCount {
                self.controllerAtIndex(oldIndex).beginAppearanceTransition(true, animated: true)
                self.controllerAtIndex(oldIndex).endAppearanceTransition()
                self.controllerAtIndex(self.guessToIndex).beginAppearanceTransition(false, animated: true)
                self.controllerAtIndex(self.guessToIndex).endAppearanceTransition()
            }
        } else {
            self.controllerAtIndex(newIndex).endAppearanceTransition()
            self.controllerAtIndex(oldIndex).endAppearanceTransition()
        }
        
        self.originOffset = Double(scrollView.contentOffset.x)
        self.guessToIndex = self.currentPageIndex
        
        self.pageViewControllerDidShow(self.guessToIndex, toIndex: self.currentPageIndex, finished:true)
        self.delegate?.pageViewController?(self, didTransitonFrom: self.controllerAtIndex(self.guessToIndex),
                                              toViewController: self.controllerAtIndex(self.currentPageIndex))
        self.isDecelerating = false
        
        self.cleanCacheToClean()
    }
    
    //MARK: - override
    func pageViewControllerWillShow(_ fromIndex:Int, toIndex:Int, animated:Bool) { }

    func pageViewControllerDidShow(_ fromIndex:Int, toIndex:Int, finished:Bool) { }
}
