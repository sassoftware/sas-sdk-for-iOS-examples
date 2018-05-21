# Getting Started: Preconfigure server connections and reports

Preconfiguring server connections and reports subscriptions can be achieved by replacing a *json* file or through code.
## Preconfigure by replacing ***sas-sdk-servers.json***
Benefits of updating the json file - 
* No coding is required.
* Simple to update and maintain.
* Applies to all the users of the app.

```Perl
{
    "servers": [
    {
        "reportPaths": [
                        "/reports/reports/faca01f6-c631-4cbf-b336-6ba186dc632e",
                        "/reports/reports/1ccd88c8-38a6-4473-90e0-8bdb447510a4",
                        "/reports/reports/03db38a7-ff39-460e-9aca-3ee108c10140",
                        "/reports/reports/cd4205df-44a8-448a-a174-765f89abe058"
                        ],
        "serverHostName": "tbub.sas.com",
        "serverPort": "443",
        "useGuestMode": "true",
        "useSSL": "true",
        "serverDescription" : "\_i18n:sas_demo_server",
        "isDemo" : "true"
    }]
}
```
*example of custom sas-sdk-servers.json file*


## Preconfiguring through code
Benefits of writing code:
* Support custom server connections and report subscriptions based on user information or other logic with your mobile app.

***Create handleReportsAvailable() to contain app serve & report preconfiguration functionality.***
```Perl
class AppDelegate: UIResponder, UIApplicationDelegate, SASManagerDelegate
{
    //MARK: Notification Listeners
    func handleReportsAvailable()
    {
```
***Specify server connection URL and report names & ids.***
```Perl
        // SAS public sample report server
        let url : URL = URL(string: "https://tbub.sas.com:443")!
        
        // UUIDs of reports on sample server
        let reports : [String : String ] = ["Warranty Analysis" : "faca01f6-c631-4cbf-b336-6ba186dc632e" ,
                                            "Capital Campaign"  : "03db38a7-ff39-460e-9aca-3ee108c10140" ,
                                            "Retail Insights"   : "1ccd88c8-38a6-4473-90e0-8bdb447510a4" ,
                                            "Water Consumption and Monitoring" : "cd4205df-44a8-448a-a174-765f89abe058"]      
```

***Verify server connection is valid, login, and subscribe to the report "Retail Insights."***
```Perl
        // attempt server verification
        SASManager.shared.verifySASServer( url )
        { (server, error) in
            
            if (self.USE_GUESTMODE)
            {
                server?.guestMode = true
            }
            else
            {
                server?.userid = ""
                server?.password = ""
            }

            server?.connect
            { (error) in
                
                var descriptor : SASReportDescriptor? = nil

                let reportUUID : String = reports["Retail Insights"]!
                descriptor = SASReportDescriptor(identifier: reportUUID)
                
                server?.subscribe(descriptor: descriptor!)
                { (report, error ) in
                    
                    if report != nil
                    {
                        let vc : SASReportViewController = (report?.createViewController())!
                        self.window?.rootViewController = vc as? UIViewController;
                    }
                    else
                    {
                        print(error as Any)
                    }
                }

            }
        }
    }
```
***Call handleReportsAvailable() as part of the UIApplicationDelegate life-cycle method - application().***
```
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool
    {
        SASManager.initialize(delegate: self)
        {_ in
            self.handleReportsAvailable()
        }
        
        // Override point for customization after application launch.
        return true
    }
```




