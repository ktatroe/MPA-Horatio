//
//  Copyright © 2016 Kevin Tatroe. All rights reserved.
//  See LICENSE.txt for this sample’s licensing information

import Foundation
import CoreData


public typealias CoreDataActivityBlock = (context: NSManagedObjectContext) -> Void
public typealias CoreDataCompletionBlock = (Void) -> Void


public class PersistentStoreController {
    var mainContext: NSManagedObjectContext


    // MARK: - Initialization

    init?(storeName: String) {
        guard let storeURL = self.dynamicType.persistentStoreURL() else { return nil }
        guard let model = NSManagedObjectModel.mergedModelFromBundles(nil) else { return nil }

        self.storeName = storeName
        
        self.coordinator = NSPersistentStoreCoordinator(managedObjectModel: model)

        self.mainContext = NSManagedObjectContext(concurrencyType: .MainQueueConcurrencyType)

        self.writeContext = NSManagedObjectContext(concurrencyType: .PrivateQueueConcurrencyType)
        self.childContext = NSManagedObjectContext(concurrencyType: .PrivateQueueConcurrencyType)

        let context = NSManagedObjectContext(concurrencyType: .MainQueueConcurrencyType)
        context.persistentStoreCoordinator = coordinator

        var error = makeStore(coordinator, atURL: storeURL)

        if coordinator.persistentStores.isEmpty {
            destroyStore(coordinator, atURL: storeURL)
            error = makeStore(coordinator, atURL: storeURL)
        }

        if coordinator.persistentStores.isEmpty {
            print("Error creating SQLite store: \(error).")
            print("Falling back to `.InMemory` store.")
            error = makeStore(coordinator, atURL: nil, type: NSInMemoryStoreType)
        }

        guard error == nil else { return nil }

        writeContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        writeContext.persistentStoreCoordinator = coordinator

        mainContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        mainContext.parentContext = writeContext

        childContext.parentContext = mainContext
    }


    // MARK: - Public

    /// Generate and return the a `NSURL` to store the local store in.
    static func persistentStoreURL() -> NSURL? {
        let searchDirectory: NSSearchPathDirectory = .DocumentDirectory

        if let url = NSFileManager.defaultManager().URLsForDirectory(searchDirectory, inDomains: .UserDomainMask).last {
            return url.URLByAppendingPathComponent(storeName)
        }

        return nil
    }

    
    /// Returns `true` if a persistent store has been created; or `false`, otherwise.
    func persistentStoreExists() -> Bool {
        if !coordinator.persistentStores.isEmpty {
            return true
        }

        return false
    }

    
    /**
    Perform a block in a newly-created child context, attempt to save that context, then
    run a completion once done.
    
    - Parameter block: The block to run to in a child context.
 
    - Parameter completion: A block run when after the activity block is run and the context saved.
    */
    func backgroundPerformBlock(block: CoreDataActivityBlock, completion: CoreDataCompletionBlock? = nil) {
        childContext.performBlock { () -> Void in
            block(context: self.childContext)

            do {
                try self.childContext.obtainPermanentIDsForObjects(Array(self.childContext.insertedObjects))
            } catch { }

            self.saveContext(self.childContext)

            self.mainContext.performBlock({ () -> Void in
                assert(NSThread.isMainThread() == true, "Save not performed on main thread!")

                self.saveContext(self.mainContext)

                self.writeContext.performBlock({ () -> Void in
                    self.saveContext(self.writeContext)

                    if let completion = completion {
                        dispatch_async(dispatch_get_main_queue(), { () -> Void in
                            completion()
                        })
                    }
                })
            })
        }
    }


    // MARK: - Private

    private let storeName: String
    
    private var writeContext: NSManagedObjectContext
    private var childContext: NSManagedObjectContext
    
    private var coordinator: NSPersistentStoreCoordinator
    
    
    private func makeStore(coordinator: NSPersistentStoreCoordinator, atURL URL: NSURL?, type: String = NSSQLiteStoreType) -> NSError? {
        var error: NSError?

        do {
            let options = [NSMigratePersistentStoresAutomaticallyOption: true, NSInferMappingModelAutomaticallyOption: true]
            let _ = try coordinator.addPersistentStoreWithType(type, configuration: nil, URL: URL, options: options)
        } catch let storeError as NSError {
            error = storeError
        }

        return error
    }


    private func destroyStore(coordinator: NSPersistentStoreCoordinator, atURL URL: NSURL, type: String = NSSQLiteStoreType) {
        do {
            let _ = try coordinator.destroyPersistentStoreAtURL(URL, withType: type, options: nil)
        } catch { }
    }


    private func saveContext(context: NSManagedObjectContext) -> Bool {
        guard persistentStoreExists() else { return false }
        guard context.hasChanges else { return false }

        do {
            try context.save()
        } catch let error as NSError {
            assertionFailure("Could not save context \(context). Error: \(error)")
            return false
        }

        return true
    }
}
