//
//  LocationCell.swift
//  corona-virus
//
//  Copyright © 2020 SAS. All rights reserved.
//

import UIKit

class ManageLocationCell : UITableViewCell
{
    @IBOutlet weak var roundedContentView:UIView?
    @IBOutlet weak var label:UILabel?
    
    override func awakeFromNib()
    {
        super.awakeFromNib()
        self.roundedContentView?.layer.cornerRadius = 10
        self.roundedContentView?.clipsToBounds = true
    }
}
