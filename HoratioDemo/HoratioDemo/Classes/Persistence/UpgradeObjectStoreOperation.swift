//
//  Copyright © 2016 Kevin Tatroe. All rights reserved.
//  See LICENSE.txt for this sample’s licensing information

import Foundation
import CoreData


typealias DataStoreUpgradeBlock = (Void) -> Void


/**
 An `Operation` subclass that performs updates on the local storage for each version of the
 app skipped since the last run.
 */
class UpgradeObjectStoreOperation: Operation {
    // MARK: Constants

    struct Versions {
        static let V100 = 389.0

        static let Current = Versions.V100
    }

    struct UserDefaults {
        static let LastVersion = "LastLaunchVersion"
        static let NeverLaunched = 0.0
    }


    // MARK: Properties

    let lastVersion: Double


    // MARK: Initialization

    override init() {
        self.lastVersion = NSUserDefaults.standardUserDefaults().doubleForKey(UserDefaults.LastVersion)

        super.init()

        addCondition(MutuallyExclusive<UpgradeObjectStoreOperation>())

        self.name = "Upgrade Object Store"
    }


    // MARK: Execution

    override func execute() {
        guard let _ = Container.resolve(PersistentStoreController.self) else {
            finish()

            return
        }

        upgradeToVersion(currentVersion: Versions.V100, fromVersion: lastVersion, upgradeBlock: nil)

        // save last version as current
        NSUserDefaults.standardUserDefaults().setDouble(Versions.Current, forKey: UserDefaults.LastVersion)

        finish()
    }


    // MARK: - Private

    func upgradeToVersion(currentVersion current: Double, fromVersion from: Double, upgradeBlock: DataStoreUpgradeBlock?) -> Bool {
        guard from < current else { return false }
        guard let upgradeBlock = upgradeBlock else { return false }

        upgradeBlock()

        return true
    }
}
