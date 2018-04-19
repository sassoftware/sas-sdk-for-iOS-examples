//
//  AppDelegate.swift
//  SASKitMasterDetail
//
//  Copyright © 2017 SAS Institute. All rights reserved.
//

import UIKit

import SASKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, UISplitViewControllerDelegate
{

    var window: UIWindow?

    static func IS_IPHONE() -> Bool
    {
        let keyWindow = UIApplication.shared.keyWindow
        return (( UIDevice.current.userInterfaceIdiom == .phone ) || ( keyWindow != nil && keyWindow!.traitCollection.horizontalSizeClass == .compact ) )
    }


    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool
    {
        // Override point for customization after application launch.
        let splitViewController = self.window!.rootViewController as! UISplitViewController
        let navigationController = splitViewController.viewControllers[splitViewController.viewControllers.count-1] as! UINavigationController
        navigationController.topViewController!.navigationItem.leftBarButtonItem = splitViewController.displayModeButtonItem
        splitViewController.delegate = self
        return true
    }

    // MARK: - Split view
    // launch split view to master view on iPhone launch
    func splitViewController(_ splitViewController: UISplitViewController, collapseSecondary secondaryViewController: UIViewController, onto primaryViewController: UIViewController) -> Bool
    {
        // Return YES to prevent UIKit from applying its default behavior
            if AppDelegate.IS_IPHONE()
            {
                return true
            }
            else
            {
                return false
            }
    }

}

