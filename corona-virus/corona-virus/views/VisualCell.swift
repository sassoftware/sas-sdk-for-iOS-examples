//
//  VisualCell.swift
//  corona-virus
//
//  Copyright © 2020 SAS. All rights reserved.
//

import UIKit
import SASKit

class VisualCell : UICollectionViewCell {
    public static let reuseIdentifier = "VisualCell"
    
    public var visualModel:VisualViewModel? {
        didSet(oldValue) {
            updateModel()
        }
    }
    
    @IBOutlet weak var optionalTitle:UILabel?
    @IBOutlet weak var visualView:UIImageView?
    @IBOutlet weak var withTitleConstraint:NSLayoutConstraint?
    @IBOutlet weak var withoutTitleConstraint:NSLayoutConstraint?
    
    @IBOutlet weak var visualHeightConstraint:NSLayoutConstraint?
    
    var cellWidthConstraint:NSLayoutConstraint?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        let widthConstraint = NSLayoutConstraint(item: contentView, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: 400)
        contentView.addConstraints([widthConstraint])
        self.cellWidthConstraint = widthConstraint
        
        self.visualView?.layer.cornerRadius = 10
        self.visualView?.backgroundColor = UIColor(named: "Report background")
        self.isAccessibilityElement = true
        
        updateModel()
    }
    
    func updateModel() {
        if let model = visualModel {
            if model.externalTitle {
                optionalTitle?.text = model.reportObject?.title?.string
                withTitleConstraint?.isActive = true
                withoutTitleConstraint?.isActive = false
            }
            else {
                clearLabel()
            }
    
            visualView?.image = model.thumbnail
            visualHeightConstraint?.constant = CGFloat( model.visualSize.height )
        }
    }
    
    override var accessibilityLabel: String? {
        get {
            if let model = visualModel {
                return ReportObjectCache.shared.getCachedAccessibilityLabel(filterValue: model.filterValue ?? "", objectID: model.objectID ?? "")
            }
            return super.accessibilityLabel
        }
        set(newValue) {
            super.accessibilityLabel = newValue
        }
    }
    
    func clearLabel() {
        optionalTitle?.text = ""
        withTitleConstraint?.isActive = false
        withoutTitleConstraint?.isActive = true
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        clearLabel()
        visualView?.image = nil
    }
}
