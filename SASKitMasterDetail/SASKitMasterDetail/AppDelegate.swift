//
//  AppDelegate.swift
//  SASKitMasterDetail
//

// Copyright 2018 SAS Institute Inc.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// https://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

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

