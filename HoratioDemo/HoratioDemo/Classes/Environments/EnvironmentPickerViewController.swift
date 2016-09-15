//
//  Copyright © 2016 Kevin Tatroe. All rights reserved.
//  See LICENSE.txt for this sample’s licensing information

import Foundation
import UIKit


struct EnvironmentCellConfiguration {
    let environment: Environment

    var title: String {
        get {
            return environment.name
        }
    }
    
    var checked: Bool {
        get {
            if let controller = Container.resolve(EnvironmentController.self) {
                if controller.currentEnvironment()?.identifier == environment.identifier {
                    return true
                }
            }
            
            return false
        }
    }
}


class EnvironmentPickerViewController: UIViewController {
    // MARK: - Constants

    struct Localizations {
        static let GroupFooter = "DebugEnvironmentFooter"
        
        static let AlertTitle = "DebugSwitchEnvironmentTitle"
        static let AlertMessage = "DebugSwitchEnvironmentMessage"
        static let AlertCancelTitle = "DebugSwitchEnvironmentCancelTitle"
        static let AlertConfirmTitle = "DebugSwitchEnvironmentConfirmTitle"
    }
    

    // MARK: - Properties
    
    var cellConfigurations = [EnvironmentCellConfiguration]()
    
    @IBOutlet weak var tableView: UITableView!
    
    
    // MARK: - Overrides

    override func viewDidLoad() {
        super.viewDidLoad()

        cellConfigurations = [EnvironmentCellConfiguration]()
        
        if let controller = Container.resolve(EnvironmentController.self) {
            for environment in controller.environments {
                let configuration = EnvironmentCellConfiguration(environment: environment)
                cellConfigurations.append(configuration)
            }
        }
    }
    
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        if let indexPath = tableView.indexPathForSelectedRow {
            tableView.deselectRowAtIndexPath(indexPath, animated: true)
        }
    }
    
    
    // MARK: - Private

    private func configurationForIndexPath(indexPath: NSIndexPath) -> EnvironmentCellConfiguration? {
        return cellConfigurations[indexPath.row]
    }
    
    
    private func switchToEnvironment(environment: Environment) {
        let alertTitle = NSLocalizedString(Localizations.AlertTitle, comment: "")
        let alertMessage = NSLocalizedString(Localizations.AlertMessage, comment: "")
        let alertView = UIAlertController(title: alertTitle, message: alertMessage, preferredStyle: .Alert)
        
        let cancelAction = UIAlertAction(title: NSLocalizedString(Localizations.AlertCancelTitle, comment: ""), style: .Cancel, handler: nil)
        alertView.addAction(cancelAction)
        
        let continueAction = UIAlertAction(title: NSLocalizedString(Localizations.AlertConfirmTitle, comment: ""), style: .Destructive) { [weak self] action in
            guard let _ = self else { return }
            
            if let controller = Container.resolve(EnvironmentController.self) {
                NSUserDefaults.standardUserDefaults().setObject(environment.identifier, forKey: controller.activeEnvironmentDefaultsKey())
                NSUserDefaults.standardUserDefaults().setBool(true, forKey: ResetObjectStoreOperation.UserDefaults.DataResetFlag)

                NSUserDefaults.standardUserDefaults().synchronize()
                
                abort()
            }
        }
        alertView.addAction(continueAction)
        
        self.presentViewController(alertView, animated: true, completion: nil )
    }
}


extension EnvironmentPickerViewController: UITableViewDelegate {
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        guard tableView == self.tableView else { return }

        if let configuration = configurationForIndexPath(indexPath) {
            switchToEnvironment(configuration.environment)
        }
        
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
        
        if let visibleIndexPaths = tableView.indexPathsForVisibleRows {
            tableView.reloadRowsAtIndexPaths(visibleIndexPaths, withRowAnimation: .Fade)
        }
    }
}


extension EnvironmentPickerViewController: UITableViewDataSource {
    func tableView(tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        guard tableView == self.tableView else { return nil }
        guard section == 0 else { return nil }
        
        return NSLocalizedString(Localizations.GroupFooter, comment: "")
    }

    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard tableView == self.tableView else { return 0 }
        
        return cellConfigurations.count
    }
    
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        guard tableView == self.tableView else { return UITableViewCell() }
        guard let configuration = configurationForIndexPath(indexPath) else { return UITableViewCell() }
        
        if let cell = tableView.dequeueReusableCellWithIdentifier(EnvironmentCell.ReuseIdentifier, forIndexPath: indexPath) as? EnvironmentCell {
            cell.configure(configuration.title, checked: configuration.checked)
        
            return cell
        }
        
        return UITableViewCell()
    }
}


class EnvironmentCell: UITableViewCell {
    // MARK: - Constants
    
    static let ReuseIdentifier = "EnvironmentCell"
    
    
    // MARK: - Properties
    
    @IBOutlet weak var titleLabel: UILabel!
    
    
    // MARK: - Overrides
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        titleLabel.text = ""
        accessoryType = .None
    }
    
    
    // MARK: - Configuration
    
    func configure(title: String, checked: Bool) {
        titleLabel.text = title
        accessoryType = checked ? .Checkmark : .None
    }
}
