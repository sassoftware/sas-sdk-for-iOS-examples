//
//  SelectLocationViewController.swift
//  corona-virus
//
//  Copyright © 2020 SAS. All rights reserved.
//

import UIKit

public protocol SelectLocationDelegate : class {
    func didSelectLocation( _ location:String )
    func getExcludedLocations() -> [String]
}

class SelectLocationViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, UISearchBarDelegate {
    
    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var tableView: UITableView!
    
    public weak var delegate:SelectLocationDelegate?
    
    private var locations: [String] = []
    private var searchingLocations: [String] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        locations = AppViewModel.shared.availableLocations
        tableView.delegate = self
        tableView.dataSource = self
        
        self.navigationItem.title = NSLocalizedString("Select Location Title", comment: "")
        tableView.tableFooterView = UIView(frame: CGRect.init(x: 0, y: 0, width: tableView.bounds.width, height: 0.5))
        tableView.tableFooterView?.backgroundColor = UIColor.lightGray
        tableView.keyboardDismissMode = .onDrag
        searchBar.delegate = self
        if let delegate = delegate
        {
            let excludedLocations = delegate.getExcludedLocations()
            locations = locations.filter({ !excludedLocations.contains($0) })
        }
    }
    
    // Force keyboard to show first
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        DispatchQueue.main.async {
            self.searchBar.becomeFirstResponder()
        }
    }
    
    // Is search bar being used?
    var searching = false
    
    // MARK: - Table view data source
    //
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if searching {
            return searchingLocations.count
        } else {
            return locations.count
        }
    }
    
    // Each time the tableview builds, it displays x amounts of rows / indexPaths <- it must be related to this
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        if searching { // if search bar is being used, show the filtered locations array
            cell.textLabel!.text = searchingLocations[indexPath.row]
        } else {
            cell.textLabel!.text = locations[indexPath.row]
        }
        cell.accessibilityHint = NSLocalizedString("Add Location Item Accessibility Hint", comment: "")
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        var selectedLocation = ""
        if searching {
            selectedLocation = searchingLocations[indexPath.row]
        } else {
            selectedLocation = locations[indexPath.row]
        }
    
        if let delegate = delegate {
            delegate.didSelectLocation( selectedLocation )
        }
        
        dismissMyself()
    }
    
    @IBAction func dismissMyself() {
        self.dismiss(animated: true) {}
    }
    
    // Filters locationArray by searchText
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        searchingLocations = locations.filter{$0.localizedCaseInsensitiveContains(searchText)}
        
        if searchText == "" {
            searching = false
        } else {
            searching = true
        }
        tableView.reloadData()
    }
    
    // Search bar closes keyboard when return button is closed
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
    }
    
}

