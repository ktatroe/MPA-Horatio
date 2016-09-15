//
//  Copyright © 2016 Kevin Tatroe. All rights reserved.
//  See LICENSE.txt for this sample’s licensing information

import Foundation
import CoreData


/**
 An `Operation` subclass that sets up the Core Data stack for local storage of the
 object graph.
 */
class LoadObjectStoreOperation: Operation {
    // MARK: Initialization

    override init() {
        super.init()

        addCondition(MutuallyExclusive<LoadObjectStoreOperation>())

        name = "Load Object Store"
    }


    // MARK: Overrides

    override func execute() {
        if let controller = Container.resolve(PersistentStoreController.self) where controller.persistentStoreExists() {
            finish()

            return
        }

        guard let controller = PersistentStoreController(storeName: "Earthquakes") where controller.persistentStoreExists() else {
            let error = NSError(domain: "horatio.operations", code: 0, userInfo: [NSLocalizedDescriptionKey : "Could not create the persistent store."])
            finishWithError(error)

            return
        }

        Container.register(PersistentStoreController.self, factory: { _ in controller })

        finish()
    }


    override func finished(errors: [NSError]) {
        guard let firstError = errors.first where userInitiated else { return }

        let alert = AlertOperation()

        alert.title = "Unable to load database"
        alert.message = "An error occurred while loading the database. \(firstError.localizedDescription). Please try again later."

        alert.addAction("Retry Later", style: .Cancel)
        alert.addAction("Retry Now") { alertOperation in
            let retryOperation = InitializeObjectStoreOperation()
            retryOperation.userInitiated = true

            alertOperation.produceOperation(retryOperation)
        }

        produceOperation(alert)
    }
}
