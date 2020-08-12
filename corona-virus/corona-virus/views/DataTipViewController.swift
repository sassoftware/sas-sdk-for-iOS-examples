//
//  DataTipViewController.swift
//  corona-virus
//
//  Copyright © 2020 SAS. All rights reserved.
//

import UIKit
import SASKit

class DataTipCell : UITableViewCell {
    @IBOutlet weak var titleLabel:UILabel?
    @IBOutlet weak var valueLabel:UILabel?
    
    @IBOutlet weak var trailingTitleConstraint:NSLayoutConstraint?
    @IBOutlet weak var bottomTitleConstraint:NSLayoutConstraint?
    @IBOutlet weak var topTitleAndValueConstraint:NSLayoutConstraint?
    @IBOutlet weak var widthValueConstraint:NSLayoutConstraint?
    
    @IBOutlet weak var largeFontTrailingTitleConstraint:NSLayoutConstraint?
    @IBOutlet weak var largeFontBottomTitleConstraint:NSLayoutConstraint?
    @IBOutlet weak var largeFontLeadingValueConstraint:NSLayoutConstraint?
    
    @IBOutlet weak var spaceToTop:NSLayoutConstraint?
    @IBOutlet weak var spaceToBottom:NSLayoutConstraint?
    
    var spaceBetweenCells : CGFloat {
        return hasLargeFonts ? 12.fVal : 8.fVal
    }

    var hasLargeFonts : Bool = false {
        didSet {
            
            largeFontBottomTitleConstraint?.isActive = hasLargeFonts
            largeFontBottomTitleConstraint?.constant = spaceBetweenCells / 2.fVal
            largeFontTrailingTitleConstraint?.isActive = hasLargeFonts
            largeFontLeadingValueConstraint?.isActive = hasLargeFonts
            
            trailingTitleConstraint?.isActive = !hasLargeFonts
            bottomTitleConstraint?.isActive = !hasLargeFonts
            topTitleAndValueConstraint?.isActive = !hasLargeFonts
            widthValueConstraint?.isActive = !hasLargeFonts
            
            spaceToTop?.constant = spaceBetweenCells / 2.fVal
            spaceToBottom?.constant = spaceBetweenCells / 2.fVal
        }
    }
}

class DataTipViewController : UITableViewController {
    public var dataTip:SASDataTip?
    public var usesLargeFontSetting:Bool = false
    var lastFocusedElement: Any? = nil
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.definesPresentationContext = true
        
        self.tableView.layer.cornerRadius = 5
        self.tableView.separatorStyle = .none
        self.tableView.backgroundColor = UIColor.init(named: "Report background")?.darker()
        self.tableView.layer.borderColor = UIColor.init(named: "Report foreground")?.withAlphaComponent(0.25).cgColor
        self.tableView.layer.borderWidth = 1
        self.tableView.allowsSelection = false
        
        // we want the total spacing to be 16 on the top and bottom, so we can adjust based on
        // the space between cells
        let dummyCell = DataTipCell()
        dummyCell.hasLargeFonts = self.usesLargeFontSetting
        let topHeader = UIView.init(frame: CGRect.init(x: 0, y: 0, width: self.tableView.frame.width, height: 15-dummyCell.spaceBetweenCells/2.fVal))
        topHeader.backgroundColor = .clear
        self.tableView.tableHeaderView = topHeader
        let bottomFooter = UIView.init(frame: CGRect.init(x: 0, y: 0, width: self.tableView.frame.width, height: 15-dummyCell.spaceBetweenCells/2.fVal))
        bottomFooter.backgroundColor = .clear
        self.tableView.tableFooterView = bottomFooter

        let nib = UINib(nibName: "DataTipCell", bundle: nil)
        tableView.register(nib, forCellReuseIdentifier: "DataTipItem")
        let tapRecognizer = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
        tableView.addGestureRecognizer( tapRecognizer )
        checkFonts()
    }
    
    @objc func handleTap(_ sender: UITapGestureRecognizer) {
        if sender.state == .ended {
            showDataTip(false)
        }
    }
    
    override func accessibilityPerformEscape() -> Bool {
        showDataTip(false)
        return true
    }

    func showDataTip( _ showTip:Bool) {
        if showTip {
            self.tableView.isHidden = false
            lastFocusedElement = UIAccessibility.focusedElement(using: .notificationVoiceOver)
        }
        UIView.animate(withDuration: 0.3, animations: {
            self.tableView.alpha = showTip ? 1 : 0
        }) { (true) in
            self.tableView.isHidden = !showTip
            if showTip {
                UIAccessibility.post(notification: UIAccessibility.Notification.layoutChanged, argument: self.tableView)
            }
            else if let lastElement = self.lastFocusedElement as? UIAccessibilityElement {
                UIAccessibility.post(notification: UIAccessibility.Notification.layoutChanged, argument: lastElement)
            }
            self.tableView.accessibilityViewIsModal = showTip
        }
    }
    
    // when the font size changes, we need to reset the font setting so we have one or
    // two columns in the data tip. 
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        
        if traitCollection.preferredContentSizeCategory != previousTraitCollection?.preferredContentSizeCategory {
            checkFonts()
        }
    }
    
    func checkFonts()
    {
        let fontSetting = UIApplication.shared.preferredContentSizeCategory
        
        switch fontSetting {
        case .accessibilityExtraExtraExtraLarge,
             .accessibilityExtraExtraLarge,
             .accessibilityExtraLarge,
             .accessibilityLarge,
             .accessibilityMedium:
            self.usesLargeFontSetting = true
        default:
            self.usesLargeFontSetting = false
        }
    }
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let dataTip = dataTip else { return 0 }
        return dataTip.dataRows.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let dataTipItems = dataTip?.dataRows else { return UITableViewCell() }
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "DataTipItem") as? DataTipCell else { return UITableViewCell() }
        
        cell.titleLabel?.textColor = UIColor.init(named: "Report foreground" )?.withAlphaComponent(0.6)
        cell.titleLabel?.text = dataTipItems[indexPath.row].dataItemLabel + ":"
        
        cell.valueLabel?.text = dataTipItems[indexPath.row].formattedValue
        
        let largeFontColor = UIColor.init(named: "Report foreground")?.withAlphaComponent(0.9)
        let regularFontColor = UIColor.init(named: "Report foreground" )?.withAlphaComponent(0.6)
        cell.valueLabel?.textColor = usesLargeFontSetting ? largeFontColor : regularFontColor
        cell.backgroundColor = .clear
        cell.hasLargeFonts = usesLargeFontSetting
        
        return cell
    }
}
