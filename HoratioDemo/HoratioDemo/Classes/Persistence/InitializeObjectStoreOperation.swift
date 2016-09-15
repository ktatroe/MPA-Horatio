//
//  Copyright © 2016 Kevin Tatroe. All rights reserved.
//  See LICENSE.txt for this sample’s licensing information

import CoreData


/**
 A `GroupOperation` subclass that encompasses the various steps required to fully
 initialize the local storage; this includes clearing the re-generatable data (if
 necessary), initializing the Core Data stack, performing any emergency data updates
 within the stack, and, if not yet primed, priming the local store by fetching
 feeds as needed.
 */
class InitializeObjectStoreOperation: GroupOperation {

    // MARK: Initialization

    init() {
        super.init(operations: [])

        let resetOperation = ResetObjectStoreOperation()

        let loadOperation = LoadObjectStoreOperation()
        loadOperation.addDependency(resetOperation)

        let upgradeOperation = UpgradeObjectStoreOperation()
        upgradeOperation.addDependency(loadOperation)

        let delayedOperation = BlockOperation {
            self.produceOperation(PrimeObjectStoreOperation())
        }
        delayedOperation.addDependency(upgradeOperation)

        for operation in [resetOperation, loadOperation, upgradeOperation, delayedOperation] {
            addOperation(operation)
        }

        addCondition(MutuallyExclusive<InitializeObjectStoreOperation>())

        name = "Initialize Object Store"
    }
}
