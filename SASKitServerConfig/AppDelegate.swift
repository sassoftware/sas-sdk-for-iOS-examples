//
//  AppDelegate.swift
//  SASKitServerConfig
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
class AppDelegate : SASApplicationDelegate
{
    let serverJson = """
        {
            "servers": [
            {
                "reportPaths": [
                    "/reports/reports/faca01f6-c631-4cbf-b336-6ba186dc632e",
                    "/reports/reports/1ccd88c8-38a6-4473-90e0-8bdb447510a4"
                ],
                "serverHostName": "tbub.sas.com",
                "serverPort": 443,
                "useGuestMode": true,
                "useSSL": true,
                "serverDescription" : "_i18n:sas_demo_server",
                "isDemo" : true
            }]
        }
    """
    
    override open func getDefaultServerConfiguration() -> Data
    {
        let jsonData = Data( serverJson.utf8 )
        return jsonData
    }
    
    override func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool
    {
        let ret : Bool = super.application(application, didFinishLaunchingWithOptions: launchOptions)
        self.applicationDidBecomeActive(application)
        
        return ret
    }
    
}

