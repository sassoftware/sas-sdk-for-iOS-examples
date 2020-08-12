//
//  ExpandedVisualViewController.swift
//  corona-virus
//
//  Copyright © 2020 SAS. All rights reserved.
//

import UIKit
import SASKit

class ExpandedVisualViewController : UIViewController, SASReportObjectDelegate
{
    @IBOutlet weak var visualView:UIView?
    @IBOutlet weak var visualTitle:UILabel?
    @IBOutlet weak var backButton:UIBarButtonItem?
    
    public weak var visualViewModel:VisualViewModel?
    
    private var dataTipVC:DataTipViewController?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        NotificationCenter.default.addObserver(self, selector: #selector(willEnterForeground), name: UIApplication.willEnterForegroundNotification, object: nil)
        self.backButton?.accessibilityLabel = NSLocalizedString("Back Button Accessibility Label", comment: "")
        
        let swipeFromEdgeGesture = UIScreenEdgePanGestureRecognizer(target: self, action: #selector(screenEdgeSwiped))
        swipeFromEdgeGesture.edges = .left

        view.addGestureRecognizer(swipeFromEdgeGesture)
    }
    
    @objc func screenEdgeSwiped(_ recognizer: UIScreenEdgePanGestureRecognizer) {
        if recognizer.state == .recognized {
            dismissVisualView(UIBarButtonItem())
        }
    }
    
    @objc func willEnterForeground() {
        hideDataTip()
    }
    
    @IBAction func dismissVisualView( _ sender:Any) {
        if let objectID = visualViewModel?.objectID {
            // sending in nil instead of self will remove self as the delegate
            AppViewModel.shared.assignDelegate(objectID, delegate: nil)
        }
        self.navigationController?.popViewController(animated: true)
    }
    
    // for now, we need to dismiss the tooltip when attributes change (font size, etc)
    // otherwise, layout changes may need to be made to the existing tooltip
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        
        if traitCollection.preferredContentSizeCategory != previousTraitCollection?.preferredContentSizeCategory {
            hideDataTip()
        }
    }
    
    func willHandleDataTip(object: SASReportObject, info: SASDataTip) -> Bool {
        if let visualViewModel = visualViewModel {
            return visualViewModel.showTooltips
        }
        return false
    }
    
    func showDataTip(object: SASReportObject, info: SASDataTip) {
        if dataTipVC == nil {
            let dtVC = DataTipViewController.init(style: .plain)
            self.addChild(dtVC)
            self.view.addSubview(dtVC.view)
            dtVC.view.alpha = 0
            dtVC.view.isHidden = true
            dataTipVC = dtVC
        }
        guard let dataTipVC = dataTipVC else { return }
        guard let visualView = visualView else { return }
        dataTipVC.dataTip = info
        
        let vertPadding:CGFloat = 40
        let horizPadding:CGFloat = 30
        
        dataTipVC.tableView.frame = CGRect.init(origin: CGPoint.zero, size: CGSize(width: view.safeAreaLayoutGuide.layoutFrame.width-horizPadding*2.fVal,height: 500))
        dataTipVC.tableView.reloadData()
        dataTipVC.tableView.layoutIfNeeded()
        dataTipVC.tableView.sizeToFit()
        
        var contentSize = dataTipVC.tableView.contentSize
        
        if contentSize.height > view.safeAreaLayoutGuide.layoutFrame.height - vertPadding*2.fVal {
            contentSize.height = view.safeAreaLayoutGuide.layoutFrame.height - vertPadding*2.fVal
            dataTipVC.tableView.isScrollEnabled = true
        }
        else {
            dataTipVC.tableView.isScrollEnabled = false
        }
        dataTipVC.tableView.frame.size.height = contentSize.height
        
        // get the preferred tip location from the datatip info
        // we want that point to be the center of the data tip, so subtract
        // half of the width and height of the data tip
        // also the preferred location is location inside the visual view, so we need to adjust
        // based on the visual view's origin as well.
        var dataTipOrigin = info.preferredTipLocation
        
        dataTipOrigin.x = dataTipOrigin.x + visualView.frame.origin.x - contentSize.width/2.fVal
        dataTipOrigin.y = dataTipOrigin.y + visualView.frame.origin.y - contentSize.height/2.fVal

        // make sure the datatip isn't too far to the right or bottom
        dataTipOrigin.x = min( dataTipOrigin.x, view.safeAreaLayoutGuide.layoutFrame.width - horizPadding - contentSize.width )
        dataTipOrigin.y = min( dataTipOrigin.y, view.safeAreaLayoutGuide.layoutFrame.height - vertPadding - contentSize.height )
        
        // make sure the datatip isn't too far to the left and top
        dataTipOrigin.x = max( dataTipOrigin.x, horizPadding + view.safeAreaLayoutGuide.layoutFrame.origin.x )
        dataTipOrigin.y = max( dataTipOrigin.y, vertPadding + view.safeAreaLayoutGuide.layoutFrame.origin.y )
        
        dataTipVC.tableView.frame.origin = dataTipOrigin
        self.view.bringSubviewToFront(dataTipVC.tableView)
        
        dataTipVC.showDataTip(true)
    }
    
    func hideDataTip(object: SASReportObject, info: SASDataTip) {
        hideDataTip()
    }
    
    func hideDataTip() {
        dataTipVC?.showDataTip(false)
    }
    
    override func accessibilityPerformEscape() -> Bool {
        dismissVisualView(UIBarButtonItem())
        return true
    }
    
    func reportObjectIsBusy(object: SASReportObject) {
    }
    
    func reportObjectIsReady(object: SASReportObject) {
    }
    
    func reportObjectDataChanged(object: SASReportObject) {
    }
}
