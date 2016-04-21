//
//  RefreshAppConfigOperation.swift
//  Copyright © 2016 PGA Americas. All rights reserved.
//

import Foundation


/**
 A `GroupOperation` subclass that encompasses the operations for initializing the active
 environment, including fetching and parsing the environments file and fetching and parsing
 the app config file corresponding to the active environment and device type.
 */
public class RefreshAppConfigOperation: GroupOperation {
    // MARK: Constants
    
    struct CacheFiles {
        static let AppConfig = "appConfig-2016.json"
    }
    
    struct Identifiers {
        static let Feed = "app_config"
    }
    
    
    // MARK: - Initialization
    
    public init() {
        super.init(operations: [])

        let appConfigCacheFile = NSURL.cacheFile(named: CacheFiles.AppConfig)
        let downloadAppConfigOperation = DownloadAppConfigOperation(cacheFile: appConfigCacheFile)
            
        let parseAppConfigOperation = ParseAppConfigOperation(cacheFile: appConfigCacheFile)
        parseAppConfigOperation.addDependency(downloadAppConfigOperation)
            
        self.addOperation(downloadAppConfigOperation)
        self.addOperation(parseAppConfigOperation)
        
        addCondition(MutuallyExclusive<RefreshAppConfigOperation>())
        
        name = "Refresh App Config"
    }
}
