//
//  LocationViewController.swift
//  corona-virus
//
//  Copyright © 2020 SAS. All rights reserved.
//

import UIKit
import SafariServices
import SASKit

class LocationViewController : UIViewController, SFSafariViewControllerDelegate {
    @IBOutlet weak var collectionView:UICollectionView?
    @IBOutlet weak var toolbarTitle:UIBarButtonItem?
    @IBOutlet weak var moreOptionsButton:UIBarButtonItem?
    
    @IBOutlet weak var collectionViewLayout:UICollectionViewFlowLayout?
    
    var isPageUpdating: Bool = false
    weak var pageModel:PageViewModel?
    {
        willSet(newValue) {
            NotificationCenter.default.removeObserver(self, name: AppViewModel.ReportUpdated, object: nil)
            NotificationCenter.default.removeObserver(self, name: AppViewModel.PageThumbnailsUpdated, object: self.pageModel)
            NotificationCenter.default.removeObserver(self, name: AppViewModel.ReportCheckingUpdates, object: nil)
            NotificationCenter.default.removeObserver(self, name: AppViewModel.ReportUpdating, object: nil)
        }
        didSet(oldValue) {
            NotificationCenter.default.addObserver(self, selector: #selector(reportUpdated(_:)), name: AppViewModel.ReportUpdated, object: nil)
            NotificationCenter.default.addObserver(self, selector: #selector(thumbnailsUpdated(_:)), name: AppViewModel.PageThumbnailsUpdated, object: self.pageModel)
            NotificationCenter.default.addObserver(self, selector: #selector(reportCheckingUpdates(_:)), name: AppViewModel.ReportCheckingUpdates, object: nil)
            NotificationCenter.default.addObserver(self, selector: #selector(reportIsUpdating(_:)), name: AppViewModel.ReportUpdating, object: nil)
        }
    }
    
    @objc func thumbnailsUpdated( _ notification:NSNotification ) {
        guard let pageModel = notification.object as? PageViewModel else { return }
        if self.pageModel?.location == pageModel.location {
            DispatchQueue.main.async {
                self.collectionView?.reloadData()
                self.collectionView?.invalidateIntrinsicContentSize()
                self.collectionView?.collectionViewLayout.invalidateLayout()
            }
        }
    }
    
    @objc func reportCheckingUpdates( _ notification:NSNotification) {
        isPageUpdating = true
        self.toolbarTitle?.title = NSLocalizedString("Checking Updates Message", comment: "")
    }
    
    @objc func reportIsUpdating( _ notification:NSNotification) {
        isPageUpdating = true
        self.toolbarTitle?.title = NSLocalizedString("Updating Message", comment: "")
    }
    @objc func reportUpdated( _ notification:NSNotification) {
        isPageUpdating = false
        self.toolbarTitle?.title = ""
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        collectionView?.delegate = self
        collectionView?.dataSource = self
        
        toolbarTitle?.title = ""
        
        let foregroundColor = UIColor(named: "Default foreground")!
        
        // we are using the toolbar title button as a title, instead of a button
        toolbarTitle?.isEnabled = false
        toolbarTitle?.setTitleTextAttributes([NSAttributedString.Key.foregroundColor: foregroundColor], for: .disabled)
        toolbarTitle?.accessibilityRespondsToUserInteraction = false
        
        moreOptionsButton?.accessibilityLabel = NSLocalizedString("More Options Button Accessibility Label", comment: "")
        moreOptionsButton?.accessibilityHint = NSLocalizedString("More Options Button Accessibility Hint", comment: "")
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if self.pageModel?.location != GlobalLocation {
            AppViewModel.shared.locationPageOffset = scrollView.contentOffset
        }
    }
    
    @IBAction func displayActionSheet( sender: UIBarButtonItem ) {
        let actionMenu = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
           
        let manageString = NSLocalizedString("Manage Locations Option", comment: "")
        let manageAction = UIAlertAction(title: manageString, style: .default, handler: { (action: UIAlertAction!) -> Void in
            self.performSegue(withIdentifier: "Manage Location", sender: self)
        })
        
        let legalString = NSLocalizedString("Legal Notices Option", comment: "")
        let legalAction = UIAlertAction(title: legalString, style: .default, handler: { (action: UIAlertAction!) -> Void in
            self.performSegue(withIdentifier: "Legal Notices", sender: self)
        })
        
        let feedbackString = NSLocalizedString("Send Feedback Option", comment: "")
        let sendAction = UIAlertAction(title: feedbackString, style: .default, handler: { (action: UIAlertAction!) -> Void in
            let feedbackUrl = "https://forms.office.com/Pages/ResponsePage.aspx?id=XE3BsSU2s0WkMJVSNzoML3RNFolnWOBCiL6xGKcJQJtUQlZNSEE3NTE0UjFIRElBNU44WkJCQlZWViQlQCN0PWcu"
            if let url = URL(string: feedbackUrl) {
                let sendAction = SFSafariViewController(url: url)
                sendAction.delegate = self
                self.present(sendAction, animated: true)
            }
        })
        
        let cancelString = NSLocalizedString("Cancel Option", comment: "")
        let cancelAction = UIAlertAction(title: cancelString, style: .cancel)
           
        actionMenu.addAction(manageAction)
        actionMenu.addAction(sendAction)
        actionMenu.addAction(legalAction)
        actionMenu.addAction(cancelAction)
        
        actionMenu.pruneNegativeWidthConstraints()
        
        self.present(actionMenu, animated: true, completion: nil)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        super.prepare(for: segue, sender: sender)
        if segue.identifier == "ExpandVisual" {
            if let visualModel = sender as? VisualViewModel, let objectID = visualModel.objectID, let visual = AppViewModel.shared.getVisualView( objectID ), let destination = segue.destination as? ExpandedVisualViewController, let _ = destination.view, let visualView = destination.visualView {
                
                visualView.addSubview( visual )
                
                visual.translatesAutoresizingMaskIntoConstraints = false
                
                let topConstraint = NSLayoutConstraint(item: visual, attribute: .top, relatedBy: .equal, toItem: destination.visualView, attribute: .top, multiplier: 1, constant: 0)
                let bottomConstraint = NSLayoutConstraint(item: visual, attribute: .left, relatedBy: .equal, toItem: destination.visualView, attribute: .left, multiplier: 1, constant: 0)
                let leftConstraint = NSLayoutConstraint(item: visual, attribute: .right, relatedBy: .equal, toItem: destination.visualView, attribute: .right, multiplier: 1, constant: 0)
                let rightConstraint = NSLayoutConstraint(item: visual, attribute: .bottom, relatedBy: .equal, toItem: destination.visualView, attribute: .bottom, multiplier: 1, constant: 0)
                
                visualView.addConstraints([ topConstraint, bottomConstraint, leftConstraint, rightConstraint])
                
                destination.navigationItem.title = self.pageModel?.locationLabel
                destination.visualTitle?.text = ""
                destination.visualViewModel = visualModel
                AppViewModel.shared.assignDelegate(objectID, delegate: destination)
            }
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        if let offset = AppViewModel.shared.locationPageOffset, self.pageModel?.location != GlobalLocation {
            DispatchQueue.main.async {
                self.collectionView?.bounds.origin = offset
            }
        }

        super.viewWillAppear(animated)

        if let pageModel = pageModel {
            let hasAllThumbnails = pageModel.hasAllCachedObjects
            if !hasAllThumbnails {
                ReportObjectCache.shared.addPageToProcess(pageModel)
            }
        }
        
        ReportObjectCache.shared.resume()
    }
}

extension LocationViewController : UICollectionViewDelegateFlowLayout { }

extension LocationViewController : UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        guard let model = pageModel else {return 0}
        return model.visuals.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let visualModel = pageModel?.visuals[indexPath.item] else { return UICollectionViewCell() }
        if let _ = visualModel.reportObject as? SASTextReportObject {
            guard let textCell = collectionView.dequeueReusableCell(withReuseIdentifier: DynamicTextCell.reuseIdentifier, for: indexPath) as? DynamicTextCell else { return UICollectionViewCell() }
            textCell.cellWidthConstraint?.constant = getCellWidth()
            textCell.label?.attributedText = visualModel.dynamicText
            return textCell
        }
        else {
            guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: VisualCell.reuseIdentifier, for: indexPath) as? VisualCell else { return UICollectionViewCell() }
            
            cell.cellWidthConstraint?.constant = getCellWidth()
            
            cell.visualModel = visualModel
            
            return cell
        }
    }
    
    func getCellWidth() -> CGFloat {
        guard let collection = collectionView, let layout = collectionView?.collectionViewLayout as? UICollectionViewFlowLayout else { return 0 }
        
        return collection.bounds.width - collection.contentInset.left - collection.contentInset.right - layout.sectionInset.left - layout.sectionInset.right
    }
    
    func collectionView(_ collectionView: UICollectionView, shouldSelectItemAt indexPath: IndexPath) -> Bool {
        return pageModel?.visuals[indexPath.item].expandable ?? false
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if(!self.isPageUpdating) {
            if let visual = pageModel?.visuals[indexPath.item] {
                ReportObjectCache.shared.pause {
                    AppViewModel.shared.locationsFilterControl?.selectedValue = self.pageModel?.location
                    
                    self.performSegue(withIdentifier: "ExpandVisual", sender: visual)
                }
            }
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        if let visual = pageModel?.visuals[indexPath.item] {
            let cellWidth = getCellWidth()
            var cellSize = CGSize(width: cellWidth, height: visual.visualSize
                .height)
            
            if visual.externalTitle {
                let testLabel = UILabel()
                testLabel.font = UIFont.preferredFont(forTextStyle: .headline)
                testLabel.text = visual.reportObject?.title?.string
                testLabel.numberOfLines = 0
                let labelSize = testLabel.sizeThatFits(CGSize(width: cellWidth, height: CGFloat.greatestFiniteMagnitude))
                cellSize.height = cellSize.height + labelSize.height + 30
            }
            
            return cellSize
        }
        
        return CGSize.zero
    }
}

// this is a workaround for an apple bug with layout constraint issues
extension UIAlertController {
    func pruneNegativeWidthConstraints() {
        for subView in self.view.subviews {
            for constraint in subView.constraints where constraint.debugDescription.contains("width == - 16") {
                subView.removeConstraint(constraint)
            }
        }
    }
}
