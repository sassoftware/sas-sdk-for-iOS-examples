//
//  ReportObjectImageCache.swift
//  corona-virus
//
//  Copyright © 2020 SAS. All rights reserved.
//

import Foundation
import SASKit

/// Report Object Cache
///
/// This class is responsible for the processing of the report and generation of all the images
/// for the app.
///
/// NOTE: Since there is one page in the report for the location visuals, and a section filter to change
///       between the locations, and since we want the visuals to be located on different pages of the app,
///       we opted to cache images of the visuals every time the data changes.   This allows the app to work
///       offline, and allows the UI to just deal with images, which are easier to manage.
class ReportObjectCache : SASReportObjectDelegate {
    
    /// This is a singleton object in the app.  We will have one shared instance.
    static let shared: ReportObjectCache = ReportObjectCache()
    
    /// File system path where the cache will be stored
    static let imageCachePath: URL = URL(fileURLWithPath: SASFileUtils.cachePath()).appendingPathComponent("SASCorona")
    
    /// Private init.  This is a singleton.  use ReportObjectCache.shared
    private init() {
        do { try FileManager.default.createDirectory(at: ReportObjectCache.imageCachePath, withIntermediateDirectories: true, attributes: nil) } catch {}
    }

    // MARK: Pause Methods
    
    /// We allow the processing to be paused so that we can use the report filter
    /// to be used to get live visuals within the app.
    public private(set) var isPaused: Bool = false
    
    /// When a caller asks to pause processing, the pause will not happen immediatly.
    /// We need to wait for visuals currently rendering to finish.  When they finish,
    /// we need to let the "pause" caller know that they can safely use the report locations
    /// filter and the filtered objects.
    private var pauseCompletionBlock: (()->Void)? = nil

    /// This is for other parts of the application that need to modify the filter, or display
    /// live visual to tell the cache to pause processing.   The completion block will be called when
    /// its safe to use the report API's
    public func pause(completion: @escaping ()->Void ) {
        isPaused = true

        self.pauseCompletionBlock = completion
        checkPagesToProcess()
    }
    
    /// Utility method to call check if we are done processing and paused.
    private func pauseCompletion() {
        guard isPaused && visualsToSnap.isEmpty else { return }
        let tempCompletion = pauseCompletionBlock
        pauseCompletionBlock = nil
        tempCompletion?()
    }
    
    /// When another part of the application has paused the cache, and they are done working with
    /// the report, it should resume the cache so that updates can be processed.
    public func resume() {
        isPaused = false
        checkPagesToProcess()
    }
    
    // MARK: Cache operations
    
    /// Cache invalidation.
    /// This will remove the files in the cache.
    ///
    /// AppViewModel.ReportUpdating will be dispatched.
    func invalidateCache() {
        do {
            try FileManager.default.removeItem(at: ReportObjectCache.imageCachePath)
            try FileManager.default.createDirectory(at: ReportObjectCache.imageCachePath, withIntermediateDirectories: true, attributes: nil)
        } catch {}
        
        NotificationCenter.default.post(Notification(name: AppViewModel.ReportUpdating))
        
        let pages = AppViewModel.shared.pages
        for page in pages {
            let visuals = page.visuals
            for visual in visuals {
                visual.thumbnail = nil
                visual.dynamicText = nil
                visual.accessibilityLabel = nil
            }
        }
    }
    
    /// Selective cache invalidation.
    /// This can be used to invalidate a single page in the app.
    func removeImages(_ location:String) {
        if let pageModel = AppViewModel.shared.pageForLocation(location) {
            for visual in pageModel.visuals {
                if let objectID = visual.objectID {
                    
                    // remove the accessibility label
                    if self.hasCachedAccessibilityLabel(visual: visual) {
                        let objectKey = generateKey(filterValue: pageModel.location, objectID: objectID+"accessibilityLabel", size: CGSize.zero)
                        let diskLocation = ReportObjectCache.imageCachePath.appendingPathComponent(objectKey + ".rtf").path
                        do { try FileManager.default.removeItem(atPath: diskLocation) } catch {}
                    }
                    
                    // remove cached text
                    if self.hasCachedText(visual: visual) {
                        let objectKey = generateKey(filterValue: pageModel.location, objectID: objectID, size: CGSize.zero)
                        
                        let diskLocation = ReportObjectCache.imageCachePath.appendingPathComponent(objectKey + ".rtf").path
                        do { try FileManager.default.removeItem(atPath: diskLocation) } catch {}
                    }
                    
                    // remove cached image
                    if self.hasCachedImage(visual: visual) {
                        let objectKey = generateKey(filterValue: pageModel.location, objectID: objectID, size: visual.visualSize)
                        
                        let diskLocation = ReportObjectCache.imageCachePath.appendingPathComponent(objectKey + ".png").path
                        do { try FileManager.default.removeItem(atPath: diskLocation) } catch {}
                    }
                }
            }
            
            if let index = AppViewModel.shared.pages.firstIndex(where: {$0 === pageModel}) {
                AppViewModel.shared.pages.remove(at:index)
            }
            
            if let index = pagesToProcess.firstIndex(where: {$0 === pageModel}) {
                pagesToProcess.remove(at: index)
            }
            
            if currentPage?.location == pageModel.location {
                currentPage = nil
                visualsToSnap = []
            }
        }
    }
    
    /// Generate a unique cache key for a object in a page.
    private func generateKey(filterValue: String, objectID: String, size: CGSize) -> String {
        let host = AppViewModel.shared.sasServerURL.host ?? ""
        let key = host + AppViewModel.shared.reportId + objectID + filterValue + "_width(\(size.width))_height(\(size.height))_"
        
        return Data(key.utf8).base64EncodedString()
    }
    
    /// For the text objects, we render NSAttributed strings we get from the report.  This caches the string
    /// to the disk for easy retrival
    func cacheText(text: NSAttributedString?, reportID: String, filterValue: String, objectID: String) {
        let key = generateKey(filterValue: filterValue, objectID: objectID, size: CGSize.zero)
        let diskLocation = ReportObjectCache.imageCachePath.appendingPathComponent(key + ".rtf").path
    
        do {
            if let text = text {
                let documentAttributes: [NSAttributedString.DocumentAttributeKey: Any] = [.documentType: NSAttributedString.DocumentType.rtf]
                
                let rtfData = try text.data(from: NSRange(location: 0, length: text.length), documentAttributes: documentAttributes)
                let rtfString = String(data: rtfData, encoding: .utf8) ?? ""
                try rtfString.write(to: URL(fileURLWithPath: diskLocation), atomically: true, encoding: .utf8)
            }
            else {
                try FileManager.default.removeItem(atPath: diskLocation)
            }
        } catch { return }
    }
    
    /// We have accessibiity labels for each cell in the app.   We need to cache them since computing them is expensive
    func cacheAccessibilityLabel(text: String?, reportID: String, filterValue: String, objectID: String) {
        return cacheText(text: NSAttributedString.init(string: text ?? ""), reportID: reportID, filterValue: filterValue, objectID: objectID+"accessibilityLabel")
    }
    
    /// Cache an image of a report visual to disk
    func cacheImage(image: UIImage?, reportID: String, filterValue: String, objectID: String, size: CGSize ) {
        let key = generateKey(filterValue: filterValue, objectID: objectID, size: size)

        let diskLocation = ReportObjectCache.imageCachePath.appendingPathComponent(key + ".png").path
        
        do {
            if let image = image {
                try image.pngData()?.write(to: URL(fileURLWithPath: diskLocation))
            }
            else {
                try FileManager.default.removeItem(atPath: diskLocation)
            }
        } catch { return }
    }
    
    /// Check for the existence of a cached visual.
    func hasCachedImage(visual: VisualViewModel) -> Bool {
        let key = generateKey(filterValue: visual.filterValue ?? "", objectID: visual.objectID ?? "", size: visual.visualSize)

        let diskLocation = ReportObjectCache.imageCachePath.appendingPathComponent(key + ".png").path
        return FileManager.default.fileExists(atPath: diskLocation)
    }
    
    /// Check for the existence of a cached text.
    func hasCachedText(visual: VisualViewModel) -> Bool {
        let key = generateKey(filterValue: visual.filterValue ?? "", objectID: visual.objectID ?? "", size: CGSize.zero)

        let diskLocation = ReportObjectCache.imageCachePath.appendingPathComponent(key + ".rtf").path
        return FileManager.default.fileExists(atPath: diskLocation)
    }
    
    /// Check for the existence of a cached accessibility label.
    func hasCachedAccessibilityLabel( visual: VisualViewModel ) -> Bool {
        let key = generateKey(filterValue: visual.filterValue ?? "", objectID: (visual.objectID ?? "") + "accessibilityLabel", size: CGSize.zero)
        let diskLocation = ReportObjectCache.imageCachePath.appendingPathComponent(key + ".rtf").path
        return FileManager.default.fileExists(atPath: diskLocation)
    }
    
    /// Fetch an image for a particular visual from the cache.
    func getCachedImage(filterValue: String, objectID: String, size: CGSize) -> UIImage? {
        let key = generateKey(filterValue: filterValue, objectID: objectID, size: size)
        
        let diskLocation = ReportObjectCache.imageCachePath.appendingPathComponent(key + ".png").path
        if let image = UIImage(contentsOfFile: diskLocation) {
            return image
        }

        return nil
    }
    
    /// Fetch text for a particular visual from the cache.
    func getCachedText(filterValue: String, objectID: String) -> NSAttributedString? {
        let key = generateKey(filterValue: filterValue, objectID: objectID, size: CGSize.zero )
        let diskLocation = ReportObjectCache.imageCachePath.appendingPathComponent(key + ".rtf").path
        let options = [NSAttributedString.DocumentReadingOptionKey.documentType: NSAttributedString.DocumentType.rtf]
        do {
        let rtfString = try NSMutableAttributedString(url: URL(fileURLWithPath:diskLocation), options: options, documentAttributes: nil)
        return rtfString
        } catch { return nil}
    }
    
    /// fetch the accessibility label for a particular visual from the cache.
    func getCachedAccessibilityLabel(filterValue: String, objectID: String) -> String? {
        return getCachedText(filterValue: filterValue, objectID: objectID+"accessibilityLabel")?.string
    }
    
    // MARK: Report Processing
    
    /// internal list of pages that are queued to be processed.
    private var pagesToProcess: [PageViewModel] = []
    /// internal list of visuals we are working on caching
    private var visualsToSnap: [VisualViewModel] = []
    /// the filter object from the SASReport.  This is the location filter.
    private var filterObject: SASCategoricalFilterControl? = nil
    /// the list of top locations from the report.
    private var topLocationsList: SASCategoricalFilterControl? = nil
    
    /// The page we are currently processing.  Note, it is important that we process one page
    /// at a time, since we need to set the filter for the page, and then get cached images/text for
    /// each visual on that page before moving on to the next page.
    private var currentPage: PageViewModel? = nil
    
    /// Are we currently processing the report?
    var hasVisualsToProcess: Bool{
        return pagesToProcess.count > 0 || visualsToSnap.count > 0
    }
    
    /// Start processing all over again.  This is an expensive opereation, so should
    /// only be called when something drastic happens like the report being updated.
    func reloadReport() {
        
        // If we are already in the middle of processing visuals, wait for them to finish.
        self.pause {
            self.filterObject = AppViewModel.shared.report?.loadReportObject(AppViewModel.shared.locationsFilterId) as? SASCategoricalFilterControl
            self.filterObject?.delegate = self
             
            // if the global location hasn't been added, then this is the first time we've run
            // the app and gotten to this point - we need to load the top locations filter
            // so we can start the app with the top 5 locations according to number of cases
            // this is a one time initialization - the locations will then be static and saved and
            // potentially customized by the user
            if AppViewModel.shared.userLocations.firstIndex(of: GlobalLocation) == nil {
                self.topLocationsList = AppViewModel.shared.report?.loadReportObject(AppViewModel.shared.topLocationsFilterID) as? SASCategoricalFilterControl
                self.topLocationsList?.delegate = self
            }
            
            // reset processing structures.
            self.pagesToProcess = []
            self.visualsToSnap = []
            
            for page in AppViewModel.shared.pages {
                self.pagesToProcess.append(page)
            }
            
            // we just finished pausing so need to resume.
            self.resume()
        }
    }
    
    /// Safely add a page to the queue to be processed, without adding duplicates.
    func addPageToProcess( _ pageModel:PageViewModel ) {
        if let _ = pagesToProcess.firstIndex(where: {$0 === pageModel}) {
            return
        }
        else {
            pagesToProcess.append(pageModel)
        }
    }
    
    /// This can be called at any point to ensure that processing is running.
    func checkPagesToProcess() {
        // Check pause progress...  We may need to enter a paused state.
        pauseCompletion()
        
        // if we are paused, dont do anything
        guard !isPaused else { return }
        
        // If we are already processing one page, then dont start another one yet.
        guard self.visualsToSnap.count == 0 else { return }
        
        // if the list is empty, then we are done.  Notify and return.
        guard let page = pagesToProcess.first else {
            NotificationCenter.default.post(Notification(name: AppViewModel.ReportUpdated))
            return
        }
        
        // dequeue the first page
        pagesToProcess.remove(at: 0)
        
        // set the current page to the one we dequeued.
        currentPage = page
        
        // process the current page.
        processPage()
    }
    
    /// Processing for the current page
    func processPage() {
        // Check pause progress...  We may need to enter a paused state.
        pauseCompletion()
        
        // if we are paused, dont do anything
        guard !isPaused else { return }
        
        // make sure we have a current page to work on.
        guard let page = currentPage else { return }
        
        // If this is the global page, then there is no filtering that
        // needs to occur.  Lets grab the visuals and return.
        if page.location == GlobalLocation {
            processVisuals(visuals: page.visuals)
            return
        }

        // ensure we have a filter object to process the locations with
        guard let filterObject = filterObject else { return }
        // if the filter objeect is busy, we need to wait until its done
        guard !filterObject.isBusy else { return }
        
        // need to make sure that the filter's selected value is the same
        // as the current page.   If its not, then lets set it, and wait for it
        // to be ready.
        if filterObject.selectedValue != page.location {
            filterObject.selectedValue = page.location
        }
        else {
            // The filter is ready, time to process the visuals on this page.
            processVisuals(visuals: page.visuals)
        }
    }
    
    /// Cache app resources for a set of visuals.
    func processVisuals(visuals: [VisualViewModel]) {
        // Check pause progress...  We may need to enter a paused state.
        pauseCompletion()
        
        // if we are paused, dont do anything
        guard !isPaused else { return }
        
        // track if we asked any visuals to render.
        var visualsRendering: Bool = false
        for visual in visuals {
            
            // guards to ensure we have a visual that we can work with
            //
            guard let objectID = visual.objectID else { continue }
            guard let report = AppViewModel.shared.report else { continue }
            visual.reportObject = report.loadReportObject(objectID)
            guard let ro = visual.reportObject else { continue }
            
            
            // If this is not a text object, ensure the object is not already in the visualsToSnapList
            if visual.reportObject is SASTextReportObject {
                // do nothing?
            } else if visualsToSnap.contains(where: { (v) -> Bool in v.objectID == objectID }) {
                continue
            }
            
            // If we already have a cache entry for this visual, nothing to do.
            guard !hasCachedImage(visual: visual) else { continue }
            guard !hasCachedText(visual: visual) else { continue }
            
            // At this point, we are going to try to render something.
            visualsRendering = true
            visualsToSnap.append(visual)
            
            if let textObj = visual.reportObject as? SASTextReportObject {
                // If we need to wait for the text object to finish processing, make sure we
                // are the delegate so we will be notified when its ready.
                if textObj.isBusy {
                    textObj.delegate = self
                } else {
                    // Get the text from the text object and cache it.
                    textObj.delegate = nil
                    let text = textObj.text
                    self.cacheText(text: text, reportID: AppViewModel.shared.reportId, filterValue: visual.filterValue ?? "", objectID: objectID)
                    self.cacheAccessibilityLabel(text: textObj.view.accessibilityLabel, reportID: AppViewModel.shared.reportId, filterValue: visual.filterValue ?? "", objectID: objectID)
                    visual.dynamicText = text
                    visual.thumbnail = nil
                    
                    // set things up for the next visual
                    prepareForNextVisual(visual)
                }
            }
            else {
                // Rendering a thumbnail is an asynchronous operation.  Ask for the thumbnail to be rendered, and wait
                // for it to finish.
                ro.renderToThumbnail(size: visual.visualSize, withTitle: !visual.externalTitle) { (reportObject, image) in
                    
                    // Cache the image now that we have it.
                    self.cacheImage(image: image, reportID: AppViewModel.shared.reportId, filterValue: visual.filterValue ?? "", objectID: objectID, size: visual.visualSize)
                    // Cache the accessibility label.
                    self.cacheAccessibilityLabel(text: reportObject.view.accessibilityLabel, reportID: AppViewModel.shared.reportId, filterValue: visual.filterValue ?? "", objectID: objectID)
                    // nil out the view on screen, this will force it to re-read it from the cache.
                    visual.thumbnail = image
                    visual.dynamicText = nil
                    
                    // set things up for the next visual
                    self.prepareForNextVisual(visual)
                }
            }
        }
        
        // If we are not waiting on any rendering visuals, then
        // we may need to start the next page.
        if !visualsRendering {
            checkPagesToProcess()
        }
    }
    
    /// Check for the next visual.  Need to remove the one being passed in, and check for
    /// more to capture.
    func prepareForNextVisual(_ visual:VisualViewModel) {
        self.visualsToSnap = self.visualsToSnap.filter { $0.objectID != visual.objectID }
        
        // we are done with the current batch.  Send a notification that this page is done, and check for more pages.
        if self.visualsToSnap.count == 0 {
            NotificationCenter.default.post(name: AppViewModel.PageThumbnailsUpdated, object: self.currentPage)
            self.checkPagesToProcess()
        }
    }
    
    // MARK: SASReportObjectDelegate
    
    /// filter is busy
    func reportObjectIsBusy(object: SASReportObject) { }
    
    //  The report filter (or top location list) is ready to use.
    func reportObjectIsReady(object: SASReportObject) {
        // Location Filter object
        if object.objectName == self.filterObject?.objectName {
            // now that the filter is ready, we should add
            // gps locations. It must be in the filter list (and not be a dup).
            for loc in AppViewModel.shared.gpsLocations {
                if AppViewModel.shared.availableLocations.contains(loc), !AppViewModel.shared.userLocations.contains(loc) {
                    AppViewModel.shared.userLocations.insert(loc, at: AppViewModel.shared.userLocations.count > 0 ? 1 : 0 )
                }
            }
            // these have been processed.  clear the list.
            AppViewModel.shared.gpsLocations = []
        }
        // top location list
        else if object.objectName == self.topLocationsList?.objectName, AppViewModel.shared.userLocations.firstIndex(of: GlobalLocation) == nil, let topLocationsList = topLocationsList {
            var topLocations:[String] = []
            // we might have a user location - if the gps location populated first
            // but we don't want to have a duplicate either; also the gps locations should be the
            // first locations in the user list
            var uniqueValues = topLocationsList.uniqueValues
            
            // filter out the ones we already have.
            for loc in AppViewModel.shared.userLocations {
                if let index = uniqueValues.firstIndex(of: loc) {
                    uniqueValues.remove(at: index)
                }
            }
            
            topLocations.insert(contentsOf: AppViewModel.shared.userLocations, at: 0)
            topLocations.insert(GlobalLocation, at: 0)
            topLocations.append(contentsOf: uniqueValues)
                
            // This is now the set of all top locations, user locations and the "global" location
            AppViewModel.shared.userLocations = topLocations
        }
        
        // kick off processing.
        processPage()
    }
    
    /// Data has changed for an object.  this is most likely because we set the
    /// filter current value.
    func reportObjectDataChanged(object: SASReportObject) {
        //kick off processing
        processPage()
    }

    /// We do not do anything here with tooltip events...
    func willHandleDataTip(object: SASReportObject, info: SASDataTip) -> Bool {
        return false
    }
    /// We do not do anything here with tooltip events...
    func showDataTip(object: SASReportObject, info: SASDataTip) {}
    /// We do not do anything here with tooltip events...
    func hideDataTip(object: SASReportObject, info: SASDataTip) {}
}
