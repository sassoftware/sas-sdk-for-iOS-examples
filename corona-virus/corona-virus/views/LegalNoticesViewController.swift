//
//  LegalNoticesViewController.swift
//  corona-virus
//
//  Copyright © 2020 SAS. All rights reserved.
//

import UIKit

class LegalNoticesViewController : UIViewController {
    
    @IBOutlet weak var containerView:UIView?
    @IBOutlet weak var closeButton:UIBarButtonItem?
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        navigationItem.title = NSLocalizedString("Legal Notices Title", comment: "")
        closeButton?.title = NSLocalizedString("Close Button Label", comment: "")
        
        guard let legalView = AppViewModel.shared.report?.loadReportObject(AppViewModel.shared.legalObjectID)?.view else { return }
        guard let container = containerView else { return }
        
        container.addSubview( legalView )
        legalView.translatesAutoresizingMaskIntoConstraints = false
        
        let topConstraint = NSLayoutConstraint(item: legalView, attribute: .top, relatedBy: .equal, toItem: container, attribute: .top, multiplier: 1, constant: 0)
        let bottomConstraint = NSLayoutConstraint(item: legalView, attribute: .left, relatedBy: .equal, toItem: container, attribute: .left, multiplier: 1, constant: 0)
        let leftConstraint = NSLayoutConstraint(item: legalView, attribute: .right, relatedBy: .equal, toItem: container, attribute: .right, multiplier: 1, constant: 0)
        let rightConstraint = NSLayoutConstraint(item: legalView, attribute: .bottom, relatedBy: .equal, toItem: container, attribute: .bottom, multiplier: 1, constant: 0)
        
        container.addConstraints([ topConstraint, bottomConstraint, leftConstraint, rightConstraint])
    }
    
    @IBAction func closeLegalNotice( sender: UIBarButtonItem )
    {
        self.navigationController?.dismiss(animated: true, completion: {})
    }
    
    
    
}
