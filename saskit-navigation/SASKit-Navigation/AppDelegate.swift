//
//  AppDelegate.swift
//  SASKit-Navigation
//
//  Created by Rich Hogan on 6/20/19.
//  Copyright © 2019 DVR. All rights reserved.
//

import UIKit
import SASKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, SASManagerDelegate, SASReportNavigationDelegate {
    var window: UIWindow?
    var server:SASServer?
    func handleSASManagerReady()
    {
        let serverDescriptor = SASServerDescriptor(URL(string: "http://your.server.com")!, serverUserid: "<username>")
        serverDescriptor.password = "<password>"

        SASManager.shared.verifySASServer(serverDescriptor)
        { (server, error) in
            self.server = server
            server?.connect({ (error) in
                let descriptor = SASReportDescriptor(identifier: "########-####-####-####-############")
                server?.subscribe(descriptor: descriptor, completion:
                    { (report, error) in
                        guard let reportView = report?.createViewController(nil) else { return }
                        
                        report?.navigationDelegate = self
                        
                        if let navController = self.window?.rootViewController as? UINavigationController
                        {
                            navController.pushViewController(reportView.viewController, animated: true)
                        }
                })
            })
        }
    }

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        SASManager.initialize(delegate: self)
        {_ in
            self.handleSASManagerReady()
        }
        return true
    }
    
    // MARK: ReportViewController Navigation Delegate
    func navigate(url: URL, navigationDescriptor: SASReportNavigationDescriptor) {
        UIApplication.shared.open(url, options: [:], completionHandler: nil)
    }
    
    func navigate(report: SASReportDescriptor, navigationDescriptor: SASReportNavigationDescriptor) {
        server?.subscribe(descriptor: report, completion: { (report, error) in
            guard let reportView = report?.createViewController(nil, navigationDescriptor: navigationDescriptor) else { return }
            
            report?.navigationDelegate = self
            
            if let navController = self.window?.rootViewController as? UINavigationController
            {
                navController.pushViewController(reportView.viewController, animated: true)
            }
        })
    }
    
    func navigate(page: Int, navigationDescriptor: SASReportNavigationDescriptor) {
    }
    
}

