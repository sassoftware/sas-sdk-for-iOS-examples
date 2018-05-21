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

***Specify server connection URL and report ids.***
```Perl
class MasterViewController: UITableViewController, AnnotationHelperDelegate, ReportDetailsCapabilitiesDelegate, SASManagerDelegate
{
    // SAS public sample report server
    let url : URL = URL(string: "https://tbub.sas.com:443")!
    
    // UUIDs of reports on sample server
    let reports : [String : String ] = ["Warranty Analysis" : "faca01f6-c631-4cbf-b336-6ba186dc632e" ,
                                        "Capital Campaign"  : "03db38a7-ff39-460e-9aca-3ee108c10140" ,
                                        "Retail Insights"   : "1ccd88c8-38a6-4473-90e0-8bdb447510a4" ,
                                        "Water Consumption and Monitoring" : "cd4205df-44a8-448a-a174-765f89abe058"]
```

***Add addReportsDynamically() function to contain preconfiguration server functionality. Verify server connection is valid.***
```Perl
    var reportDetailsViewController : UIViewController? = nil

    var reportList : [SASReport] = Array()
    
    func addReportsDynamically()
    {
        // attempt server verification
        SASManager.shared.verifySASServer( url )
        { (server, error) in
```
***Iterate through report unique identifiers (UUIDs).***

```Perl
       for (_ , reportUUID) in self.reports
       {
           // subscribe reports
           let descriptor : SASReportDescriptor = SASReportDescriptor(identifier: reportUUID)
           server?.subscribe( descriptor: descriptor )
           { (report, error ) in
               if (report != nil && error == nil)
               {
                   if (self.listContains(list: self.reportList, uniqueIdentifier: (report?.identifier)!) == false)
                   {
                       self.reportList.append(report!)
                   }
```
***Override the viewDidLoad() function and call addReportsDynamically().***

```Perl
    override func viewDidLoad()
    {
        super.viewDidLoad()
        SASManager.initialize(delegate: self)
        {_ in
            self.addReportsDynamically()
        }
    }
```


