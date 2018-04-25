#  SASKit-Samples
SASKit-Samples are XCode projects that demonstrate usage of the SASKit framework enabling iOS developers to build customized apps that include content from [SAS® Visual Analytics](https://www.sas.com/en_us/software/visual-analytics.html).


## Getting SASKit Framework
Access the SASKit installer (SASKit.pkg) from the [developer.sas.com Mobile SDK site](https://developer.sas.com/guides/mobile-sdk.html). This site also includes access to the [SASKit Documentation](https://developer.sas.com/sdk/mobile/iOS/doc/8.22/). Upon running the installation the SASKit framework is installed in "/Library/Frameworks".

For information, advice, and questions on the use of SAS Mobile SDKs please start with the [SAS Visual Analytics online community](https://communities.sas.com/Visual-Analytics).


## Open XCode Workspace

>NOTE: Because Swift does not yet have ABI compatibility, we are required to package the swift runtime with the built framework.   This means that consumers of the framework must compile apps that use the framework with the same swift version as was used for compiling the framework.   For release 8.22, the framework was built with Xcode 9.2 (9C40b).

Once SASKit framework is installed you can open SASKit-Samples.xcworkspace in XCode and build each of the projects to run on device simulators right away.

In order to build for a physical device, the bundle ID for the projects need to be changed from "com.your-domain.<appname>" to use the domain specified in your developer account.  Wildcard apps (com.your-domain.*) or specific apps for each of the samples (com.your-domain.<appname>) can be set up at developer.apple.com under your organizations' developer account.  Also, the signing ID for the projects will need to be configured in order to build to run on device.


## Apps

    * SASKitCustomApp
SAS Mobile BI is wrapped in a custom application.  This sample demonstrates deriving an application delegate from SASApplicationDelegate.

    * SASKitFullscreen
This sample demonstrates deriving an application delegate from SASManagerDelegate, connecting to a specified server, and  displaying a report in full screen.

    * SASKitMasterDetail
This sample demonstrates showing multiple reports that are maintained in a list and can be selected and displayed full screen.
