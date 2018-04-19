//
//  CustomMobileBIAppDelegate.swift
//  SASKitCustomApp
//
//  Copyright © 2017 SAS Institute. All rights reserved.
//

import UIKit

import SASKit

@UIApplicationMain
class CustomMobileBIAppDelegate : SASApplicationDelegate
{
    
    override func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool
    {
        // Override point for customization after application launch.
        let ret : Bool = super.application(application, didFinishLaunchingWithOptions: launchOptions)
        self.applicationDidBecomeActive(application)
        return ret
    }

}

