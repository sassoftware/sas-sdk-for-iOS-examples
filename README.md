#  SASKit-Samples

SASKit-Samples are XCode projects that demonstrate usage of the SASKit framework, which enables iOS developers to make customized apps that display reports created using SAS Visual Analytics (VA).


## Getting SASKit Framework

Register at www.sas.com and download the SASKit installer (SASKit.pkg) which installs SASKit.framework at "/Library/Frameworks"


## Open XCode Workspace
Once SASKit framework is installed you can open SASKit-Samples.xcworkspace in XCode and build each of the projects to run on device simulators right away.

In order to build for a physical device, the bundle ID for the projects need to be changed from "com.your-domain.<appname>" to use the domain specified in your developer account.  Wildcard apps (com.your-domain.*) or specific apps for each of the samples (com.your-domain.<appname>) can be set up at developer.apple.com under your organizations' developer account.  Also, the signing ID for the projects will need to be configured in order to build to run on device.


## Apps

    * SASKitCustomApp
SAS Mobile BI is wrapped in a custom application.  This sample demonstrates deriving an application delegate from SASApplicationDelegate.

    * SASKitFullscreen
This sample demonstrates deriving an application delegate from SASManagerDelegate, connecting to a specified server, and  displaying a report in full screen.

    * SASKitMasterDetail
This sample demonstrates showing multiple reports that are maintained in a list and can be selected and displayed full screen.
