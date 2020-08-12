//
//  DynamicTextCell.swift
//  corona-virus
//
//  Copyright © 2020 SAS. All rights reserved.
//

import UIKit

class DynamicTextCell : UICollectionViewCell {
    
    public static let reuseIdentifier = "DynamicTextCell"
    
    @IBOutlet weak var label:UILabel?
    
    var cellWidthConstraint:NSLayoutConstraint?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        let widthConstraint = NSLayoutConstraint(item: contentView, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: 400)
        contentView.addConstraints([widthConstraint])
        self.cellWidthConstraint = widthConstraint
        
        self.contentView.layer.cornerRadius = 10
        self.contentView.backgroundColor = UIColor(named: "Report background")
        self.label?.textColor = UIColor(named: "Report foreground")
        self.isAccessibilityElement = true
    }
    
    override var accessibilityLabel: String? {
        get {
            return label?.accessibilityLabel
        }
        set(newLabel) {
            
        }
    }
}
