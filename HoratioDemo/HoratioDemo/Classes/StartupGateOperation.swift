//
//  Copyright © 2016 Kevin Tatroe. All rights reserved.
//  See LICENSE.txt for this sample’s licensing information

import Foundation


class StartupGateOperation: Operation {
    struct Error {
        static let StartupGateEnvironmentManagerFailure = "Startup Gate Failed. Environment Manager is nil."
        static let StartupGatePersistentStoreManagerFailure = "Startup Gate Failed. Persistent Store Manager is nil."
    }


    // MARK: - Initialization
    
    init(withCompletionHandler handler: ((error: NSError?) -> Void)? = nil) {
        self.handler = handler

        super.init()

        addCondition(MutuallyExclusive<StartupGateOperation>())

        self.name = "StartupGateOperation"
    }

    
    // MARK: - Overrides
    
    override func execute() {
        // TODO: stub; should gate on things like persistent store being available
        finish()
    }

    override func finished(errors: [NSError]) {
        dispatch_async(dispatch_get_main_queue()) { () -> Void in
            self.handler?(error: errors.first)
        }
    }
    
    
    // MARK: - Private

    private let handler: ((error: NSError?) -> Void)?
}
