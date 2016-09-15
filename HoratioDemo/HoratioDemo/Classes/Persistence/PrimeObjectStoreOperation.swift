//
//  Copyright © 2016 Kevin Tatroe. All rights reserved.
//  See LICENSE.txt for this sample’s licensing information

import Foundation


typealias PrimeOperationBlock = (Void) -> [Operation]


/**
 A `GroupOperation` subclass that sets up a serial set of feed fetches that need to occur
 prior to the main UI being accessible and again once per launch.
 */
class PrimeObjectStoreOperation: GroupOperation {
    // MARK: Constants

    struct UserDefaults {
        static let LocalStoreInitialized = "LocalStoreInitialized"
    }

    struct Notifications {
        static let LocalStoreInitialized = "LocalStoreInitialized"
    }


    let initialPriming: Bool


    // MARK: Initialization

    init(block: PrimeOperationBlock) {
        self.initialPriming = !NSUserDefaults.standardUserDefaults().boolForKey(UserDefaults.LocalStoreInitialized)

        super.init(operations: [])

        var operations = generateOperations()

        // each operation depends on the previous completing
        for (index, operation) in operations.enumerate() {
            if index > 0 {
                operation.addDependency(operations[index - 1])
            }
        }

        if self.initialPriming {
            if let interface = generateSportsInterfaceOperation() {
                operations.insert(interface, atIndex: 0)
            }

            operations.forEach { self.addOperation($0) }
        } else {
            guard let globalQueue = Container.resolve(OperationQueue.self) else { return }
            operations.forEach { globalQueue.addOperation($0) }
        }

        // when the last operation ends, dismiss the loading screen
        let finishObserver = BlockObserver { (operation, errors) -> Void in
            if errors.isEmpty {
                NSUserDefaults.standardUserDefaults().setBool(true, forKey: UserDefaults.LocalStoreInitialized)
                NSUserDefaults.standardUserDefaults().synchronize()

                dispatch_async(dispatch_get_main_queue(), {
                    NSNotificationCenter.defaultCenter().postNotificationName(Notifications.LocalStoreInitialized, object: nil)
                })
            }
        }

        self.addObserver(finishObserver)

        addCondition(MutuallyExclusive<PrimeObjectStoreOperation>())

        name = "Prime Object Store"
    }
}
