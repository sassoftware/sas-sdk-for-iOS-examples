//
//  MasterViewController.swift
//  SASKitMasterDetail
//
//  Copyright © 2017 SAS Institute. All rights reserved.
//

import UIKit

import SASKit

let USE_GUESTMODE = true

class MasterViewController: UITableViewController, AnnotationHelperDelegate, ReportDetailsCapabilitiesDelegate, SASManagerDelegate
{
    // SAS public sample report server
    let url : URL = URL(string: "https://tbub.sas.com:443")!
    
    // UUIDs of reports on sample server
    let reports : [String : String ] = ["Warranty Analysis" : "faca01f6-c631-4cbf-b336-6ba186dc632e" ,
                                        "Capital Campaign"  : "03db38a7-ff39-460e-9aca-3ee108c10140" ,
                                        "Retail Insights"   : "1ccd88c8-38a6-4473-90e0-8bdb447510a4" ,
                                        "Water Consumption and Monitoring" : "cd4205df-44a8-448a-a174-765f89abe058"]
    
    func getApplicationName() -> String {
        return "SASKitMasterDetail"
    }
    
    func getApplicationVersion() -> String {
        return "1"
    }
    
    func showAlert(withTitle: String!, message: String!, buttonTitle: String!) {
        
    }
    
    var reportDetailsViewController : UIViewController? = nil

    var reportList : [SASReport] = Array()
    
    func addReportsDynamically()
    {
        // attempt server verification
        SASManager.shared.verifySASServer( url )
        { (server, error) in
            
            if (error == nil && server != nil)
            {
                if (USE_GUESTMODE)
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
                    if (error == nil)
                    {
                        // uncomment the following to get thumbnail generation - thumbnails aren't shown in this sample
                        // server?.generatesReportThumbnails = true
                        
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
                                        self.sortReports()
                                    }
                                    self.tableView.performSelector(onMainThread: #selector(UITableView.reloadData), with: nil, waitUntilDone: false)
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    
    func sortReports()
    {
        // sort dynamically loaded report list
        self.reportList.sort(by:
            {
                let name1 = $0.name!
                let name2 = $1.name!
                if (name1 < name2)
                {
                    return true
                }
                else
                {
                    return false
                }
        })
    }
    
    func listIndex(list : [SASReport], uniqueIdentifier : String) -> Int
    {
        var i : Int = -1
        for report in list
        {
            i += 1
            if report.identifier == uniqueIdentifier
            {
                return i
            }
        }
        return i
    }
    
    func listContains(list : [SASReport], uniqueIdentifier : String) -> Bool
    {
        for report in list
        {
            if report.identifier == uniqueIdentifier
            {
                return true
            }
        }
        return false
    }
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        tableView.backgroundColor = UIColor.white
        SASManager.initialize(delegate: self)
        {_ in
            self.addReportsDynamically()
        }
    }

    override func viewWillAppear(_ animated: Bool)
    {
        self.clearsSelectionOnViewWillAppear = self.splitViewController!.isCollapsed
        super.viewWillAppear(animated)
    }
    
    override func didReceiveMemoryWarning()
    {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func getReportForIndexPath(_ indexPath : IndexPath) -> SASReport?
    {
        var report : SASReport? = nil
        
        if (indexPath.section == 1)
        {
            report = reportList[indexPath.row]
        }
        else
        {
            report = reportList[indexPath.row]
        }
        return report
    }
    
    // MARK: - UITableViewDataSource
    override func numberOfSections(in tableView: UITableView) -> Int
    {
        let sections : Int = 1

        return sections
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int
    {
        var rows : Int = 0
        
        if (section == 1)
        {
            rows = reportList.count
        }
        else
        {
            rows = reportList.count
        }
        return rows
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String?
    {
        var addendum = ""
        if (section == 1 && reportList.count == 0)
        {
            // special case "loading" info
            addendum = " < Loading... >"
        }
        
        var title = "Available Reports"
        if (section == 1)
        {
            title = "Additional Reports" + addendum
        }
        else
        {
            title = "Available Reports" + addendum
        }
        return title
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell
    {
        var cell = tableView.dequeueReusableCell(withIdentifier: "ReportCell")
        if cell == nil
        {
            cell = UITableViewCell(style: .subtitle, reuseIdentifier: "ReportCell")
            cell?.backgroundColor = UIColor.clear
        }
        let report = self.getReportForIndexPath(indexPath)
        
        if let name = report?.name
        {
            cell?.textLabel?.text = name
        }
        
        cell?.detailTextLabel?.text = report?.location
        
        if let thumbnail = report?.thumbnail
        {
            cell?.imageView?.image = thumbnail
        }
        
        return cell!
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath)
    {
        self.performSegue(withIdentifier: "showDetail", sender: self)
        tableView.deselectRow(at: indexPath, animated: true)
    }

    
    @IBAction func updateAction(_ id: AnyObject)
    {
    }
    
    
    func detailsViewAction(_ id: AnyObject)
    {
        (reportDetailsViewController as! SASReportViewController).setCapabilitiesHelperDelegate(self)
        (reportDetailsViewController as! ReportDetailsViewDelegate).showDetailsPanel()
    }
    
    func annotateAction(_ id: AnyObject)
    {
        // invoke annotation mode
        if let split = self.splitViewController
        {
            let controllers = split.viewControllers
            let annotationViewController : SASKitAnnotationViewController = getAnnotationController(reportDetailsViewController! as! SASReportViewController, helper: self)
            let annoNavController = UINavigationController(rootViewController: annotationViewController as! UIViewController)
            let detailsNavController = controllers[controllers.count-1] as! UINavigationController
            annoNavController.modalPresentationStyle = .currentContext
            detailsNavController.present(annoNavController, animated: true)
        }
    }
    
    public func onAnnotationWillClose(_ annotatedImage: UIImage!) -> Bool
    {
        return true;
    }
    
    public func onAnnotationDidClose()
    {
        // displayMessage("Thanks for using the annotation interface.")
    }
    
    // MARK: ReportDetailsCapabilitiesDelegate methods
    public func supportsMarqueeHeader() -> Bool
    {
        return true
    }
    
    public func supportsSections() -> Bool
    {
        return true
    }
    
    public func supportsTextDetails() -> Bool
    {
        return false
    }
    
    public func supportsRefresh() -> Bool
    {
        return false
    }
    
    public func supportsAction() -> Bool
    {
        return false
    }
    
    public func supportsFavorite() -> Bool
    {
        return false
    }
    
    public func viewForMarqueeHeader() -> UIView?
    {
        // return nil // use default header contents if return nil
        let imgContainer : UIImageView = UIImageView(image: UIImage(named: "CustomDetailsHeader", in:SwiftGoodies.CURRENT_BUNDLE(type(of: self))))
        var r : CGRect = imgContainer.bounds
        r.origin.y = r.size.height - 26
        r.origin.x = 5
        r.size.width = r.size.width - 10
        r.size.height = 26
        let label = UILabel(frame: r)
        label.autoresizingMask  = UIViewAutoresizing.flexibleWidth
        label.font = UIFont(name: label.font.fontName, size: 20.0)
        label.textColor = UIColor.white
        label.text = reportDetailsViewController?.title
        imgContainer.addSubview(label)
        
        return imgContainer 
    }

    // MARK: - Segues
    override func prepare(for segue: UIStoryboardSegue, sender: Any?)
    {
        if segue.identifier == "showDetail"
        {
            if let indexPath = self.tableView.indexPathForSelectedRow
            {
                let report : SASReport? = self.getReportForIndexPath(indexPath)
                if (report != nil)
                {
                    let navController = segue.destination as! UINavigationController
     
                    reportDetailsViewController = report?.createViewController() as? UIViewController

                    navController.pushViewController(reportDetailsViewController!, animated: true)
                                                     
                    reportDetailsViewController?.title = report?.name
                    reportDetailsViewController?.navigationItem.setRightBarButtonItems([UIBarButtonItem.init(title: "Annotate",
                                                                                                             style: .plain,
                                                                                                             target: self,
                                                                                                             action: #selector(MasterViewController.annotateAction(_:))),
                                                                                        UIBarButtonItem.init(title: "Details",
                                                                                                             style: .plain,
                                                                                                             target: self,
                                                                                                             action: #selector(MasterViewController.detailsViewAction(_:))),
                                                                                        ], animated: true)
                    
                    // keep report from going under the navigation bar
                    navController.navigationBar.isTranslucent = false
                    navController.navigationItem.hidesBackButton = true
                    navController.navigationItem.leftBarButtonItem = nil
                }
            }
        }
    }

}

