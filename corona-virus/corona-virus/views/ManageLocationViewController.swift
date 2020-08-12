//
//  ManageLocationViewController.swift
//  corona-virus
//
//  Copyright © 2020 SAS. All rights reserved.
//

import UIKit

class ManageLocationViewController: UIViewController {
    
    var includedLocations = [String]()
    var locationsToDelete = [String]()
    
    @IBOutlet weak var applyButton: UIBarButtonItem?
    @IBOutlet weak var cancelButton: UIBarButtonItem?
    
    @IBOutlet weak var addButtonContainer:UIView?
    @IBOutlet weak var addButton:UIButton?
    
    @IBOutlet weak var tableView: UITableView?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.title = NSLocalizedString("Manage Locations Title", comment: "")
        
        // to make the fancy rounded corner cells, we have 7.5 pixels on the top and bottom so 15px
        // are in between each cell. We want some extra space at the top so it's also 15px
        let spacerView = UIView(frame: CGRect.init(x: 0, y: 0, width: tableView?.bounds.width ?? 0, height: 7.5))
        tableView?.tableHeaderView = spacerView
        
        // Load Locations from the array in the AppViewModel
        includedLocations = AppViewModel.shared.userLocations
        tableView?.delegate = self
        tableView?.dataSource = self
        
        tableView?.dragInteractionEnabled = true
        tableView?.dragDelegate = self
        tableView?.dropDelegate = self
        
        applyButton?.title = NSLocalizedString("Apply Button", comment: "")
        applyButton?.accessibilityHint = NSLocalizedString("Manage Locations Apply Button Accessibility Hint", comment: "")
        self.isModalInPresentation = true
        
        addButtonContainer?.layer.cornerRadius = 10
        addButtonContainer?.clipsToBounds = true
        
        addButton?.setTitle(NSLocalizedString("Manage Locations Add Location Button Label", comment: ""), for: .normal)
        addButton?.accessibilityLabel = NSLocalizedString("Manage Locations Add Location Button Accessibility Label", comment: "")
        addButton?.accessibilityHint = NSLocalizedString("Manage Locations Add Location Button Accessibility Hint", comment: "")
        
        applyButton?.isEnabled = false
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        super.prepare(for: segue, sender: sender)
        if segue.identifier == "Add Location" {
            if let navController = segue.destination as? UINavigationController, let destination = navController.viewControllers.first as? SelectLocationViewController {
                destination.delegate = self
            }
        }
    }
    
    @IBAction func addLocation() {
        performSegue(withIdentifier: "Add Location", sender: nil)
    }
    
    @IBAction func closeManageLocations( sender: UIBarButtonItem ) {
        dismissMyself()
    }
    
    func dismissMyself() {
        locationsToDelete = []
        self.navigationController?.dismiss(animated: true, completion: {})
    }
    
    @IBAction func applyLocations( sender: UIBarButtonItem ) {
        for location in locationsToDelete {
            ReportObjectCache.shared.removeImages(location)
        }
        locationsToDelete = []
        AppViewModel.shared.userLocations = includedLocations
        dismissMyself()
    }
}

extension ManageLocationViewController : UITableViewDataSource, UITableViewDelegate {
    // MARK: - Table view data source
    //
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return includedLocations.count
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return self.includedLocations[indexPath.row] != GlobalLocation
    }

    // Each time the tableview builds, it displays x amounts of rows / indexPaths <- it must be related to this
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as? ManageLocationCell else { return UITableViewCell()}
        var label = includedLocations[indexPath.row]
        if label == GlobalLocation {
            label = NSLocalizedString("Global Location Label", comment: "")
        }
        cell.label?.text = label
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let delete = UIContextualAction(style: .destructive, title: "Delete") { (action, view, completion) in
            
            self.locationsToDelete.append( self.includedLocations[indexPath.row] )
            self.includedLocations.remove(at: indexPath.row)
            self.tableView?.deleteRows(at: [indexPath], with: .automatic)
            
            self.applyButton?.isEnabled = true
            completion(true)
        }
        delete.backgroundColor = .red
        return UISwipeActionsConfiguration(actions: [delete])
    }
}
extension ManageLocationViewController : UITableViewDragDelegate, UITableViewDropDelegate {
    func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        return true
    }

    func tableView(_ tableView: UITableView, moveRowAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        includedLocations.insert(includedLocations.remove(at: sourceIndexPath.row), at: destinationIndexPath.row)
        applyButton?.isEnabled = true
    }

    // MARK: - UITableViewDragDelegate

    func tableView(_ tableView: UITableView, itemsForBeginning session: UIDragSession, at indexPath: IndexPath) -> [UIDragItem] {
        return []
    }

    // MARK: - UITableViewDropDelegate

    func tableView(_ tableView: UITableView, performDropWith coordinator: UITableViewDropCoordinator) {
        // no-op
    }
}

extension ManageLocationViewController : SelectLocationDelegate {
    func getExcludedLocations() -> [String] {
        return includedLocations
    }
    
    func didSelectLocation(_ location: String) {
        let indexPath = IndexPath(row: includedLocations.count, section: 0)
        includedLocations.append( location )
        tableView?.insertRows(at: [indexPath], with: .automatic)
        applyButton?.isEnabled = true
    }
}
