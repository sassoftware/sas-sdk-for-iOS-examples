//
//  PageViewModel.swift
//  corona-virus
//
//  Copyright © 2020 SAS. All rights reserved.
//

import Foundation
import SASKit

/// ViewModel for a single visual.
class VisualViewModel : Codable {
    
    // MARK: Codable
    enum CodingKeys: CodingKey {
        case objectID
        case visualHeight
        case expandable
        case externalTitle
        case showTooltips
    }

    /// The unique identifier for an object in the report.
    var objectID: String? = nil
    /// The height this visual should be given on the page
    /// NOTE: all visuals are given the full width.
    private var visualHeight: Int = 200
    /// Should the user be able to drill in and interact with this visual.
    var expandable:Bool = true
    /// Should we use the internal title on this visual (provided by the report
    /// object rendering) or are we going to render it ourselves.
    var externalTitle:Bool = false
    /// The filter value used to filter this object.
    var filterValue: String? = nil
    /// can we get tooltips for this object?
    var showTooltips:Bool = false
    
    /// Accessibility label for this object.
    var accessibilityLabel: String? = nil
    /// Accessibility hint for this object.
    var accessibilityHint:String? = nil
    
    /// The interface to the report object.
    var reportObject: SASReportObject? = nil {
        /// When thhis changes, we need to reset the thumbnail, text and accessibility info, as
        /// it may have changed.
        didSet(oldValue) {
            thumbnail = nil
            dynamicText = nil
            accessibilityLabel = nil
            if let objectID = self.objectID {
                thumbnail = ReportObjectCache.shared.getCachedImage(filterValue: filterValue ?? "", objectID: objectID, size: self.visualSize)
                dynamicText = ReportObjectCache.shared.getCachedText(filterValue: filterValue ?? "", objectID: objectID)
                accessibilityLabel = ReportObjectCache.shared.getCachedAccessibilityLabel(filterValue: filterValue ?? "", objectID: objectID )
                accessibilityHint = expandable ? NSLocalizedString("Visual Accessibility Hint", comment: "") : ""
            }
        }
    }
    
    /// The UI image of this visual.
    var thumbnail: UIImage?
    /// The Attributed string (if this is a text visual)
    var dynamicText: NSAttributedString?
    
    /// computed propery for the visuals size.
    var visualSize: CGSize
    {
        get
        {
            // default size
            var visSize = CGSize(width: UIScreen.main.bounds.width-30, height: CGFloat(visualHeight))
            
            // we want the specified height to represent the "graph" portion of the
            // visual, so we need to add the height of the label to the desired height
            if !externalTitle
            {
                let visualTitle = reportObject?.title
            
                let labelWidth = visSize.width - CGFloat((reportObject?.padding ?? 0) * 2)
                let label = UILabel()
                label.attributedText = visualTitle
                label.numberOfLines = 0
                let labelSize = label.sizeThatFits(CGSize(width: labelWidth, height: CGFloat.greatestFiniteMagnitude))
                
                visSize.height = visSize.height + labelSize.height + CGFloat(reportObject?.padding ?? 0) // allow for space between title and graph
            }
            
            return visSize
        }
    }
}

/// The ViewModel for a page.
class PageViewModel : Codable {
    /// The location this page represents.
    var location: String = GlobalLocation
    /// The list of visuals on this page.
    var visuals: [VisualViewModel] = []
    
    /// The SASReport we are using to get objects from.
    var report: SASReport? = nil {
        /// When the report changes, we need to reset our data structures.
        willSet(newValue) {
            if newValue == nil {
                for visual in visuals {
                    report?.unloadReportObject(visual.objectID ?? "")
                    visual.reportObject = nil
                    visual.filterValue = nil
                }
            }
        }
        
        /// When the report changes, re-load the report object.
        didSet(oldValue) {
            for visual in visuals {
                visual.filterValue = self.location
                visual.reportObject = report?.loadReportObject(visual.objectID ?? "") ?? nil
            }
        }
    }
    
    // MARK: Codable
    enum CodingKeys: CodingKey {
        case location
        case visuals
    }
    
    /// The display string for the page's location.
    var locationLabel: String {
        get {
            if location == GlobalLocation {
                return NSLocalizedString("Global Location Label", comment: "")
            }
            
            return location
        }
    }
    
    /// do we have cache hits for all the objects on this page?
    var hasAllCachedObjects: Bool {
        return percentageCachedObjectsComplete == 1
    }
    
    /// compute how many objects are already in the cache.
    var percentageCachedObjectsComplete: CGFloat {
        get {
            let numVisuals = CGFloat(visuals.count)
            var completedThumbnails:CGFloat = 0
            
            for visual in visuals {
                if visual.thumbnail != nil || visual.dynamicText != nil {
                    completedThumbnails = completedThumbnails + 1
                }
            }
            
            // avoid weird floating math, just in case
            if completedThumbnails == numVisuals
            {
                return 1
            }

            return completedThumbnails / numVisuals
        }
    }
}
