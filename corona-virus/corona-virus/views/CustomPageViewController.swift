//
//  LocationPageController.swift
//  corona-virus
//
//  Copyright © 2020 SAS. All rights reserved.
//

import UIKit
import SpriteKit

class CustomPageViewController : UIPageViewController
{
    fileprivate lazy var pages: [LocationViewController] = []
    
    @IBOutlet weak var sasIcon:UIBarButtonItem?
    
    @IBOutlet weak var splashScreen:UIView?
    @IBOutlet weak var primaryTitle:UILabel?
    @IBOutlet weak var iconTitle:UILabel?
    @IBOutlet weak var marketingLabel:UILabel?
    @IBOutlet weak var spinner:UIActivityIndicatorView?
    
    @IBOutlet weak var addLocationButton:UIBarButtonItem?
      
    private var firstTime = true
    
    fileprivate func getViewController(withIdentifier identifier: String) -> UIViewController
    {
        return UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: identifier)
    }
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        self.dataSource = self
        self.delegate = self
        
        let defaults = UserDefaults.standard
        
        if let _ = defaults.string(forKey: "skipLaunchScreen")
        {
            firstTime = false
        }
        else
        {
            firstTime = true
            defaults.set(true, forKey: "skipLaunchScreen")
        
            primaryTitle?.text = NSLocalizedString("Splash Screen Primary Title", comment: "")
            iconTitle?.text = NSLocalizedString("Splash Screen Icon Title", comment: "")
            marketingLabel?.text = NSLocalizedString("Splash Screen Marketing Text", comment: "")
            spinner?.alpha = 0
        }
        
        // and we are using this one to present the icon, but we don't need an action
        let foregroundColor = UIColor(named: "Default foreground")!
        sasIcon?.isEnabled = false
        sasIcon?.accessibilityLabel = NSLocalizedString("SAS Logo Accessibility Label", comment: "")
        
        let logo = UIImage(named: "SAS Logo")?.withTintColor( foregroundColor ) .withRenderingMode(.alwaysOriginal)
        sasIcon?.image = logo
        
        self.view.backgroundColor = UIColor.init(named: "Default background")
        
        updatePageModels()
        updateCurrentLocation()
        
        self.addLocationButton?.accessibilityLabel = NSLocalizedString("Add Location Button Accessibility Label", comment: "")
        self.addLocationButton?.accessibilityHint = NSLocalizedString("Add Location Button Accessibility Hint", comment: "")
        
        NotificationCenter.default.addObserver(self, selector: #selector(CustomPageViewController.handleLocationsChanged), name: AppViewModel.LocationsChanged, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(CustomPageViewController.handleCurrentLocationChanged), name: AppViewModel.CurrentLocationChanged, object: nil)
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        
        if traitCollection.preferredContentSizeCategory != previousTraitCollection?.preferredContentSizeCategory {
            if let report = AppViewModel.shared.report {
                AppViewModel.shared.reportUpdated(report: report)
                self.view.setNeedsLayout()
            }
        }
    }
    
    override func viewWillAppear(_ animated: Bool)
    {
        super.viewWillAppear(animated)
        
        if firstTime {
            if let splashScreen = self.splashScreen, let keyWindow = UIApplication.shared.windows.filter({$0.isKeyWindow}).first {
                keyWindow.addSubview(splashScreen)
                splashScreen.translatesAutoresizingMaskIntoConstraints = false
                let topConstraint = NSLayoutConstraint(item: splashScreen, attribute: .top, relatedBy: .equal, toItem: keyWindow, attribute: .top, multiplier: 1, constant: 0)
                let leftConstraint = NSLayoutConstraint(item: splashScreen, attribute: .leading, relatedBy: .equal, toItem: keyWindow, attribute: .leading, multiplier: 1, constant: 0)
                let rightConstraint = NSLayoutConstraint(item: splashScreen, attribute: .trailing, relatedBy: .equal, toItem: keyWindow, attribute: .trailing, multiplier: 1, constant: 0)
                let bottomConstraint = NSLayoutConstraint(item: splashScreen, attribute: .bottom, relatedBy: .equal, toItem: keyWindow, attribute: .bottom, multiplier: 1, constant: 0)
                keyWindow.addConstraints([topConstraint,leftConstraint,rightConstraint,bottomConstraint])
                animateBlobsOnSplashScreen()
            }
        }
    }
    
    override func viewDidAppear(_ animated: Bool)
    {
        super.viewDidAppear(animated)
        
        if firstTime {
            self.primaryTitle?.font = self.primaryTitle?.font.bold()
            self.spinner?.startAnimating()
        
            UIView.animate(withDuration: 1, delay: 9, options: .beginFromCurrentState, animations: {
                self.spinner?.alpha = 1
            }) { (Bool) in
                UIView.animate(withDuration: 2, delay: 1, options: .beginFromCurrentState, animations: {
                    self.splashScreen?.alpha = 0
                }) { (Bool) in
                    self.splashScreen?.removeFromSuperview()
                }
            }
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        super.prepare(for: segue, sender: sender)
        if let navController = segue.destination as? UINavigationController, let destination = navController.viewControllers.first as? SelectLocationViewController {
            destination.delegate = self
        }
    }
    
    func updatePageModels() {
        let pageModels = AppViewModel.shared.pages
        var pageViewControllers:[LocationViewController] = []
        let existingPages = pages
        var newLocation = AppViewModel.shared.currentLocation
        
        // we want to see if the currentLocation is still valid
        if let viewController = self.viewControllers?.first as? LocationViewController {
            if let currentLocation = viewController.pageModel?.location {
                if !AppViewModel.shared.userLocations.contains(currentLocation) {
                    var oldIndex = pages.firstIndex(of: viewController) ?? 1
                    oldIndex = oldIndex - 1
                    
                    while ( oldIndex > 0 ) {
                        if let location = pages[oldIndex].pageModel?.location {
                            if AppViewModel.shared.userLocations.contains(location) {
                                newLocation = location
                                break
                            }
                        }
                        oldIndex = oldIndex - 1
                    }
                    
                    if oldIndex == 0 {
                        newLocation = AppViewModel.shared.userLocations[0]
                    }
                }
            }
        }
        
        for pageModel in pageModels {
            var matchFound = false
            for page in existingPages {
                if page.pageModel?.location == pageModel.location {
                    pageViewControllers.append( page )
                    matchFound = true
                }
            }
            if !matchFound {
                let pageViewController = self.getViewController(withIdentifier: "LocationPage") as! LocationViewController
                pageViewController.pageModel = pageModel
                pageViewControllers.append( pageViewController)
            }
        }
        
        let hadPagesBefore = pages.count > 0
        pages = pageViewControllers
        
        if hadPagesBefore, AppViewModel.shared.currentLocation != newLocation {
            AppViewModel.shared.currentLocation = newLocation
        } else {
            updateCurrentLocation()
        }
    }
    
    func animateBlobsOnSplashScreen() {
        if let splashScreen = self.splashScreen {
            let view = SKView(frame: CGRect(x: 0, y: 0, width: splashScreen.frame.width, height: splashScreen.frame.height))
            splashScreen.addSubview(view)
            splashScreen.sendSubviewToBack(view)
            
            let scene = SKScene(size: view.frame.size)
            scene.backgroundColor = UIColor.white
            view.presentScene(scene)

            let wait = SKAction.wait(forDuration: 0.2)
            
            let addBall = SKAction.run { [unowned scene] in
                
                let randomNumBalls = Int.random(in: 1...7)
                for _ in 0...randomNumBalls {
                    let ballRadius = CGFloat.random(in: 20...175)
                    let ball = SKShapeNode(circleOfRadius: ballRadius)
                    
                    ball.fillColor = UIColor(named: "Report background")!
                    ball.strokeColor = UIColor(named: "Report background")!
                    
                    ball.position = self.grabRandomPoint(ballRadius)
                    ball.xScale = 0
                    ball.yScale = 0
                    
                    let randomFloat = Double.random(in: 2.25...4)
                    let popIn = SKAction.scale(to: 1, duration: randomFloat)
                    
                    popIn.timingMode = .easeInEaseOut
                    
                    ball.run(popIn)
                    scene.addChild(ball)
                }
            }
            scene.run( SKAction.repeat(SKAction.sequence([addBall,wait]), count: 50))
        }
    }
    
    func grabRandomPoint(_ radius:CGFloat) -> CGPoint {
        if let splashScreen = self.splashScreen {
            let randomX = CGFloat.random(in:splashScreen.frame.minX-radius-10...splashScreen.frame.maxX+radius+10)
            let randomY = CGFloat.random(in:splashScreen.frame.minY-radius-10...splashScreen.frame.maxY+radius+10)
            
            let randomPoint = CGPoint(x: randomX, y: randomY)
            
            return randomPoint
        }
        return CGPoint()
    }
    
    func updateCurrentLocation() {
        let currentLocation = AppViewModel.shared.currentLocation
        if let index = AppViewModel.shared.userLocations.firstIndex(of: currentLocation) {
            DispatchQueue.main.async {
                self.setViewControllers([self.pages[index]], direction: .forward, animated: false) { (Bool) in
                    self.updateNavigationBarTitle()
                }
            }
        }
        else if let firstVC = pages.first {
            DispatchQueue.main.async {
                self.setViewControllers([firstVC], direction: .forward, animated: false) { (Bool) in
                    self.updateNavigationBarTitle()
                }
            }
        }
    }
    
    func updateNavigationBarTitle() {
        if let currentPage = self.viewControllers?.first as? LocationViewController, let currentPageModel = currentPage.pageModel {
            self.navigationItem.title = currentPageModel.locationLabel
        }
    }
    
    @IBAction func displaySelectLocation(_ sender: Any) {
        performSegue(withIdentifier: "Select Location", sender: self)
    }
    
    @objc func handleLocationsChanged( _ notification : Notification ) {
        updatePageModels()
    }
    @objc func handleCurrentLocationChanged( _ notification : Notification ) {
        updateCurrentLocation()
    }
}

extension CustomPageViewController: UIPageViewControllerDataSource {
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
        guard let locationViewController = viewController as? LocationViewController else { return nil }
        guard let viewControllerIndex = pages.firstIndex(of: locationViewController) else { return nil }
        
        let previousIndex = viewControllerIndex - 1
        guard previousIndex >= 0 else { return nil }
        guard pages.count > previousIndex else { return nil }
        
        return pages[previousIndex]
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
        guard let locationViewController = viewController as? LocationViewController else { return nil }
        guard let viewControllerIndex = pages.firstIndex(of: locationViewController) else { return nil }
        
        let nextIndex = viewControllerIndex + 1
        guard nextIndex < pages.count else { return nil }
        guard pages.count > nextIndex else { return nil }
        
        return pages[nextIndex]
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, didFinishAnimating finished: Bool, previousViewControllers: [UIViewController], transitionCompleted completed: Bool) {
        if let viewController = self.viewControllers?.first as? LocationViewController {
            if let loc = viewController.pageModel?.location {
                AppViewModel.shared.currentLocation = loc
                updateNavigationBarTitle()
            }
        }
    }

    func presentationCount(for pageViewController: UIPageViewController) -> Int {
        return pages.count
    }
    
    func presentationIndex(for pageViewController: UIPageViewController) -> Int {
        if pages.count > 0 {
            for index in 0...(pages.count-1) {
                let page = pages[index]
                if page.pageModel?.location == AppViewModel.shared.currentLocation {
                    return pages.firstIndex(of: page) ?? 0
                }
            }
        }
        return 0
    }
}

extension CustomPageViewController: UIPageViewControllerDelegate { }

extension CustomPageViewController : SelectLocationDelegate {
    func getExcludedLocations() -> [String] {
        return AppViewModel.shared.userLocations
    }
   
    func didSelectLocation(_ location: String) {
        // Add locations to AppViewModel userLocations and checks if it's already there
        if !AppViewModel.shared.userLocations.contains(location)
        {
            AppViewModel.shared.userLocations.append(location)
            AppViewModel.shared.currentLocation = location
        }
    }
    
    
}

