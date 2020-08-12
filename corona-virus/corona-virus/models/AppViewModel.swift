//
//  AppViewModel.swift
//  corona-virus
//
//  Copyright © 2020 SAS. All rights reserved.
//

import Foundation
import CoreLocation
import SASKit

// Key for the "global" page.
let GlobalLocation = "__GLOBAL__"

/// This class is the ViewModel for the application.
///
/// Protocol conformance:
/// - NSObject
/// - Codable: the inital state of this class is encoded in json and bundled with the app.
/// - SASReportDelegate:  We need to know when the report (or its data) have been updated, so we can
///                       update the view (and the cache)
/// - SASReportNavigationDelegate:  The legal page contains exernal links to data sources, etc...   The user
///                                 can tap on these links in the app, and the visual will generate the correct URL for
///                                 the app to link to.
/// - CLLocationManagerDelegate: This allows the app to determine the current location so we can add location based on device
///                              location.
class AppViewModel : NSObject, Codable, SASReportDelegate, SASReportNavigationDelegate, CLLocationManagerDelegate {
    /// Descriptor to identify the report.
    var reportDescriptor: SASReportDescriptor {
        SASReportDescriptor(identifier: reportId)
    }
    
    /// URL that the server is located at.
    var sasServerURL: URL {
        return URL(string: sasServerURLString)!
    }
    
    /// This is a singleton object.  All access should be from shared.
    static let shared: AppViewModel = Bundle.main.decode(AppViewModel.self, from:"AppViewModel.json")
    
    // MARK: Events
    
    /// Event to dispatch when the list of locations have changed.
    static let LocationsChanged = Notification.Name("LocationsChanged")
    /// Event to dispatch when the current location changes (user switches pages)
    static let CurrentLocationChanged = Notification.Name("CurrentLocationChanged")
    /// Event to dispatch when we are done updating the report.
    static let ReportUpdated = Notification.Name("ReportUpdated")
    /// Event to dispatch when images are done processing for a page.
    static let PageThumbnailsUpdated = Notification.Name("PageThumbnailsUpdated")
    /// Event to dispatch when the report begins checking for updates.
    static let ReportCheckingUpdates = Notification.Name("ReportCheckingUpdates")
    /// Event to dispatch when the report is updating.
    static let ReportUpdating = Notification.Name("ReportUpdating")
    
    /// location manager for getting device location.
    private let locationManager = CLLocationManager()
    
    // MARK: Codable
    
    /// The keys to use for deserialization.
    enum CodingKeys: CodingKey {
        case legalObjectID
        case reportId
        case locationsFilterId
        case topLocationsFilterID
        case sasServerURLString
        case currentLocation
    }
    
    /// The identifier of the location filter object in the report.
    var locationsFilterId: String = ""
    /// The identifier of the top locations list object in the report.
    var topLocationsFilterID: String = ""
    /// The list of pages to display
    var pages: [PageViewModel] = []
    /// the identifier of the object with the legal text to display in the app.
    var legalObjectID: String = ""
    /// the unique id of the report on the server
    var reportId: String = ""
    /// The url of the server.
    var sasServerURLString: String = ""
    
    /// The list of gps locations retrieved from the device.
    var gpsLocations: [String] = []
    
    /// The locations filter control object from the report
    var locationsFilterControl: SASCategoricalFilterControl? = nil

    /// Used to coordinate the scroll position of all of the pages.
    var locationPageOffset:CGPoint?
    
    /// Read the user settings that are stored in UserDefaults
    func readUserSettings() {
        // We store user locations anytime the user locations change (including the first launch of the app).
        // If we have stored user locations, lets use those.
        if let uc = UserDefaults.standard.object(forKey: "userLocations") as? [String] {
            self.userLocations = uc
        }
        // If we dont have stored user locations, this is the first launch of the app.  Lets
        // try to get the gps location of the device and use that.
        else {
            self.locationManager.requestWhenInUseAuthorization()
            if CLLocationManager.locationServicesEnabled() {
                locationManager.delegate = self
                locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
                locationManager.startUpdatingLocation()
            }
        }
        
        // Fetch the "current" page, and reflect that in the view.
        if let cp = UserDefaults.standard.object(forKey: "currentPage") as? String {
            self.currentLocation = cp
        }
    }
    
    /// Store the current state of the app to disk, so that on future restarts of the app,
    /// we can return the user to the last state.
    func serializeToDisk() {
        UserDefaults.standard.set(self.currentLocation, forKey: "currentPage")
        UserDefaults.standard.set(self.userLocations, forKey: "userLocations")
        UserDefaults.standard.synchronize()
    }
    
    /// The current page in the app.
    var currentLocation: String = GlobalLocation {
        didSet(oldValue) {
            // When the current location changes, we need to re-serialize to disk,
            // and send a notification so that the app can react to this model change.
            if oldValue != currentLocation {
                self.serializeToDisk()
                NotificationCenter.default.post(Notification(name: AppViewModel.CurrentLocationChanged))
            }
        }
    }
    
    /// The SASServer we are getting the report from.
    var sasServer: SASServer? = nil
    
    /// The report we are working with.
    var report: SASReport? = nil {
        
        /// If the report changes (or when it loads), we need to reset all of our
        /// internal structures.
        willSet(newValue) {
            report?.navigationDelegate = nil
            report?.unloadReportObject(self.locationsFilterId)
            report?.unloadReportObject(self.topLocationsFilterID)
            self.locationsFilterControl = nil
            
            for page in self.pages {
                page.report = nil
            }
        }
        
        /// When we get a new report, reload the report objects we need, and set ourselves as delegates to the report.
        didSet(oldValue) {
            locationsFilterControl = report?.loadReportObject(locationsFilterId) as? SASCategoricalFilterControl

            for page in pages {
                page.report = report
            }
            
            report?.delegate = self
            report?.navigationDelegate = self
        }
    }
    
    /// Are we trying to update the report?
    var isUpdating: Bool = false
    
    /// Force a cheek for updates.
    func updateReport() {
        // not if we are already trying to run an update!
        guard !isUpdating else { return }
        // make sure we have a report to update.
        guard let report = self.report else { return }
            
        // yep, now we are updating.
        isUpdating = true
        
        // If we ask for an update, and dont get an answer in 2min, something has
        // gone wrong..  This sets up a timer, so we can quit waiting on the update.
        perform(#selector(tiredOfWaitingForUpdate), with: nil, afterDelay: 120)
        
        // ask the report to check for an update, and download updates if applicable.
        report.update { (status, error) in
            
            // we are downloading updated assets.  Lets notify the UI, so it can reflect this...
            if status == .updateDownloadBegan {
                NotificationCenter.default.post(Notification(name: AppViewModel.ReportUpdating))
            }
            
            // There was no update.
            if status == .noUpdate {
                NotificationCenter.default.post(Notification(name: AppViewModel.ReportUpdated))
                self.isUpdating = false
            }
            
            // If the update is still in progress, then return here.  We will get
            // more callbacks when the update is done.
            guard status.isFinished else { return }

            // We got an update!  we can cancel the bail-out timer.
            NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(self.tiredOfWaitingForUpdate), object: nil)
            
            // This should not happen, but if we did not trigger this, then lets get out of here...
            guard self.isUpdating else { return }
            
            // deal with an error condition.  For our purposes, we can pretend the update happened. We will
            // check again later..
            guard error == nil else {
                NotificationCenter.default.post(Notification(name: AppViewModel.ReportUpdated))
                self.isUpdating = false
                return
            }
            
            // done handling this update.
            self.isUpdating = false
            
            // reset our data structures so we can reload the update.
            self.reportUpdated(report: report)
        }
    }
    
    /// This is a bail-out for a non-responsive server.  This could happen if the device loses
    /// network connectivity, or some other non-recoverable scenario.   In this case, the app
    /// pretends the update happened, and will carry on with the data we already have.   The app will
    /// check again later for data updates, so no big deal.
    @objc func tiredOfWaitingForUpdate() {
        self.isUpdating = false
        
        // report isn't actually trying to update anymoree
        NotificationCenter.default.post(Notification(name: AppViewModel.ReportUpdated))
    }
    
    /// Get a page view model for a location identifier.
    func pageForLocation(_ location: String) -> PageViewModel? {
        for page in pages {
            if page.location == location {
                return page
            }
        }
        
        return nil
    }
    
    /// The set of locations for the app.  This can change based on several things:
    /// * top locations
    /// * GPS location
    /// * the manage location screen.
    var userLocations: [String] = [] {
        /// When the user locations changes, we need to process this location in the
        /// ReportObjectCache.  We also need to adjust our view model for the added/removed/moved
        /// locations.
        didSet(oldValue) {
            if oldValue != userLocations
            {
                var newPagesList: [PageViewModel] = []
                
                for loc in self.userLocations {
                    // If we already have this location loaded, just use it.
                    if let page = pageForLocation(loc) {
                        newPagesList.append(page)
                        continue
                    }
                    
                    // this is a new location, create a new page model for this location.
                    let newPage = createUserPage(location: loc)
                    newPagesList.append(newPage)
                    
                    // Tell the cache to process this page.
                    ReportObjectCache.shared.addPageToProcess(newPage)
                }
                
                // This is our new page list.
                pages = newPagesList
                
                // The locations have changed, lets save that to disk
                self.serializeToDisk()
                
                // Let the UI know that the locations have changed.
                NotificationCenter.default.post(Notification(name: AppViewModel.LocationsChanged))
                // Kick off the processing in the cache.
                ReportObjectCache.shared.checkPagesToProcess()
            }
        }
    }
    
    /// this returns all of the possible locations, including the user's locations
    var availableLocations: [String] {
        guard let filterControl = self.locationsFilterControl else { return [] }
        return filterControl.uniqueValues
    }
    
    /// Create the global location.
    func createGlobalPage() -> PageViewModel {
        // we store the template for this page in the app bundle as json.
        let globalPage = Bundle.main.decode(PageViewModel.self, from: "GlobalPageTemplate.json")
        
        // fetch all of the needed images/text from the cache.
        for visual in globalPage.visuals {
            if let image = ReportObjectCache.shared.getCachedImage(filterValue: "", objectID: visual.objectID ?? "", size: visual.visualSize) {
                visual.thumbnail = image
                visual.dynamicText = nil
            } else if let text = ReportObjectCache.shared.getCachedText(filterValue: "", objectID:visual.objectID ?? "" ) {
                visual.dynamicText = text
                visual.thumbnail = nil
            }
        }
        return globalPage
    }
    
    /// Create a "location" page.
    func createUserPage(location:String) -> PageViewModel {
        /// the global location is a special case with its own template.
        if location == GlobalLocation {
            return createGlobalPage()
        }
        
        // we store the template for this page in the app bundle as json.
        let page: PageViewModel = Bundle.main.decode(PageViewModel.self, from: "LocationPageTemplate.json")
        page.location = location
        
        // fetch all of the needed images/text from the cache.
        for visual in page.visuals {
            if let image = ReportObjectCache.shared.getCachedImage(filterValue: location, objectID: visual.objectID ?? "", size: visual.visualSize) {
                visual.thumbnail = image
                visual.dynamicText = nil
            } else if let text = ReportObjectCache.shared.getCachedText(filterValue: location, objectID:visual.objectID ?? "" ) {
                visual.dynamicText = text
                visual.thumbnail = nil
            }
        }

        // update the visual with the filter value.
        for visual in page.visuals {
            visual.filterValue = location
        }
        
        return page
    }
    
    /// This is called by the AppDelegate when SASManager has finished initialization.
    func sasAvailable() {
        // populate the pages list.
        if self.pages.isEmpty {
            for loc in userLocations {
                self.pages.append(createUserPage(location:loc))
            }
        }
        
        // Have we already got a connection to the server?
        if let server = SASManager.shared.sasServer(SASServerDescriptor(sasServerURL)) {
            // Yes?  lets check to see if we have the report already subscribed.
            self.sasServer = server
            checkReport()
        }
        else {
            // No.  We need to connect to the server.
            connectToServer()
        }
    }
    
    /// Establish a connection to the server.
    func connectToServer() {
        // verify that the server is reachable and is a valid SAS Visual Analytics install.
        SASManager.shared.verifySASServer(SASServerDescriptor(sasServerURL)) { (server, error) in
            // Error?  not much more we can do...
            guard error == nil else { return }

            // We know the server is there (and is responding).   lets connect!
            server?.connect({ (error) in
                // We now have a connection to the server.  Lets subscribe to the report we need.
                self.sasServer = server
                self.checkReport()
            })
        }
    }
    
    /// Subscribe (if needed) and start processing the report.
    func checkReport() {
        // If we dont have a server, this will not work at all.
        guard let server = self.sasServer else { return }
        
        // Do we already have a subscription?
        if let baseReport = server.getSubscribedReport(descriptor: AppViewModel.shared.reportDescriptor) {
            // Yes!  lets use it.
            self.report = baseReport
            
            // this is needed here, even though we might call it again in self.updateReport
            // it's needed for the cases where we do not have an update, so that the filters
            // can be set up and so we can load any images that may have been cleared and not
            // regenerated on a previous run
            ReportObjectCache.shared.reloadReport()
            NotificationCenter.default.post(Notification(name: AppViewModel.ReportCheckingUpdates))
            
            // we have already subscribed, but it may have updated on the server.
            self.updateReport()
        }
        else {
            // No.  We need to subscrive to the report.
            server.subscribe(descriptor: AppViewModel.shared.reportDescriptor) { (report, error) in
                guard let report = report else { return }
                self.report = report
                
                // we just subscribed, so no need to check for an update.  Just start processing it.
                ReportObjectCache.shared.reloadReport()
            }
        }
    }
    
    /// fetch a UIView for a report object.
    func getVisualView( _ objectID: String ) -> UIView? {
        guard let report = report else { return nil }
        // This will load an individual report object from the report.
        guard let reportObject = report.loadReportObject( objectID ) else { return nil }
        
        // we can get a UIView that will render this object from the report object.
        return reportObject.view
    }
    
    /// Helper method to assign a delegate to a report object.
    func assignDelegate( _ objectID: String, delegate:SASReportObjectDelegate? ) {
        guard let report = report else { return }
        guard let reportObject = report.loadReportObject(objectID) else { return }
        
        reportObject.delegate = delegate
    }
    
    // MARK: CLLocationManagerDelegate
    
    /// we got location(s) from the device
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let location = locations.first {
            let geoCoder = CLGeocoder()
            // try to figure out what the name of this location is based on the lat/long.
            geoCoder.reverseGeocodeLocation(location, completionHandler: {(placemarks, error) in
                if (error != nil) {
                    // bummer, we are not able to use the location info from this device
                    print("reverse geodcode fail: \(error!.localizedDescription)")
                    self.locationManager.stopUpdatingLocation()
                }
                
                // need to make sure we have something to look at...
                guard let placemarks = placemarks else {
                    print("Placemarks is nil")
                    self.locationManager.stopUpdatingLocation()
                    return
                }
                
                // there are placemarks, lets try to see if the report's filter has these locations in it.
                if let pm = placemarks.first, let countryCode = pm.isoCountryCode, let country = NSLocale.init(localeIdentifier: "en_US").displayName(forKey: NSLocale.Key.countryCode, value: countryCode) {
                       if !AppViewModel.shared.userLocations.contains(country) {
                            AppViewModel.shared.gpsLocations.append(country)
                            self.locationManager.stopUpdatingLocation()
                    }
                }
            })
        }
    }
    
    /// Error handling for CLLocationManager.
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Failed to find user's location: \(error.localizedDescription)")
    }
    
    // MARK: SASReportDelegate
    
    /// The report is checking periodically on its own for data and report updates.  If
    /// it determines there is an update, this delegate method will be called.  For our purposes, we
    /// just force an udpate.
    func dataUpdated(report: SASReport) {
        self.updateReport()
    }
    
    /// The report is checking periodically on its own for data and report updates.  If
    /// it determines there is an update, this delegate method will be called.  (This is also
    /// called from our manual update method after a succeessful update).   This method nil's out
    /// all of our internal structures, and then tells the cache to invalidate and rebuild things.
    func reportUpdated(report: SASReport) {
        self.isUpdating = false
        // force an unload of the report
        let rept = self.report
        self.report = nil
        self.report = rept
        
        ReportObjectCache.shared.invalidateCache()
        ReportObjectCache.shared.reloadReport()
    }
    
    // MARK: SASReportNavigationDelegate
    
    /// The "Legal" view is a text object from the report with links to more information on the web.
    /// The user can follow these links.  We will just redirect to the OS, this will launch the URL in a browser.
    func navigate(url: URL, navigationDescriptor: SASReportNavigationDescriptor) {
        UIApplication.shared.open(url, options: [:], completionHandler: nil)
    }
    
    /// No Report Navigation in this particular report we need to worry about
    func navigate(report: SASReportDescriptor, navigationDescriptor: SASReportNavigationDescriptor) {
    }
    
    /// No Section Navigation in this particular report we need to worry about
    func navigate(page: Int, navigationDescriptor: SASReportNavigationDescriptor) {
    }
}

