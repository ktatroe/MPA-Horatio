//
//  Copyright © 2016 Kevin Tatroe. All rights reserved.
//  See LICENSE.txt for this sample’s licensing information

import Foundation


/**
 A `GroupOperation` subclass that wraps the startup sequence—including initializing the active
 environment and setting up the Core Data local store.
 */
class StartupSequenceOperation: GroupOperation {
    // MARK: - Initialization

    init(withCompletionHandler handler: (error: NSError?) -> Void) {
        self.handler = handler
        
        self.appearanceOperation = ConfigureAppearanceOperation()
        
        self.registerDefaultsOperation = RegisterDefaultsOperation()
        registerDefaultsOperation.addDependency(appearanceOperation)

        self.environmentsOperation = InitializeEnvironmentOperation()
        environmentsOperation.addDependency(registerDefaultsOperation)

        super.init(operations: [appearanceOperation, registerDefaultsOperation, environmentsOperation, initializeKrux])

        // can't even initialize these operations until the environment is known,
        // so delay creation of them
        let continueOperation = BlockOperation {
            let upgradeAlertOperation = UpgradeAlertOperation()
            self.addOperation(upgradeAlertOperation)

            let objectStoreOperation = InitializeObjectStoreOperation()
            self.startupGateOperation.addDependency(objectStoreOperation)
            objectStoreOperation.addDependency(upgradeAlertOperation)
            self.addOperation(objectStoreOperation)
        }

        continueOperation.addDependency(environmentsOperation)
        addOperation(continueOperation)

        startupGateOperation.addDependency(continueOperation)
        addOperation(self.startupGateOperation)
    }


    // MARK: - Operation Overrides

    override func finished(errors: [NSError]) {
        dispatch_async(dispatch_get_main_queue()) { () -> Void in
            self.handler(error: errors.first)
        }
    }


    // MARK: - Properties
    
    private let registerDefaultsOperation: RegisterDefaultsOperation
    private let appearanceOperation: ConfigureAppearanceOperation
    
    private let environmentsOperation: InitializeEnvironmentOperation
    private let startupGateOperation = StartupGateOperation()
    
    private let handler: (error: NSError?) -> Void
}
