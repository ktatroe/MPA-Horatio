//
//  Copyright © 2016 Kevin Tatroe. All rights reserved.
//  See LICENSE.txt for this sample’s licensing information

import Foundation
import CoreData


/**
 A `GroupOperation` subclass that fetches the data reset endpoint, sets the "needs reset?"
 flag if indicated, and deletes the data store if the flag is set (either by this operation
 or previously).
 */
class ResetObjectStoreOperation: GroupOperation {
    // MARK: Constants

    struct UserDefaults {
        static let DataResetValue = "DataResetKey"
        static let DataResetFlag = "DataResetFlagKey"
    }

    struct Endpoints {
        static let DataResetStaging = "http://data.ncaa.com/ncaa/ios/adhoc/ncaacache.json"
        static let DataResetProduction = "http://data.ncaa.com/ncaa/ios/ncaacache.json"
    }

    struct Filenames {
        static let WALFileSuffix = "-wal"
        static let SHMFileSuffix = "-shm"
    }


    // MARK: Initialization

    init() {
        super.init(operations: [])

        if let url = NSURL.init(string: Endpoints.DataResetStaging) {
            let task = NSURLSession.sharedSession().downloadTaskWithURL(url) { url, response, error in
                self.downloadFinished(url, response: response as? NSHTTPURLResponse, error: error)

                self.deleteLocalStoreIfFlagged()
            }

            let taskOperation = URLSessionTaskOperation(task: task)

            let reachabilityCondition = ReachabilityCondition(host: url)
            taskOperation.addCondition(reachabilityCondition)

            let networkObserver = NetworkObserver()
            taskOperation.addObserver(networkObserver)

            addCondition(MutuallyExclusive<ResetObjectStoreOperation>())

            addOperation(taskOperation)
        }

        name = "Reset Data Store"
    }


    // MARK: Private

    private func downloadFinished(url: NSURL?, response: NSHTTPURLResponse?, error: NSError?) {
        guard let localURL = url else { return }
        guard let response = response else { return }
        guard error == nil else { return }

        if let currentDataValue = NSData.init(contentsOfURL: localURL) {
            if currentDataValue.length == 0 {
                return
            }

            defer {
                NSUserDefaults.standardUserDefaults().setObject(currentDataValue, forKey: UserDefaults.DataResetValue)
                NSUserDefaults.standardUserDefaults().synchronize()
            }

            if let previousDataValue = NSUserDefaults.standardUserDefaults().dataForKey(UserDefaults.DataResetValue) {
                if previousDataValue.length == 0 {
                    return
                }

                let flaggedForReset = !currentDataValue.isEqualToData(previousDataValue)

                if flaggedForReset {
                    // this method can only turn on the flag, never off
                    NSUserDefaults.standardUserDefaults().setBool(flaggedForReset, forKey: UserDefaults.DataResetFlag)
                    NSUserDefaults.standardUserDefaults().synchronize()
                }
            }
        }
    }

    private func deleteLocalStoreIfFlagged() {
        let dataFlaggedForReset = NSUserDefaults.standardUserDefaults().boolForKey(UserDefaults.DataResetFlag)

        if dataFlaggedForReset {
            NSFetchedResultsController.deleteCacheWithName(nil)

            NSUserDefaults.standardUserDefaults().setBool(false, forKey: UserDefaults.DataResetFlag)
            NSUserDefaults.standardUserDefaults().setBool(false, forKey: PrimeObjectStoreOperation.UserDefaults.LocalStoreInitialized)

            NSUserDefaults.standardUserDefaults().synchronize()

            if let persistence = Container.resolve(PersistentStoreController.self) {
                if let storeURL = type(of: persistence).persistentStoreURL() {
                    do {
                        try NSFileManager.defaultManager().removeItemAtURL(storeURL)

                        if let WALPath = storeURL.path?.stringByAppendingString(Filenames.WALFileSuffix) {
                            try NSFileManager.defaultManager().removeItemAtPath(WALPath)
                        }

                        if let SHMPath = storeURL.path?.stringByAppendingString(Filenames.SHMFileSuffix) {
                            try NSFileManager.defaultManager().removeItemAtPath(SHMPath)
                        }
                    } catch { }
                }
            }
        }
    }
}
