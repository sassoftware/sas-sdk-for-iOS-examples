//
//  AppDelegate.swift
//  corona-virus
//
//  Copyright © 2020 SAS. All rights reserved.
//

import UIKit
import SASKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, SASManagerDelegate {
    
    /// MARK: SASManagerDelegate
    func shouldCheckForUpdatesOnOpenReports() -> Bool {
        return true
    }

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {

        // SAS MANAGER INIT
        SASManager.initialize(delegate: self)
        {_ in
            // check for migration.
            self.doMigration()
            
            // read the user settigns from disk
            AppViewModel.shared.readUserSettings()
            
            // Let the AppViewModel know to get things going.
            AppViewModel.shared.sasAvailable()
        }
        
        // UI APPEARANCE
        let pageControl = UIPageControl.appearance()
        pageControl.currentPageIndicatorTintColor = UIColor(named: "Default foreground")
        pageControl.pageIndicatorTintColor = pageControl.currentPageIndicatorTintColor?.withAlphaComponent(0.5)
        
        return true
    }
    
    /// The current version of the app.
    var version: SemanticVersion {
        guard let appVersionString: String = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String else { return .zero }
        return SemanticVersion.createSemanticVersion(versionString: appVersionString)
    }
    
    /// If this is a new version, we need to do some processing...
    func doMigration() {
        let lastRunVersion = SemanticVersion.createSemanticVersion(versionString: UserDefaults.standard.string(forKey: "lastRunVersion") ?? "")

        // Pre-release versions need to have the cache invalidated....
        if lastRunVersion == .zero {
            ReportObjectCache.shared.invalidateCache()
        }
        
        if self.version > lastRunVersion {
            // HANDLE MIGRATION TO NEWER VERSIONS HERE
            let defaults = UserDefaults.standard
            if  let userCountries = defaults.array(forKey: "userCountries"),
                defaults.array(forKey: "userLocations") == nil {
                defaults.set(userCountries, forKey: "userLocations")
                defaults.removeObject(forKey: "userCountries")
            }
        }
        
        UserDefaults.standard.set(self.version.asString(), forKey: "lastRunVersion")
    }
}

