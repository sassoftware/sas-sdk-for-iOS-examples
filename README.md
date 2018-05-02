#  SASKit-Samples
SASKit-Samples are XCode projects that demonstrate using the SASKit framework enabling iOS developers to build customized apps that include content from [SAS® Visual Analytics](https://www.sas.com/en_us/software/visual-analytics.html). The SAS SDK lets you build  mobile apps that you can personalize, pre-configure, customize, and manage to meet your exact requirements.


## Getting SASKit Framework
Access the SASKit installer (SASKit.pkg) from the [developer.sas.com Mobile SDK site](https://developer.sas.com/guides/mobile-sdk.html). This site also includes access to the [SASKit Documentation](https://developer.sas.com/sdk/mobile/iOS/doc/8.22/). After running the installation the SASKit framework is installed in "/Library/Frameworks".

For information, advice, and questions on the use of SAS Mobile SDKs please start with the [SAS Visual Analytics online community](https://communities.sas.com/Visual-Analytics).


## Open XCode Workspace

>NOTE: Because Swift does not yet have ABI compatibility, we are required to package the swift runtime with the built framework. This means that consumers of the framework must compile apps that use the framework with the same swift version as was used for compiling the framework. For release 8.22, the framework was built with Xcode 9.2 (9C40b).

Once the SASKit framework is installed you can open SASKit-Samples.xcworkspace in XCode and build each of the projects to run on device simulators right away.

In order to build for a physical device, the bundle ID for the projects need to be changed from "com.your-domain.<appname>" to use the domain specified in your developer account. Wildcard apps (com.your-domain.*) or specific apps for each of the samples (com.your-domain.<appname>) can be set up at developer.apple.com under your organizations' developer account. Also, the signing ID for the projects will need to be configured in order to build to run on a device.


## Scenarios addressed through the Sample Apps

### Personalize - [SASKitCustomApp](https://github.com/sassoftware/sas-sdk-for-iOS-examples/tree/master/SASKitCustomApp)
The first step many users want to take is to personalize the exising SAS Mobile BI app by building a mobile app that uses their app name and icon. This sample demonstrates deriving an application delegate from SASApplicationDelegate and adding your app name and icon. 

[Get Started](docs/GettingStarted_Personalize.md) creating your personalized mobile app.

### Pre-Configure
Pre-configure your server connections and report subscriptions so your users don't have to perform those tasks manually. For a pre-configured connection and set of reports auto-downlaoded, you can replace ***sas-sdk-servers.json*** in the framework with your own server configuration. Pre-configuration can be combined with any of the other three scenarios and has been available for some time with the Mobile Device Management(MDM) distribution.

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

### Customize - [SASKitMasterDetail](https://github.com/robbypowell/sas-sdk-for-iOS-examples/tree/master/SASKitMasterDetail)
Creating a fully customized mobile app lets you include both SAS Visual Analytics reports and any other content and capabilities that tie into your organizational goals, processes, and projects. An example of a custom mobile app build with the SAS SDK is [GatherIQ](https://gatheriq.analytics/), a free app that is part of the **SAS Data for Good** program. This app is available in the App Store and Google Play.

### Manage 
If you manage and secure your mobile devices with a Mobile Device Management (MDM) solution, you can integrate your mobile apps with your MDM solution by using the SAS SDK. This is done by overriding File System, Network and Keychain access:
 * [SASFileSystemDelegate](https://developer.sas.com/sdk/mobile/iOS/doc/8.22/Protocols/SASFileSystemDelegate.html)
 * [SASKeychainDelegate](https://developer.sas.com/sdk/mobile/iOS/doc/8.22/Protocols/SASKeychainDelegate.html)
 * [SASNetworkDelegate](https://developer.sas.com/sdk/mobile/iOS/doc/8.22/Protocols/SASNetworkDelegate.html)
    
